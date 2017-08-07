#define TWEAK
#import "../Tweak.h"
#import <UIKit/UIView+Private.h>

#define FrontFlashOnRecursively ((self.cameraDevice == 1) && ((FrontFlashOnInPhoto && (self.cameraMode == 0 || self.cameraMode == 4)) || (FrontFlashOnInVideo && (self.cameraMode == 1 || self.cameraMode == 2))))
#define flashIsTurnedOn ((isiOS71 ? self.lastSelectedPhotoFlashMode == 1 : self.photoFlashMode == 1) || self.videoFlashMode == 1)

static BOOL override = NO;

%hook PLCameraView

- (void)_shutterButtonClicked {
    if (FrontFlashOnRecursively && flashIsTurnedOn) {
        void (^orig)(void) = ^{
            %orig;
        };
        flashScreen([UIApplication sharedApplication].keyWindow, orig);
    } else
        %orig;
}

- (BOOL)_flashButtonShouldBeHidden {
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

- (void)cameraControllerVideoCaptureDidStart:(id)arg1 {
    %orig;
    if (FrontFlashOnRecursively) {
        CAMFlashButton *flashButton = MSHookIvar<CAMFlashButton *>(self, "__flashButton");
        flashButton.autoHidden = NO;
    }
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

- (BOOL)_shouldEnableFlashButton {
    if (FrontFlashOnRecursively && [self _isCapturing]) {
        MSHookIvar<BOOL>(self, "__capturing") = NO;
        BOOL orig = %orig;
        MSHookIvar<BOOL>(self, "__capturing") = YES;
        return orig;
    }
    return %orig;
}

- (void)_stillDuringVideoPressed:(id)arg1 {
    if (FrontFlashOnRecursively && flashIsTurnedOn) {
        void (^orig)(void) = ^{
            %orig;
        };
        flashScreen([UIApplication sharedApplication].keyWindow, orig);
    } else
        %orig;
}

- (void)_showControlsForCapturingVideoAnimated:(BOOL)animated {
    %orig;
    if (FrontFlashOnInVideo && self.cameraDevice == 1) {
        [self._topBar setStyle:0 animated:animated];
        [self _updateTopBarStyleForDeviceOrientation:[(PLCameraController *)[%c(PLCameraController) sharedInstance] cameraOrientation]];
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
        [self._topBar pl_setHidden:YES animated:NO];
}

- (void)_showControlsForChangeToMode:(NSInteger)mode animated:(BOOL)animated {
    %orig;
    if (self.cameraDevice != 1)
        [self._topBar pl_setHidden:YES animated:NO];
}

- (void)_updateTopBarStyleForDeviceOrientation:(NSInteger)orientation {
    %orig;
    if (self.cameraDevice == 1)
        [self._topBar setStyle:1 animated:NO];
    else
        [self._topBar pl_setHidden:YES animated:NO];
}

- (void)_applyTopBarRotationForDeviceOrientation:(NSInteger)orientation {
    hook = YES;
    %orig;
    hook = NO;
    if (self.cameraDevice == 1) {
        [self._topBar setStyle:1 animated:NO];
        [self _updateTopBarStyleForDeviceOrientation:orientation];
    } else
        [self._topBar pl_setHidden:YES animated:NO];
}

- (void)cameraController:(id)controller willChangeToMode:(NSInteger)mode device:(NSInteger)device {
    %orig;
    [self._topBar pl_setHidden:device != 1 animated:YES];
}

%end

%end

%ctor {
    if (IN_SPRINGBOARD)
        return;
    callback();
    if (FrontFlashOn) {
        HaveObserver();
        openCamera7();
        %init;
        if (IS_IPAD) {
            %init(iPad);
        }
    }
}
