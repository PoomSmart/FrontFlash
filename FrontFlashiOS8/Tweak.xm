#import "../FrontFlash.h"
#import "../Tweak.h"

#define isVideoMode (self.cameraMode == 1 || self.cameraMode == 2 || self.cameraMode == 6)
#define isPhotoMode (self.cameraMode == 0 || self.cameraMode == 4)
#define FrontFlashOnRecursively ((self.cameraDevice == 1) && ((FrontFlashOnInPhoto && isPhotoMode) || (FrontFlashOnInVideo && isVideoMode)))
#define flashIsTurnedOn ((isPhotoMode && self.lastSelectedPhotoFlashMode == 1) || (isVideoMode && self.videoFlashMode == 1))

%hook CAMCameraView

- (void)_captureStillImage
{
	if (FrontFlashOnRecursively && flashIsTurnedOn)
		flashScreen(^{%orig;});
	else
		%orig;
}

- (void)_createDefaultControlsIfNecessary
{
	onFlash = YES;
	%orig;
	onFlash = NO;
}

- (BOOL)_shouldHideFlashButtonForMode:(NSInteger)mode
{
	BOOL shouldHook = ((self.cameraDevice == 1) && ((FrontFlashOnInPhoto && (mode == 0 || mode == 4)) || (FrontFlashOnInVideo && (mode == 1 || mode == 2 || mode == 6))));
	if (shouldHook) {
		onFlash = YES;
		MSHookIvar<NSInteger>([%c(CAMCaptureController) sharedInstance], "_cameraDevice") = 0;
		BOOL orig = %orig(0);
		MSHookIvar<NSInteger>([%c(CAMCaptureController) sharedInstance], "_cameraDevice") = 1;
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

- (void)_showControlsForCapturingVideoAnimated:(BOOL)animated
{
	%orig;
	if (FrontFlashOnInVideo && self.cameraDevice == 1) {
		[self._topBar setStyle:0 animated:animated];
		[self _updateTopBarStyleForDeviceOrientation:[(CAMCaptureController *)[%c(CAMCaptureController) sharedInstance] cameraOrientation]];
		[self._flashButton cam_setHidden:NO animated:animated];
	}
}

- (void)captureController:(id)controller didStartRecordingForVideoRequest:(id)request
{
	%orig;
	if (self.cameraDevice == 1)
		self._flashButton.allowsAutomaticFlash = NO;
}

%end

%hook CAMCaptureController

- (BOOL)hasFlash
{
	reallyHasFlash = %orig;
	return onFlash ? YES : reallyHasFlash;
}

%end

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, PreferencesChangedNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
	FFLoader();
	if (FrontFlashOn) {
		dlopen("/System/Library/PrivateFrameworks/CameraKit.framework/CameraKit", RTLD_LAZY);
		%init;
		if (IPAD)
			dlopen("/Library/Application Support/FrontFlash/FrontFlashiPadiOS8.dylib", RTLD_LAZY);
	}
	[pool drain];
}
