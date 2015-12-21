#import "../FrontFlash.h"
#import "../Tweak.h"

#define FrontFlashOnRecursively ((self.cameraDevice == 1) && ((FrontFlashOnInPhoto && (self.cameraMode == 0 || self.cameraMode == 4)) || (FrontFlashOnInVideo && (self.cameraMode == 1 || self.cameraMode == 2))))
#define flashIsTurnedOn ((isiOS71 ? self.lastSelectedPhotoFlashMode == 1 : self.photoFlashMode == 1) || self.videoFlashMode == 1)

%hook PLCameraView

- (void)_shutterButtonClicked
{
	if (FrontFlashOnRecursively && flashIsTurnedOn) {
		void (^orig)(void) = ^{ %orig; };
		flashScreen([UIApplication sharedApplication].keyWindow, orig);
	} else
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
	if (FrontFlashOnRecursively && flashIsTurnedOn) {
		void (^orig)(void) = ^{ %orig; };
		flashScreen([UIApplication sharedApplication].keyWindow, orig);
	} else
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

%ctor
{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, PreferencesChangedNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
	FFLoader();
	if (FrontFlashOn) {
		dlopen("/System/Library/PrivateFrameworks/PhotoLibrary.framework/PhotoLibrary", RTLD_LAZY);
		%init;
		if (IPAD)
			dlopen("/Library/Application Support/FrontFlash/FrontFlashiPadiOS7.dylib", RTLD_LAZY);
	}
}