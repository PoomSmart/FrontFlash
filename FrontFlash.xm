#import <UIKit/UIKit.h>
#import <GraphicsServices/GSCapability.h>

#define PreferencesChangedNotification "com.PS.FrontFlash.prefs"
#define PREF_PATH @"/var/mobile/Library/Preferences/com.PS.FrontFlash.plist"
#define Bool(key) [[prefDict objectForKey:key] boolValue]
#define Color(key) ([prefDict objectForKey:key] ? [[prefDict objectForKey:key] floatValue] : 1.0f)					
#define FrontFlashOnInPhoto Bool(@"FrontFlashOnInPhoto")
#define FrontFlashOnInVideo Bool(@"FrontFlashOnInVideo")
#define FrontFlashOn (FrontFlashOnInPhoto || FrontFlashOnInVideo)

#define declareFlashBtn() \
	PLCameraFlashButton *flashBtn = MSHookIvar<PLCameraFlashButton *>(self, "_flashButton");

static BOOL isFrontCamera;
static BOOL frontFlashActive;
static float previousBacklightLevel;
static UIView *flashView = nil;
static NSDictionary *prefDict = nil;

@interface UIApplication (FrontFlash)
- (void)setBacklightLevel:(float)level;
@end

@interface PLCameraController : NSObject
+ (id)sharedInstance;
- (BOOL)isCapturingVideo;
@end

@interface PLReorientingButton : UIButton
- (void)setHidden:(BOOL)hidden animationDuration:(double)duration;
@end

@interface PLCameraFlashButton : PLReorientingButton
@property(assign, nonatomic) int flashMode;
@property(assign, nonatomic, getter=isAutoHidden) BOOL autoHidden;
@end

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[prefDict release];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
}


%hook PLCameraController

- (BOOL)hasFlash
{
	return FrontFlashOn ? YES : %orig;
}

- (void)_setCameraMode:(int)mode cameraDevice:(int)device
{
	isFrontCamera = device == 1 ? YES : NO;
	%orig;
}

- (void)_setFlashMode:(int)mode force:(BOOL)arg2
{
	%orig;
	if (isFrontCamera && FrontFlashOn) {
		frontFlashActive = (mode == 1) ? YES : NO;
	}
}

%end

%hook PLCameraFlashButton

- (void)_collapseAndSetMode:(int)mode animated:(BOOL)animated
{
	if (isFrontCamera && FrontFlashOn && [[%c(PLCameraController) sharedInstance] isCapturingVideo] && mode == 0) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"FrontFlash" message:@"Currrently no implementation for Auto mode." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    	[alert show];
    	[alert release];
		%orig(-1, animated);
	}
	else %orig;
}

%end

%hook PLCameraView

- (void)_postCaptureCleanup
{
	%orig;
	if (isFrontCamera && FrontFlashOn) {
		declareFlashBtn()
		[flashBtn setHidden:NO animationDuration:1.0f];
	}
}

- (void)_commonPostVideoCaptureCleanup
{
	%orig;
	if (isFrontCamera && FrontFlashOn) {
		declareFlashBtn()
		[flashBtn setHidden:NO];
	}
}

- (void)cameraShutterClicked:(id)arg1
{
	%orig;
	if (isFrontCamera && FrontFlashOn) {
		declareFlashBtn()
		[flashBtn setHidden:NO];
		[flashBtn setUserInteractionEnabled:YES];
	}
}

- (void)_updateOverlayControls
{
	%orig;
	if (FrontFlashOn) {
		declareFlashBtn()
		if (isFrontCamera)
			[flashBtn setHidden:NO animationDuration:1.0f];
		else {
			if (!GSSystemHasCapability(kGSCameraFlashCapability))
				[flashBtn setHidden:YES animationDuration:1.0f];
		}
	}
}

- (void)cameraControllerVideoCaptureDidStart:(id)arg1
{
	%orig;
	if (isFrontCamera && FrontFlashOn) {
		declareFlashBtn()
		[flashBtn setAutoHidden:NO];
	}
}

- (void)_shutterButtonClicked
{
	declareFlashBtn()
	if (FrontFlashOn) {
		[flashBtn setHidden:NO];
		[flashBtn setUserInteractionEnabled:YES];
	}
	if ((flashBtn.flashMode == 1 || frontFlashActive) && isFrontCamera && FrontFlashOn) {
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

%end


%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	[pool release];
}
