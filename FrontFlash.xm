#import <UIKit/UIKit.h>

#define PreferencesChangedNotification "com.PS.FrontFlash.prefs"
#define PREF_PATH @"/var/mobile/Library/Preferences/com.PS.FrontFlash.plist"
#define Bool(key) ([prefDict objectForKey:key] ? [[prefDict objectForKey:key] boolValue] : YES)
#define FloatVal(key) ([prefDict objectForKey:key] ? [[prefDict objectForKey:key] floatValue] : 1.0f)					
#define FrontFlashOnInPhoto Bool(@"FrontFlashOnInPhoto")
#define FrontFlashOnInVideo Bool(@"FrontFlashOnInVideo")
#define FrontFlashOn (FrontFlashOnInPhoto || FrontFlashOnInVideo)
#define isiOS4 (kCFCoreFoundationVersionNumber >= 550.32 && kCFCoreFoundationVersionNumber < 675.00)

#define declareFlashBtn() \
	PLCameraFlashButton *flashBtn = MSHookIvar<PLCameraFlashButton *>(self, "_flashButton");
	
#define kDelayDuration 0.22
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
@end

@interface PLCameraFlashButton : PLReorientingButton
@property(assign, nonatomic) int flashMode;
@end

@interface PLCameraFlashButton (iOS5Up)
@property(assign, nonatomic, getter=isAutoHidden) BOOL autoHidden;
@end

@interface PLCameraController : NSObject
@property(assign, nonatomic) int cameraDevice;
+ (id)sharedInstance;
- (BOOL)isCapturingVideo;
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
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist"];
	previousBacklightLevel = isiOS4 ? ((dict != nil) ? [[dict objectForKey:@"SBBacklightLevel2"] floatValue] : 0.5) : [UIScreen mainScreen].brightness;
	GSEventSetBacklightLevel(1.0);
	UIWindow* window = [UIApplication sharedApplication].keyWindow;
   	flashView = [[UIView alloc] initWithFrame: CGRectMake(0.0f, 0.0f, window.frame.size.width, window.frame.size.height)];
   	[flashView setTag:9596];
    	switch ([[prefDict objectForKey:@"colorProfile"] intValue]) {
		case 1:
			flashView.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:FloatVal(@"Alpha")];
			break;
		case 2:
			flashView.backgroundColor = [UIColor colorWithRed:255/255.0f green:252/255.0f blue:120/255.0f alpha:FloatVal(@"Alpha")];
			break;
		case 3:
			flashView.backgroundColor = [UIColor colorWithRed:168/255.0f green:239/255.0f blue:255/255.0f alpha:FloatVal(@"Alpha")];
			break;
		case 4:
			flashView.backgroundColor = [UIColor colorWithRed:FloatVal(@"R") green:FloatVal(@"G") blue:FloatVal(@"B") alpha:FloatVal(@"Alpha")];
			break;
		default:
			flashView.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:FloatVal(@"Alpha")];
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


%hook UIImage

// This method will make FrontFlash works in iMessages app, I don't know why
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle
{
	return %orig;
}

%end

%hook PLCameraController

- (BOOL)hasFlash
{
	reallyHasFlash = %orig;
	return FrontFlashOn && onFlash ? YES : reallyHasFlash;
}

- (void)_setCameraMode:(int)mode cameraDevice:(int)device force:(BOOL)force
{
	isFrontCamera = (device == 1);
	%orig;
}

- (void)_setCameraMode:(int)mode cameraDevice:(int)device
{
	isFrontCamera = (device == 1);
	%orig;
}

- (void)_setFlashMode:(int)mode force:(BOOL)arg2
{
	%orig;
	if (FrontFlashOn) {
		if (self.cameraDevice == 1)
			frontFlashActive = (mode == 1);
	}
}

%end

%hook PLCameraFlashButton

- (void)setFlashMode:(int)mode notifyDelegate:(BOOL)delegate
{
	if (FrontFlashOn) {
		if ([[%c(PLCameraController) sharedInstance] isCapturingVideo] && mode == -1 && !reallyHasFlash && self.flashMode == 1)
			%orig(1, delegate);
		else
			%orig;
	} else
		%orig;
}

- (void)_collapseAndSetMode:(int)mode animated:(BOOL)animated
{
	if (FrontFlashOn) {
		if (mode == 0 && isFrontCamera)
			%orig(-1, animated);
		else
			%orig;
	} else
		%orig;
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
		if (self.cameraDevice == 1) {
			if (!isiOS4)
				[flashBtn setAutoHidden:NO];
		}
	}
}

%group SC2iOS45

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
	if (kCFCoreFoundationVersionNumber >= 550.32 && kCFCoreFoundationVersionNumber < 793.00) {
		void *openSC2 = dlopen("/Library/MobileSubstrate/DynamicLibraries/StillCapture2.dylib", RTLD_LAZY);
		if (openSC2 != NULL)
			%init(SC2iOS45);
	}
	%init();
	[pool drain];
}
