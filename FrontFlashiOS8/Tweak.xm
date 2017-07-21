#define TWEAK
#import "../Tweak.h"
#import <UIKit/UIView+Private.h>

#define isVideoMode (self.cameraMode == 1 || self.cameraMode == 2 || self.cameraMode == 6)
#define isPhotoMode (self.cameraMode == 0 || self.cameraMode == 4)
#define FrontFlashOnRecursively ((self.cameraDevice == 1) && ((FrontFlashOnInPhoto && isPhotoMode) || (FrontFlashOnInVideo && isVideoMode)))
#define flashIsTurnedOn ((isPhotoMode && self.lastSelectedPhotoFlashMode == 1) || (isVideoMode && self.videoFlashMode == 1))

BOOL override = NO;

%hook CAMCameraView

- (void)_captureStillImage {
    if (FrontFlashOnRecursively && flashIsTurnedOn)
        flashScreen([UIApplication sharedApplication].keyWindow, ^{ %orig; });
    else
        %orig;
}

- (void)_createDefaultControlsIfNecessary {
    onFlash = FrontFlashOnRecursively;
    %orig;
    onFlash = NO;
}

- (void)_updateFlashModeIfNecessary {
    override = FrontFlashOnRecursively;
    %orig;
    override = NO;
}

- (BOOL)_shouldHideFlashButtonForMode:(NSInteger)mode {
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

- (BOOL)_shouldEnableFlashButton {
    if (FrontFlashOnRecursively && [self _isCapturing]) {
        MSHookIvar<BOOL>(self, "__capturing") = NO;
        BOOL orig = %orig;
        MSHookIvar<BOOL>(self, "__capturing") = YES;
        return orig;
    }
    return %orig;
}

- (void)_showControlsForCapturingVideoAnimated:(BOOL)animated {
    %orig;
    if (FrontFlashOnInVideo && self.cameraDevice == 1) {
        [self._topBar setStyle:0 animated:animated];
        [self _updateTopBarStyleForDeviceOrientation:[(CAMCaptureController *)[%c(CAMCaptureController) sharedInstance] cameraOrientation]];
        [self._flashButton cam_setHidden:NO animated:animated];
    }
}

- (void)captureController:(id)controller didStartRecordingForVideoRequest:(id)request {
    %orig;
    if (self.cameraDevice == 1)
        self._flashButton.allowsAutomaticFlash = NO;
}

%end

%hook CAMCaptureController

- (BOOL)hasFlash {
    reallyHasFlash = %orig;
    return onFlash ? YES : reallyHasFlash;
}

- (NSInteger)cameraDevice {
    return override ? 0 : %orig;
}

%end

%group iPad

BOOL hook;
BOOL hook2;

%hook CAMPadApplicationSpec

- (BOOL)shouldCreateTopBar {
    return YES;
}

- (BOOL)shouldCreateFlashButton {
    return YES;
}

%end

%hook CAMTopBar

- (CGSize)sizeThatFits: (CGSize)size {
    return CGSizeMake(200.0, 40.0);
}

%end

%hook CAMCameraSpec

- (BOOL)isPad {
    return hook ? NO : YES;
}
- (BOOL)isPhone {
    return hook2 ? YES : NO;
}

%end

%hook CAMCameraView

- (BOOL)_shouldApplyRotationDirectlyToTopBarForOrientation: (NSInteger)orientation cameraMode: (NSInteger)mode {
    return YES;
}

- (BOOL)_shouldHideTopBarForMode:(NSInteger)mode {
    return self.cameraDevice != 1;
}

- (void)_createFlashButtonIfNecessary {
    hook2 = YES;
    %orig;
    hook2 = NO;
}

- (void)_showControlsForReturningFromSuspensionAnimated:(BOOL)animated {
    %orig;
    if (self.cameraDevice != 1)
        [self._topBar cam_setHidden:YES animated:NO];
}

- (void)_showControlsForChangeToMode:(NSInteger)mode animated:(BOOL)animated {
    %orig;
    if (self.cameraDevice != 1)
        [self._topBar cam_setHidden:YES animated:NO];
}

- (void)_updateTopBarStyleForDeviceOrientation:(NSInteger)orientation {
    %orig;
    if (self.cameraDevice == 1)
        [self._topBar setStyle:1 animated:NO];
    else
        [self._topBar cam_setHidden:YES animated:NO];
}

- (void)_applyTopBarRotationForDeviceOrientation:(NSInteger)orientation {
    hook = YES;
    %orig;
    hook = NO;
    if (self.cameraDevice == 1) {
        [self._topBar setStyle:1 animated:NO];
        [self _updateTopBarStyleForDeviceOrientation:orientation];
    } else
        [self._topBar cam_setHidden:YES animated:NO];
}

- (void)cameraController:(id)controller willChangeToMode:(NSInteger)mode device:(NSInteger)device {
    %orig;
    [self._topBar cam_setHidden:device != 1 animated:YES];
}

%end

%end

%ctor {
    if (IN_SPRINGBOARD)
        return;
    HaveObserver();
    callback();
    if (FrontFlashOn) {
        openCamera8();
        %init;
        if (IS_IPAD) {
            %init(iPad);
        }
    }
}
