#import "../FrontFlash.h"
#import <substrate.h>

static BOOL FrontFlashOnInPhoto;
static BOOL FrontFlashOnInVideo;
#define FrontFlashOn (FrontFlashOnInPhoto || FrontFlashOnInVideo)
#define FrontFlashOnRecursively ((self.cameraDevice == 1) && ((FrontFlashOnInPhoto && (self.cameraMode == 0 || self.cameraMode == 4)) || (FrontFlashOnInVideo && (self.cameraMode == 1 || self.cameraMode == 2))))
#define flashIsTurnedOn (self.lastSelectedPhotoFlashMode == 1 || self.videoFlashMode == 1)
static BOOL onFlash;
static BOOL reallyHasFlash;

static CGFloat alpha;
static CGFloat hue;
static CGFloat sat;
static CGFloat bri;

static int colorProfile;

static void FFLoader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	FrontFlashOnInPhoto = dict[@"FrontFlashOnInPhoto"] ? [dict[@"FrontFlashOnInPhoto"] boolValue] : YES;
	FrontFlashOnInVideo = dict[@"FrontFlashOnInVideo"] ? [dict[@"FrontFlashOnInVideo"] boolValue] : YES;
	hue = dict[@"Hue"] ? [dict[@"Hue"] floatValue] : 1.0f;
	sat = dict[@"Sat"] ? [dict[@"Sat"] floatValue] : 1.0f;
	bri = dict[@"Bri"] ? [dict[@"Bri"] floatValue] : 1.0f;
	alpha = dict[@"Alpha"] ? [dict[@"Alpha"] floatValue] : 1;
	colorProfile = dict[@"colorProfile"] ? [dict[@"colorProfile"] intValue] : 1;
}

static void flashScreen(void (^completionBlock)(void))
{
	UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
	float previousBacklightLevel = [UIScreen mainScreen].brightness;
	[UIScreen mainScreen].brightness = 1.0f;
	UIView *flashView = [[UIView alloc] initWithFrame:keyWindow.bounds];
	UIColor *flashColor;
	switch (colorProfile) {
		case 1:
			flashColor = [UIColor whiteColor];
			break;
		case 2:
			flashColor = [UIColor colorWithRed:1.0f green:0.99f blue:0.47f alpha:1.0f];
			break;
		case 3:
			flashColor = [UIColor colorWithRed:0.66f green:0.94f blue:1.0f alpha:1.0f];
			break;
		case 4:
			flashColor = [UIColor colorWithHue:hue saturation:sat brightness:bri alpha:alpha];
			break;
	}
	flashView.backgroundColor = flashColor;
	flashView.alpha = 0.0f;
	[keyWindow addSubview:flashView];
	[UIView animateWithDuration:kDelayDuration delay:0.0f options:UIViewAnimationCurveEaseOut
		animations:^{
			flashView.alpha = 1.0f;
		}
		completion:^(BOOL finished1) {
			if (finished1) {
				if (completionBlock)
					completionBlock();
				[UIView animateWithDuration:kDimDuration delay:0.0f options:UIViewAnimationCurveEaseOut
					animations:^{
						flashView.alpha = 0.0f;
					}
					completion:^(BOOL finished2) {
						if (finished2) {
							[flashView removeFromSuperview];
							[flashView release];
							[UIScreen mainScreen].brightness = previousBacklightLevel;
						}
					}];
			}
	}];
}

%hook PLCameraView

- (void)_shutterButtonClicked
{
	if (FrontFlashOnRecursively && flashIsTurnedOn)
		flashScreen(^{%orig;});
	else
		%orig;
}

- (BOOL)_flashButtonShouldBeHidden
{
	if (FrontFlashOnRecursively) {
		onFlash = YES;
		MSHookIvar<NSInteger>([%c(PLCameraController) sharedInstance], "_cameraDevice") = 0;
		BOOL orig = %orig;
		MSHookIvar<NSInteger>([%c(PLCameraController) sharedInstance], "_cameraDevice") = 1;
		onFlash = NO;
		return orig;
	}
	return %orig;
}

- (void)cameraControllerVideoCaptureDidStart:(id)arg1
{
	%orig;
	if (FrontFlashOnRecursively) {
		CAMFlashButton *flashButton = MSHookIvar<CAMFlashButton *>(self, "__flashButton");
		flashButton.autoHidden = NO;
	}
}

- (void)_createDefaultControlsIfNecessary
{
	onFlash = YES;
	%orig;
	onFlash = NO;
}

- (BOOL)_shouldHideFlashButtonForMode:(NSInteger)mode
{
	BOOL shouldHook = ((self.cameraDevice == 1) && ((FrontFlashOnInPhoto && (mode == 0 || mode == 4)) || (FrontFlashOnInVideo && (mode == 1 || mode == 2))));
	if (shouldHook) {
		onFlash = YES;
		MSHookIvar<NSInteger>([%c(PLCameraController) sharedInstance], "_cameraDevice") = 0;
		BOOL orig = %orig(0);
		MSHookIvar<NSInteger>([%c(PLCameraController) sharedInstance], "_cameraDevice") = 1;
		onFlash = NO;
		return orig;
	}
	return %orig;
}

- (BOOL)_shouldEnableFlashButton
{	
	if (FrontFlashOnRecursively && [self _isCapturing]) {
		MSHookIvar<BOOL>(self, "__capturing") = NO;
		BOOL orig = %orig;
		MSHookIvar<BOOL>(self, "__capturing") = YES;
		return orig;
	}
	return %orig;
}

- (void)_stillDuringVideoPressed:(id)arg1
{
	if (FrontFlashOnRecursively && flashIsTurnedOn)
		flashScreen(^{%orig;});
	else
		%orig;
}

- (void)_showControlsForCapturingVideoAnimated:(BOOL)animated
{
	%orig;
	if (FrontFlashOnInVideo && self.cameraDevice == 1) {
		[self._topBar setStyle:0 animated:animated];
		[self _updateTopBarStyleForDeviceOrientation:[[%c(PLCameraController) sharedInstance] cameraOrientation]];
		if (isiOS70) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
				[self._flashButton pl_setHidden:NO animated:animated];
			});
		} else
			[self._flashButton pl_setHidden:NO animated:animated];
	}
}

%end

%hook PLCameraController

- (BOOL)hasFlash
{
	reallyHasFlash = %orig;
	return onFlash ? YES : reallyHasFlash;
}

%end

#define VOID(name) name(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
static void VOID(PreferencesChangedCallback)
{
	system("killall Camera");
	FFLoader();
}

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, PreferencesChangedNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
	FFLoader();
	if (FrontFlashOn) {
		dlopen("/System/Library/PrivateFrameworks/PhotoLibrary.framework/PhotoLibrary", RTLD_LAZY);
		%init;
		if (IPAD)
			dlopen("/Library/Application Support/FrontFlash/FrontFlashiPadiOS7.dylib", RTLD_LAZY);
	}
	[pool drain];
}
