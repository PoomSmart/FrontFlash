#import <UIKit/UIKit.h>

#define PreferencesChangedNotification "com.PS.FrontFlash.prefs"
#define PREF_PATH @"/var/mobile/Library/Preferences/com.PS.FrontFlash.plist"
#define Bool(key) ([prefDict objectForKey:key] ? [[prefDict objectForKey:key] boolValue] : YES)
#define Color(key) ([prefDict objectForKey:key] ? [[prefDict objectForKey:key] floatValue] : 1.f)					
#define FrontFlashOnInPhoto Bool(@"FrontFlashOnInPhoto")
#define FrontFlashOnInVideo Bool(@"FrontFlashOnInVideo")
#define FrontFlashOn (FrontFlashOnInPhoto || FrontFlashOnInVideo)

#define declareFlashBtn() \
	PLCameraFlashButton *flashBtn = MSHookIvar<PLCameraFlashButton *>(self, "_flashButton");
	
#define kDelayDuration 0.3
#define kFadeDuration 0.5

static BOOL isFrontCamera;
static BOOL frontFlashActive;
static BOOL onFlash = NO;
static BOOL reallyHasFlash;
static float previousBacklightLevel;
static UIView *flashView = nil;
static NSDictionary *prefDict = nil;

@interface UIApplication (FrontFlash)
- (void)setBacklightLevel:(float)level;
@end

@interface PLReorientingButton : UIButton
- (void)setHidden:(BOOL)hidden animationDuration:(double)duration;
@end

@interface PLCameraFlashButton : PLReorientingButton
@property(assign, nonatomic) int flashMode;
@property(assign, nonatomic, getter=isAutoHidden) BOOL autoHidden;
@end

@interface PLCameraController : NSObject
@property(assign, nonatomic) int cameraDevice;
@end

@interface PLCameraView
@property(assign, nonatomic) int cameraMode;
@property(assign, nonatomic) int cameraDevice;
@end

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[prefDict release];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
}

static void flashScreen()
{
	previousBacklightLevel = [UIScreen mainScreen].brightness;
	GSEventSetBacklightLevel(1.0);
	UIWindow* window = [UIApplication sharedApplication].keyWindow;
   	flashView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, window.frame.size.width, window.frame.size.height)];
   	[flashView setTag:9596];
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
		default:
			flashView.backgroundColor = [UIColor whiteColor];
			break;
	}
    [window addSubview:flashView];
}

static void unflashScreen()
{
	[UIView animateWithDuration:kFadeDuration delay:0.0 options:0
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


%hook PLCameraController

- (BOOL)hasFlash
{
	reallyHasFlash = %orig;
	return FrontFlashOn && onFlash ? YES : reallyHasFlash;
}

- (void)_setCameraMode:(int)mode cameraDevice:(int)device
{
	isFrontCamera = device == 1 ? YES : NO;
	%orig;
}

- (void)_setFlashMode:(int)mode force:(BOOL)arg2
{
	%orig;
	if (FrontFlashOn) {
		if (self.cameraDevice == 1)
			frontFlashActive = mode == 1 ? YES : NO;
	}
}

%end

%hook PLCameraFlashButton

- (void)_collapseAndSetMode:(int)mode animated:(BOOL)animated
{
	if (FrontFlashOn) {
		if (mode == 0 && isFrontCamera) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"FrontFlash" message:@"No implementation for Auto mode." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    		[alert show];
    		[alert release];
			%orig(-1, animated);
		} else %orig;
	} else %orig;
}

%end

%hook PLCameraView

- (void)_postCaptureCleanup
{
	%orig;
	if (FrontFlashOn) {
		declareFlashBtn()
		if (self.cameraDevice == 1)
			[flashBtn setHidden:NO];
		else {
			if (!reallyHasFlash)
				[flashBtn setHidden:YES];
		}
	}
}

- (void)_commonPostVideoCaptureCleanup
{
	%orig;
	if (FrontFlashOn) {
		declareFlashBtn()
		if (self.cameraDevice == 1)
			[flashBtn setHidden:NO];
		else {
			if (!reallyHasFlash)
				[flashBtn setHidden:YES];
		}
	}
}

- (void)cameraShutterClicked:(id)arg1
{
	%orig;
	if (FrontFlashOn) {
		declareFlashBtn()
		if (self.cameraDevice == 1) {
			[flashBtn setHidden:NO];
			[flashBtn setUserInteractionEnabled:YES];
		} else {
			if (!reallyHasFlash)
				[flashBtn setHidden:YES];
		}
	}
}

- (void)_updateOverlayControls
{
	onFlash = YES;
	%orig;
	onFlash = NO;
	if (FrontFlashOn) {
		declareFlashBtn()
		if (self.cameraDevice == 1)
			[flashBtn setHidden:NO];
		else {
			if (!reallyHasFlash)
				[flashBtn setHidden:YES];
		}
	}
}

- (void)cameraControllerVideoCaptureDidStart:(id)arg1
{
	%orig;
	if (FrontFlashOn) {
		declareFlashBtn()
		if (self.cameraDevice == 1)
			[flashBtn setAutoHidden:NO];
	}
}

%group SC2iOS5

- (void)captureImage
{
	declareFlashBtn()
	if (FrontFlashOnInVideo) {
		if (reallyHasFlash) {
			[flashBtn setHidden:NO];
			[flashBtn setUserInteractionEnabled:YES];
		}
	}
	if ((flashBtn.flashMode == 1 || frontFlashActive) && isFrontCamera && FrontFlashOn) {
		flashScreen();
    	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDelayDuration*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
    		%orig;
    		if (flashView != nil && isFrontCamera && FrontFlashOnInVideo) {
   			[UIView animateWithDuration:kFadeDuration delay:0.0 options:0
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
    	});
    } else %orig;
}

%end

- (void)_shutterButtonClicked
{
	declareFlashBtn()
	if (FrontFlashOn) {
		if (self.cameraDevice == 1) {
			[flashBtn setHidden:NO];
			[flashBtn setUserInteractionEnabled:YES];
		} else {
			if (!reallyHasFlash)
				[flashBtn setHidden:YES];
		}
	}
	if ((flashBtn.flashMode == 1 || frontFlashActive) && isFrontCamera && FrontFlashOn) {
		flashScreen();
    	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDelayDuration*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
    		%orig;
    	});
    } else %orig;
}

- (void)takePictureOpenIrisAnimationFinished
{
    %orig;
    if (FrontFlashOnInPhoto) {
    	if (flashView != nil && isFrontCamera)
   			unflashScreen();
   	}
}

- (void)takePictureDuringVideoOpenIrisAnimationFinished
{
    %orig;
    if (FrontFlashOnInVideo) {
    	if (flashView != nil && isFrontCamera)
   			unflashScreen();
   	}
}

%end


%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	if (kCFCoreFoundationVersionNumber >= 675.00 && kCFCoreFoundationVersionNumber < 793.00) {
		void *openSC2 = dlopen("/Library/MobileSubstrate/DynamicLibraries/StillCapture2.dylib", RTLD_LAZY);
		if (openSC2 != NULL)
			%init(SC2iOS5);
	}
	%init();
	[pool release];
}
