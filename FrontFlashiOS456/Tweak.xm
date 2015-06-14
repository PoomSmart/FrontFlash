#import "../FrontFlash.h"
#import "../Tweak.h"
#import <substrate.h>

#define FrontFlashOn (FrontFlashOnInPhoto || FrontFlashOnInVideo)
#define FrontFlashOnRecursively ((self.cameraDevice == 1) && ((FrontFlashOnInPhoto && (self.cameraMode == 0)) || (FrontFlashOnInVideo && (self.cameraMode == 1))))
static BOOL frontFlashActive;

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
	onFlash = YES;
	%orig;
	onFlash = NO;
	handleFlashButton(self);
}

- (void)_postCaptureCleanup
{
	%orig;
	handleFlashButton(self);
}

- (void)_captureStillDuringVideo
{
	if (frontFlashActive && FrontFlashOnRecursively)
		flashScreen(^{%orig;});
	else
		%orig;
}

- (void)cameraShutterClicked:(PLCameraButton *)button
{
	if (frontFlashActive && FrontFlashOnRecursively && MSHookIvar<NSInteger>(button, "_buttonMode") == 0)
		flashScreen(^{%orig;});
	else
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

- (void)setFlashMode:(NSInteger)mode notifyDelegate:(BOOL)delegate
{
	%orig(([[NSClassFromString(@"PLCameraController") sharedInstance] isCapturingVideo] && mode == -1 && !reallyHasFlash && self.flashMode == 1) ? 1 : mode, delegate);
}

- (void)_collapseAndSetMode:(NSInteger)mode animated:(BOOL)animated
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

- (void)_setFlashMode:(NSInteger)mode force:(BOOL)force
{
	%orig;
	frontFlashActive = (mode == 1);
}

%end

%group SC2iOS45

%hook PLCameraView

- (void)sc2_captureImage
{
	if (frontFlashActive && FrontFlashOnRecursively)
		flashScreen(^{%orig;});
	else
		%orig;
}

%end

%end

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, PreferencesChangedNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
	FFLoader();
	if (FrontFlashOn) {
		dlopen("/System/Library/PrivateFrameworks/PhotoLibrary.framework/PhotoLibrary", RTLD_LAZY);
		%init;
		if (isiOS45) {
			if (dlopen("/Library/MobileSubstrate/DynamicLibraries/StillCapture2.dylib", RTLD_LAZY) != NULL) {
				%init(SC2iOS45);
			}
		}
	}
	[pool drain];
}
