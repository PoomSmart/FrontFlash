#import <UIKit/UIKit.h>

#define PreferencesChangedNotification "com.PS.FrontFlash.prefs"
#define PREF_PATH @"/var/mobile/Library/Preferences/com.PS.FrontFlash.plist"
#define Bool(key) [[prefDict objectForKey:key] boolValue]
#define Color(key) ([prefDict objectForKey:key] ? [[prefDict objectForKey:key] floatValue] : 1.0f)					
#define isFrontCamera ((self.cameraMode == 0 || self.cameraMode == 1) && self.cameraDevice == 1)
#define FrontFlashOnInPhoto Bool(@"FrontFlashOnInPhoto")
#define FrontFlashOnInVideo Bool(@"FrontFlashOnInVideo")
#define FrontFlashOn (FrontFlashOnInPhoto || FrontFlashOnInVideo)

static BOOL frontFlashActive;
static float previousBacklightLevel;
static UIView *flashView = nil;
static NSDictionary *prefDict = nil;

@interface PLCameraView
@property(nonatomic) int flashMode;
@property(nonatomic) int cameraMode;
@property(nonatomic) int cameraDevice;
@end

@interface PLCameraController
@property(nonatomic) int cameraMode;
@property(nonatomic) int cameraDevice;
@end

@interface PLCameraFlashButton
@property(assign, nonatomic) int flashMode;
@end

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[prefDict release];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
}

%hook PLCameraController

- (void)_setFlashMode:(int)mode force:(BOOL)arg2
{
	%orig;
	if (isFrontCamera && FrontFlashOn) {
		frontFlashActive = (mode == 1) ? YES : NO;
	}
}

- (BOOL)hasFlash
{
	return FrontFlashOn && isFrontCamera ? YES : %orig;
}

%end

%hook PLCameraView

- (void)previewStartedOpenIrisAnimationFinished
{
	if (FrontFlashOn) {
		frontFlashActive = (isFrontCamera && self.flashMode == 1) ? YES : NO;
		frontFlashActive = (self.cameraMode == 1 && self.cameraDevice == 1) ? YES : NO;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && FrontFlashOn) {
			PLCameraFlashButton *flashButton = MSHookIvar<PLCameraFlashButton *>(self, "_flashButton");
			[(UIButton *)flashButton setHidden:(isFrontCamera ? NO : YES)];
		}
	}
	%orig;
}

- (void)_shutterButtonClicked
{
	PLCameraFlashButton *flashButton = MSHookIvar<PLCameraFlashButton *>(self, "_flashButton");
	if ((flashButton.flashMode == 1 || frontFlashActive) && isFrontCamera && FrontFlashOn) {
		previousBacklightLevel = [UIScreen mainScreen].brightness;
		GSEventSetBacklightLevel(1.0);
		UIWindow* window = [UIApplication sharedApplication].keyWindow;
   		flashView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, window.frame.size.width, window.frame.size.height)];
    		switch ([[prefDict objectForKey:@"colorProfile"] intValue]) {
			case 1:
				flashView.backgroundColor = [UIColor whiteColor];
				break;
			case 2:
				flashView.backgroundColor = [UIColor colorWithRed:255/255.0f green:252/255.0f blue:120/255.0f alpha:1.0f];
				break;
			case 3:
				flashView.backgroundColor = [UIColor colorWithRed:168/255.0f green:239/255.0f blue:255/255.0f alpha:1.0f];
				break;
			case 4:
				flashView.backgroundColor = [UIColor colorWithRed:Color(@"R") green:Color(@"G") blue:Color(@"B") alpha:1.0f];
				break;
		}
    	[window addSubview:flashView];
    	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
    		%orig;
    	});
    } else %orig;
}

- (void)takePictureOpenIrisAnimationFinished
{
    %orig;
    if (flashView != nil && isFrontCamera && FrontFlashOnInPhoto) {
   		[UIView animateWithDuration:1.2 delay:0.0 options:0
                animations:^{
    			flashView.alpha = 0.0f;
                }
        	completion:^(BOOL finished) {
			[flashView removeFromSuperview];
			flashView = nil;
			[flashView release];
			[[UIApplication sharedApplication] setBacklightLevel:previousBacklightLevel];
			GSEventSetBacklightLevel(previousBacklightLevel);
        	}];
    }
}

- (void)takePictureDuringVideoOpenIrisAnimationFinished
{
    %orig;
    if (isFrontCamera && FrontFlashOnInVideo) {
		PLCameraFlashButton *flashButton = MSHookIvar<PLCameraFlashButton *>(self, "_flashButton");
		[flashButton setHidden:YES];
	}
    if (flashView != nil && isFrontCamera && FrontFlashOnInVideo) {
   		[UIView animateWithDuration:1.2 delay:0.0 options:0
                animations:^{
    			flashView.alpha = 0.0f;
                }
        	completion:^(BOOL finished) {
			[flashView removeFromSuperview];
			flashView = nil;
			[flashView release];
			[[UIApplication sharedApplication] setBacklightLevel:previousBacklightLevel];
			GSEventSetBacklightLevel(previousBacklightLevel);
        	}];
    }
}

- (BOOL)_flashButtonShouldBeHidden
{
	return isFrontCamera && FrontFlashOn ? NO : %orig;
}

%end


%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	[pool release];
}
