#import <UIKit/UIKit.h>

#define PreferencesChangedNotification "com.PS.FrontFlash.prefs"
#define PREF_PATH @"/var/mobile/Library/Preferences/com.PS.FrontFlash.plist"
#define Bool(dict, key, defaultBoolValue) ([[dict objectForKey:key] boolValue] ?: defaultBoolValue)

#define isFrontCamera ((self.cameraMode == 0 || self.cameraMode == 1) && self.cameraDevice == 1)
static BOOL frontFlashActive;
static BOOL BUG_FIX_1;
static float previousBacklightLevel;
static UIView *flashView = nil;
static NSDictionary *prefDict = nil;

#define FrontFlashOnInPhoto Bool(prefDict, @"FrontFlashOnInPhoto", NO)
#define FrontFlashOnInVideo Bool(prefDict, @"FrontFlashOnInVideo", NO)
#define FrontFlashOn (FrontFlashOnInPhoto || FrontFlashOnInVideo)

@interface PLCameraView
@property(nonatomic) int flashMode;
@property(nonatomic) int videoFlashMode;
@property(nonatomic) int cameraMode;
@property(nonatomic) int cameraDevice;
@end

@interface PLCameraController
@property(nonatomic) int flashMode;
@property(nonatomic) int cameraMode;
@property(nonatomic) int cameraDevice;
@end

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[prefDict release];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
}

%hook PLCameraController

- (BOOL)hasFlash { return FrontFlashOn && isFrontCamera ? YES : %orig; }

- (void)_setFlashMode:(int)mode force:(BOOL)arg2
{
	%orig;
	if (isFrontCamera && FrontFlashOn) {
		if (mode == 1) frontFlashActive = YES;
		if (mode == -1) frontFlashActive = NO;
		if (mode == 0) frontFlashActive = NO;
	}
}

- (void)_setCameraMode:(int)arg1 cameraDevice:(int)arg2
{
	%orig;
	if (arg1 == 1 && arg2 == 1 && FrontFlashOn && self.flashMode == 1) BUG_FIX_1 = YES;
	else BUG_FIX_1 = NO;
}

%end

%hook PLCameraView

- (void)previewStartedOpenIrisAnimationFinished
{
	if (FrontFlashOn) {
		if (isFrontCamera && self.flashMode == 1) frontFlashActive = YES; else frontFlashActive = NO;
		if (self.cameraMode == 1 && self.cameraDevice == 1) frontFlashActive = YES;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && FrontFlashOn) {
			%class PLCameraFlashButton;
			PLCameraFlashButton *flashButton = MSHookIvar<PLCameraFlashButton *>(self, "_flashButton");
			[(UIButton *)flashButton setHidden:(isFrontCamera ? NO : YES)];
		}
	}
	%orig;
}

- (void)_shutterButtonClicked
{
	if (frontFlashActive && isFrontCamera && FrontFlashOn) {
		previousBacklightLevel = [UIScreen mainScreen].brightness;
		GSEventSetBacklightLevel(1.0);
		UIWindow* window = [UIApplication sharedApplication].keyWindow;
   		flashView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, window.frame.size.width, window.frame.size.height)];
    		flashView.backgroundColor = [UIColor whiteColor];
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
    	%class PLCameraFlashButton;
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

- (BOOL)_flashButtonShouldBeHidden { return isFrontCamera && FrontFlashOn ? NO : %orig; }

%end

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	[pool release];
}

// vim:ft=objc
