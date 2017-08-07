#define TWEAK
#import "../Tweak.h"

#define isVideoMode(mode) (mode == 1 || mode == 2 || mode == 6)
#define isPhotoMode(mode) (mode == 0 || mode == 4)
#define FrontFlashOnRecursively(mode, device) ((device == 1) && ((FrontFlashOnInPhoto && isPhotoMode(mode)) || (FrontFlashOnInVideo && isVideoMode(mode))))
#define flashIsTurnedOn ((isPhotoMode(self._currentMode) && self._desiredFlashMode == 1) || (isVideoMode(self._currentMode) && self._desiredTorchMode == 1))

BOOL noAnimation = NO;
BOOL override = NO;

%hook AVCaptureFigVideoDevice

- (BOOL)hasFlash {
    return self.position == AVCaptureDevicePositionFront ? YES : %orig;
}

%end

%hook CAMCaptureCapabilities

- (BOOL)isFrontFlashSupported {
    return YES;
}

%end

%hook CAMLegacyStillImageCaptureRequest

- (NSInteger)flashMode {
    return override ? 0 : %orig;
}

%end

%hook CAMMutableStillImageCaptureRequest

- (NSInteger)flashMode {
    return override ? 0 : %orig;
}

%end

%hook CAMViewfinderViewController

- (BOOL)_shouldHideFlashButtonForMode: (NSInteger)mode device: (NSInteger)device {
    if (isVideoMode(mode) && device == 1)
        return NO;
    return %orig;
}

- (void)captureController:(id)arg1 didOutputTorchAvailability:(BOOL)arg2 {
    if (isVideoMode(self._currentMode) && self._currentDevice == 1)
        return;
    %orig;
}

- (void)stillImageRequestDidStartCapturing:(id)arg1 {
    noAnimation = FrontFlashOnRecursively(self._currentMode, self._currentDevice) && flashIsTurnedOn;
    %orig;
    noAnimation = NO;
}

- (void)_performCaptureAnimation {
    if (noAnimation)
        return;
    %orig;
}

- (void)_captureStillImageWithCurrentSettings {
    if (FrontFlashOnRecursively(self._currentMode, self._currentDevice) && flashIsTurnedOn) {
        UIView *keyWindow = [UIApplication sharedApplication].keyWindow;
        void (^post)(void) = ^{
            override = YES;
            %orig;
            override = NO;
        };
        flashScreen(keyWindow, post);
    } else
        %orig;
}

- (void)captureController:(id)controller didStartRecordingForVideoRequest:(id)request {
    %orig;
    if (self._currentDevice == 1)
        self._flashButton.allowsAutomaticFlash = NO;
}

- (void)_updateTopBarStyleForMode:(NSInteger)mode device:(NSInteger)device capturing:(BOOL)capturing animated:(BOOL)animated {
    %orig(mode, device, device == 1 ? NO : capturing, animated);
}

%end

%ctor {
    if (IN_SPRINGBOARD)
        return;
    HaveObserver();
    callback();
    if (FrontFlashOn) {
        openCamera9();
        %init;
    }
}
