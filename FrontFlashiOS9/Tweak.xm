#import "../FrontFlash.h"
#import "../Tweak.h"
#import "../ZKSwizzle.h"

#define isVideoMode(mode) (mode == 1 || mode == 2 || mode == 6)
#define isPhotoMode(mode) (mode == 0 || mode == 4)
#define FrontFlashOnRecursively(mode, device) ((device == 1) && ((FrontFlashOnInPhoto && isPhotoMode(mode)) || (FrontFlashOnInVideo && isVideoMode(mode))))
#define flashIsTurnedOn ((isPhotoMode(self._currentMode) && self._desiredFlashMode == 1) || (isVideoMode(self._currentMode) && self._desiredTorchMode == 1))

BOOL noAnimation = NO;

%hook CAMCaptureCapabilities

- (BOOL)isFrontFlashSupported
{
	return YES;
}

%end

%hook CAMLegacyStillImageCaptureRequest

- (int)flashMode
{
	return 0;
}

%end

%hook CAMMutableStillImageCaptureRequest

- (int)flashMode
{
	return 0;
}

%end

ZKSwizzleInterface($_Lamo_CAMViewfinderViewController, CAMViewfinderViewController, NSObject);

@interface $_Lamo_CAMViewfinderViewController (Hey)
@property NSInteger _desiredFlashMode;
@property NSInteger _desiredTorchMode;
@property NSInteger _flashMode;
@property NSInteger _currentMode;
@property NSInteger _currentDevice;
- (CAMFlashButton *)_flashButton;
@end

@implementation $_Lamo_CAMViewfinderViewController

- (BOOL)_shouldHideFlashButtonForMode:(int)mode device:(int)device
{
	if (isVideoMode(mode) && device == 1)
		return NO;
	return ZKOrig(BOOL, mode, device);
}

- (void)captureController:(id)arg1 didOutputTorchAvailability:(BOOL)arg2
{
	if (isVideoMode(self._currentMode) && self._currentDevice == 1)
		return;
	ZKOrig(void, arg1, arg2);
}

- (void)stillImageRequestDidStartCapturing:(id)arg1
{
	noAnimation = FrontFlashOnRecursively(self._currentMode, self._currentDevice) && flashIsTurnedOn;
	ZKOrig(void, arg1);
	noAnimation = NO;
}

- (void)_performCaptureAnimation
{
	if (noAnimation)
		return;
	ZKOrig(void);
}

- (void)_captureStillImageWithCurrentSettings
{
	if (FrontFlashOnRecursively(self._currentMode, self._currentDevice) && flashIsTurnedOn) {
		UIView *keyWindow = [UIApplication sharedApplication].keyWindow;
		void (^post)() = ^{ ZKOrig(void); };
		flashScreen(keyWindow, post);
	} else
		ZKOrig(void);
}

- (void)captureController:(id)controller didStartRecordingForVideoRequest:(id)request
{
	ZKOrig(void, controller, request);
	if (self._currentDevice == 1)
		self._flashButton.allowsAutomaticFlash = NO;
}

- (void)_updateTopBarStyleForMode:(int)mode device:(int)device capturing:(BOOL)capturing animated:(BOOL)animated
{
	ZKOrig(void, mode, device, NO, animated);
}

@end

%ctor
{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, PreferencesChangedNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
	FFLoader();
	if (FrontFlashOn) {
		dlopen("/System/Library/PrivateFrameworks/CameraUI.framework/CameraUI", RTLD_LAZY);
		%init;
		if (IPAD)
			dlopen("/Library/Application Support/FrontFlash/FrontFlashiPadiOS9.dylib", RTLD_LAZY);
	}
}
