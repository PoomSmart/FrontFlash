#define TWEAK
#import "../Tweak.h"
#import <substrate.h>

#define FrontFlashOn (FrontFlashOnInPhoto || FrontFlashOnInVideo)
#define FrontFlashOnRecursively ((self.cameraDevice == 1) && ((FrontFlashOnInPhoto && (self.cameraMode == 0)) || (FrontFlashOnInVideo && (self.cameraMode == 1))))
static BOOL frontFlashActive;
static BOOL override = NO;

static void handleFlashButton(PLCameraView *cameraView)
{
	PLCameraFlashButton *flashButton = MSHookIvar<PLCameraFlashButton *>(cameraView, "_flashButton");
	if (cameraView.cameraDevice == 1) {
		flashButton.hidden = NO;
		flashButton.userInteractionEnabled = YES;
	} else {
		if (!reallyHasFlash)
			flashButton.hidden = YES;
	}
}

%hook PLCameraView

- (void)_updateOverlayControls
{
	onFlash = FrontFlashOnRecursively;
	%orig;
	onFlash = NO;
	handleFlashButton(self);
}

- (void)_updateFlashModeIfNecessary
{
	override = FrontFlashOnRecursively;
	%orig;
	override = NO;
}

- (void)_updateIsNonDefaultFlashMode:(int)mode
{
	override = FrontFlashOnRecursively;
	%orig;
	override = NO;
}

- (void)_postCaptureCleanup
{
	%orig;
	handleFlashButton(self);
}

- (void)_captureStillDuringVideo
{
	if (frontFlashActive && FrontFlashOnRecursively) {
		void (^orig)(void) = ^{ %orig; };
		flashScreen([UIApplication sharedApplication].keyWindow, orig);
	} else
		%orig;
}

- (void)cameraShutterClicked:(PLCameraButton *)button
{
	if (frontFlashActive && FrontFlashOnRecursively && MSHookIvar<NSInteger>(button, "_buttonMode") == 0) {
		void (^orig)(void) = ^{ %orig; };
		flashScreen([UIApplication sharedApplication].keyWindow, orig);
	} else
		%orig;
	handleFlashButton(self);
}

- (void)_commonPostVideoCaptureCleanup
{
	%orig;
	handleFlashButton(self);
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
		PLCameraFlashButton *flashButton = MSHookIvar<PLCameraFlashButton *>(self, "_flashButton");
		if ([flashButton respondsToSelector:@selector(setAutoHidden:)])
			flashButton.autoHidden = NO;
	}
}

%end

%hook PLCameraFlashButton

- (void)setFlashMode:(int)mode notifyDelegate:(BOOL)delegate
{
	%orig(([(PLCameraController *)[NSClassFromString(@"PLCameraController") sharedInstance] isCapturingVideo] && mode == -1 && !reallyHasFlash && self.flashMode == 1) ? 1 : mode, delegate);
}

- (void)_collapseAndSetMode:(int)mode animated:(BOOL)animated
{
	%orig(mode == 0 && (((PLCameraController *)[NSClassFromString(@"PLCameraController") sharedInstance]).cameraDevice == 1) ? -1 : mode, animated);
}

%end

%hook PLCameraController

- (BOOL)hasFlash
{
	reallyHasFlash = %orig;
	return onFlash ? YES : reallyHasFlash;
}

- (void)_setFlashMode:(int)mode force:(BOOL)force
{
	%orig;
	frontFlashActive = (mode == 1);
}

- (int)cameraDevice
{
	return override ? 0 : %orig;
}

%end

%group SC2iOS5

%hook PLCameraView

- (void)sc2_captureImage
{
	if (frontFlashActive && FrontFlashOnRecursively) {
		void (^orig)(void) = ^{ %orig; };
		flashScreen([UIApplication sharedApplication].keyWindow, orig);
	} else
		%orig;
}

%end

%end

%ctor
{
	preferences = [[HBPreferences alloc] initWithIdentifier:tweakIdentifier];
	registerPref(preferences);
	if (FrontFlashOn) {
		openCamera6();
		%init;
		if (isiOS45) {
			if (dlopen("/Library/MobileSubstrate/DynamicLibraries/StillCapture2.dylib", RTLD_LAZY) != NULL) {
				%init(SC2iOS5);
			}
		}
	}
}