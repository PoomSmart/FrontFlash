#import "FrontFlash.h"
#import <notify.h>
	
#define kDelayDuration .15
#define kDimDuration 1
#define FrontFlashFlashScreenNotification "com.PS.FrontFlash.flashScreen"
#define delayCaptureQueueKey "com.PS.FrontFlash.delayCapture"

static BOOL FrontFlashOnInPhoto = YES;
static BOOL FrontFlashOnInVideo = YES;
#define FrontFlashOn (FrontFlashOnInPhoto || FrontFlashOnInVideo)
#define FrontFlashOnRecursively ((FrontFlashOnInPhoto && ([self cameraMode] == 0 || [self cameraMode] == 4)) || (FrontFlashOnInVideo && [self cameraMode] == 1))
static BOOL isFrontCamera;
static BOOL frontFlashActive;
static BOOL onFlash = NO;
static BOOL reallyHasFlash;

static BOOL fromCT2;

static CGFloat alpha = 1;
static CGFloat hue = 1;
static CGFloat sat = 1;
static CGFloat bri = 1;

static int colorProfile = 1;

static void FFLoader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	FrontFlashOnInPhoto = dict[@"FrontFlashOnInPhoto"] ? [dict[@"FrontFlashOnInPhoto"] boolValue] : YES;
	FrontFlashOnInVideo = dict[@"FrontFlashOnInVideo"] ? [dict[@"FrontFlashOnInVideo"] boolValue] : YES;
	hue = dict[@"Hue"] ? [dict[@"Hue"] floatValue] : 1;
	sat = dict[@"Sat"] ? [dict[@"Sat"] floatValue] : 1;
	bri = dict[@"Bri"] ? [dict[@"Bri"] floatValue] : 1;
	alpha = dict[@"Alpha"] ? [dict[@"Alpha"] floatValue] : 1;
	colorProfile = dict[@"colorProfile"] ? [dict[@"colorProfile"] intValue] : 1;
}

static void flashScreen()
{
	[[UIScreen mainScreen] setBrightness:1];
	notify_post(FrontFlashFlashScreenNotification);
}

static id cameraInstance()
{
	return isiOS8 ? [%c(CAMCaptureController) sharedInstance] : [%c(PLCameraController) sharedInstance];
}

static int cameraDevice()
{
	id view = [cameraInstance() delegate];
	return isiOS8 ? ((CAMCameraView *)view).cameraDevice : ((PLCameraView *)view).cameraDevice;
}

static BOOL isCapturingVideo()
{
	return [cameraInstance() isCapturingVideo];
}

static UIButton *flashBtn()
{
	id cameraView = [cameraInstance() delegate];
	id flashBtn = isiOS7Up ? MSHookIvar<CAMFlashButton *>(cameraView, "__flashButton") : MSHookIvar<PLCameraFlashButton *>(cameraView, "_flashButton");
	return flashBtn;
}

static void handleFlashButton()
{
	UIButton *flashButton = flashBtn();
	if (cameraDevice() == 1) {
		flashButton.hidden = NO;
		flashButton.userInteractionEnabled = YES;
	} else {
		if (!reallyHasFlash)
			flashButton.hidden = YES;
	}
}


%group iOS56

%hook PLCameraView

- (void)cameraShutterClicked:(id)arg1
{
	%orig;
	handleFlashButton();
}

- (void)_updateOverlayControls
{
	onFlash = YES;
	%orig;
	onFlash = NO;
	handleFlashButton();
}

- (void)_postCaptureCleanup
{
	%orig;
	handleFlashButton();
}

- (void)_shutterButtonClicked
{
	handleFlashButton();
	if (isFrontCamera && self.cameraMode == 0) {
		flashScreen();
		dispatch_queue_t delayCaptureQueue = dispatch_queue_create(delayCaptureQueueKey, NULL);
		dispatch_async(delayCaptureQueue, ^{
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDelayDuration*NSEC_PER_SEC), delayCaptureQueue, ^(void){
				%orig;
			});
		});
		dispatch_release(delayCaptureQueue);
	} else
		%orig;
}

- (void)_commonPostVideoCaptureCleanup
{
	%orig;
	handleFlashButton();
}

%end

%hook PLCameraFlashButton

- (void)setFlashMode:(int)mode notifyDelegate:(BOOL)delegate
{
	%orig(isCapturingVideo() && mode == -1 && !reallyHasFlash && self.flashMode == 1 ? 1 : mode, delegate);
}

- (void)_collapseAndSetMode:(int)mode animated:(BOOL)animated
{
	%orig(mode == 0 && isFrontCamera ? -1 : mode, animated);
}

%end

%end

%group iOS4

%hook PLCameraController

- (void)_setCameraMode:(int)mode cameraDevice:(int)device force:(BOOL)force
{
	isFrontCamera = (device == 1);
	%orig;
}

%end

%end

%group Common

%hook CAMERACONTROLLER

- (BOOL)hasFlash
{
	reallyHasFlash = %orig;
	return onFlash ? YES : reallyHasFlash;
}

- (void)_setCameraMode:(int)mode cameraDevice:(int)device
{
	isFrontCamera = (device == 1);
	%orig;
}

- (void)_setFlashMode:(int)mode force:(BOOL)arg2
{
	%orig;
	frontFlashActive = (mode == 1);
}

- (void)captureOutput:(id)arg1 didStartRecordingToOutputFileAtURL:(id)arg2 fromConnections:(id)arg3
{
	%orig;
	if (cameraDevice() == 1)
		[(id)flashBtn() setAutoHidden:NO];
}

%end

%end

%group CommonPre8

%hook PLCameraView

- (BOOL)_flashButtonShouldBeHidden
{
	if (FrontFlashOnRecursively && cameraDevice() == 1)
		return NO;
	return %orig;
}

- (void)cameraControllerVideoCaptureDidStart:(id)start
{
	%orig;
	if (self.cameraDevice == 1) {
		if (!isiOS4)
			[(id)flashBtn() setAutoHidden:NO];
	}
}

%end

%end

%group SC2iOS45

%hook PLCameraView

- (void)sc2_captureImage
{
	if (FrontFlashOnInVideo) {
		if (reallyHasFlash) {
			flashBtn().hidden = NO;
			flashBtn().userInteractionEnabled = YES;
		}
	}
	if ((((PLCameraFlashButton *)flashBtn).flashMode == 1 || frontFlashActive) && isFrontCamera) {
		flashScreen();
    } else
    	%orig;
}

%end

%end

%group iOS718

%hook CAMTopBar

- (void)_updateHiddenViewsForButtonExpansionAnimated:(BOOL)animated
{
	%orig;
	if (isCapturingVideo() && isFrontCamera)
		[self.flashButton pl_setHidden:NO animated:YES];
}

%end

%end

%group iOS70

%hook CAMFlashButton

- (void)setFlashMode:(int)mode notifyDelegate:(BOOL)delegate
{
	int flashMode = mode;
	if (isCapturingVideo() && mode == -1 && !reallyHasFlash && self.flashMode == 1)
		flashMode = 1;
	else if (mode == 0 && isFrontCamera)
		flashMode = -1;
	%orig(flashMode, delegate);
}

%end

%end

%group iOS78

%hook CAMTopBar

- (void)_setFlashButtonExpanded:(BOOL)expand
{
	%orig;
	if (isFrontCamera)
		[self.elapsedTimeView pl_setHidden:expand animated:YES];
}

%end

%hook CAMERAVIEW

- (void)_createDefaultControlsIfNecessary
{
	onFlash = YES;
	%orig;
	onFlash = NO;
}

- (BOOL)_shouldHideFlashButtonForMode:(int)mode
{
	if (FrontFlashOnRecursively && cameraDevice() == 1)
		return NO;
	return %orig;
}

- (BOOL)_shouldEnableFlashButton
{
	if (FrontFlashOnRecursively && cameraDevice() == 1)
		return YES;
	return %orig;
}

- (void)_showControlsForCapturingVideoAnimated:(BOOL)animated
{
	%orig;
	if (FrontFlashOnInVideo && cameraDevice() == 1) {
		[[self _topBar] setStyle:0 animated:NO];
		int cameraOrientation = isiOS8 ? [cameraInstance() cameraOrientation] : [cameraInstance() cameraOrientation];
		[self _updateTopBarStyleForDeviceOrientation:cameraOrientation];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (isiOS70 ? .2 : 0)*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			[flashBtn() pl_setHidden:NO animated:YES];
		});
	}
}

%new
- (BOOL)shouldFlashTheScreen
{
	int cameraMode = [self cameraMode];
	BOOL isStillImageMode = cameraMode == 0 || cameraMode == 4;
	BOOL isFrontCamera = [self cameraDevice] == 1;
	BOOL isNotSuspended = ![[UIApplication sharedApplication] isSuspended];
	BOOL isNotInBurstMode = NO;
	if ([cameraInstance() respondsToSelector:@selector(performingTimedCapture)])
		isNotInBurstMode = ![cameraInstance() performingTimedCapture];
	else if ([cameraInstance() respondsToSelector:@selector(performingAvalancheCapture)])
		isNotInBurstMode = ![cameraInstance() performingAvalancheCapture];
	BOOL flashModeIsOn = (((CAMFlashButton *)flashBtn()).flashMode == 1);
	BOOL controllerFlashModeIsOn = frontFlashActive;
	return (isStillImageMode && isFrontCamera && isNotSuspended && isNotInBurstMode) && (flashModeIsOn || controllerFlashModeIsOn);
}

- (void)_createShutterButtonIfNecessary
{
	%orig;
	CAMShutterButton *shutterButton = [MSHookIvar<CAMBottomBar *>(self, "__bottomBar") shutterButton];
	[shutterButton removeTarget:self action:@selector(cameraShutterReleased:) forControlEvents:UIControlEventTouchUpInside];
	[shutterButton addTarget:self action:@selector(frontflash_cameraShutterReleased:) forControlEvents:UIControlEventTouchUpInside];
}

%new
- (void)frontflash_cameraShutterReleased:(CAMShutterButton *)button
{
	if ([self shouldFlashTheScreen]) {
		flashScreen();
		dispatch_queue_t delayCaptureQueue = dispatch_queue_create(delayCaptureQueueKey, NULL);
		dispatch_async(delayCaptureQueue, ^{
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDelayDuration*NSEC_PER_SEC), delayCaptureQueue, ^(void){
				[self cameraShutterReleased:button];
			});
		});
		dispatch_release(delayCaptureQueue);
	} else
		[self cameraShutterReleased:button];
}

%end

%end

%group iOS78iPad

static BOOL hook = NO;
static BOOL hook2 = NO; 

%hook CAMPadApplicationSpec

- (BOOL)shouldCreateTopBar
{
	return YES;
}

- (BOOL)shouldCreateFlashButton
{
	return YES;
}

%end

%hook CAMTopBar

- (CGSize)sizeThatFits:(CGSize)size
{
	return CGSizeMake(200, 40);
}

%end

%hook CAMCameraSpec

- (BOOL)isPad
{
	return hook ? NO : YES;
}
- (BOOL)isPhone
{
	return hook2 ? YES : NO;
}

%end

%hook CAMERAVIEW

- (BOOL)_shouldApplyRotationDirectlyToTopBarForOrientation:(int)orientation cameraMode:(int)mode
{
	return YES;
}

- (void)_createFlashButtonIfNecessary
{
	hook2 = YES;
	%orig;
	hook2 = NO;
}

- (void)_updateTopBarStyleForDeviceOrientation:(int)orientation
{
	%orig;
	[[self _topBar] setStyle:1 animated:NO];
}

- (void)_applyTopBarRotationForDeviceOrientation:(int)orientation
{
	hook = YES;
	%orig;
	hook = NO;
	[[self _topBar] pl_setHidden:cameraDevice() != 1 animated:YES];
	[[self _topBar] setStyle:1 animated:NO];
	[self _updateTopBarStyleForDeviceOrientation:orientation];
}

- (void)cameraController:(id)cont willChangeToMode:(int)mode device:(int)device
{
	%orig;
	[[self _topBar] pl_setHidden:device != 1 animated:YES];
}

%end

%end

%group iOS8

%hook CAMCameraView

- (BOOL)_shouldHideFlashButtonForMode:(int)mode
{
	if (FrontFlashOnRecursively && cameraDevice() == 1) {
		MSHookIvar<int>(cameraInstance(), "_cameraDevice") = 0;
		BOOL r = %orig;
		MSHookIvar<int>(cameraInstance(), "_cameraDevice") = 1;
		return r;
	}
	return %orig;
}
	
%end
	
%end

%group CT2

%hook CameraBar

- (void)startTimerMode
{
	%orig;
	fromCT2 = MSHookIvar<int>(self, "prevTimerMode") == 2;
}

- (void)countTheSeconds:(id)seconds
{
	if (MSHookIvar<int>(self, "prevTimerMode") == 2 && MSHookIvar<int>(self, "iSeconds") == 2) {
		BOOL flashModeIsOn = (((CAMFlashButton *)flashBtn()).flashMode == 1);
		BOOL flashModeOk = flashModeIsOn || frontFlashActive;
		if (flashModeOk && isFrontCamera) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.7*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
				flashScreen();
			});
			%orig;
			fromCT2 = NO;
		} else
			%orig;
	} else
		%orig;
}

%end

%end

#define AddObserver(voidName, identifier) CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, voidName, CFSTR(identifier), NULL, CFNotificationSuspensionBehaviorCoalesce);
#define VOID(name) name(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)

static void VOID(PreferencesChangedCallback)
{
	system("killall Camera");
	FFLoader();
}

static void VOID(FlashScreen)
{
	UIColor *flashColor;
	switch (colorProfile) {
		case 1:
			flashColor = [UIColor whiteColor];
			break;
		case 2:
			flashColor = [UIColor colorWithRed:1 green:.99 blue:.47 alpha:1];
			break;
		case 3:
			flashColor = [UIColor colorWithRed:.66 green:.94 blue:1 alpha:1];
			break;
		case 4:
			flashColor = [UIColor colorWithHue:hue saturation:sat brightness:bri alpha:alpha];
			break;
	}
	if (isiOS8Up)
		[[%c(SBScreenFlash) mainScreenFlasher] flashColor:flashColor withCompletion:nil];
	else
		[[%c(SBScreenFlash) sharedInstance] flashColor:flashColor];
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist"];
	float previousBacklightLevel = dict ? [dict[@"SBBacklightLevel2"] floatValue] : .5;
	dispatch_queue_t delayReleaseQueue = dispatch_queue_create("com.PS.FrontFlash.delayRelease", NULL);
	dispatch_async(delayReleaseQueue, ^{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDimDuration*NSEC_PER_SEC), delayReleaseQueue, ^(void){
			[[UIScreen mainScreen] setBrightness:previousBacklightLevel];
		});
	});
	dispatch_release(delayReleaseQueue);
}

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, PreferencesChangedNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
	FFLoader();
	NSString *ident = [[NSBundle mainBundle] bundleIdentifier];
	if ([ident isEqualToString:@"com.apple.springboard"]) {
		AddObserver(FlashScreen, FrontFlashFlashScreenNotification)
	}
	if (FrontFlashOn) {
		dlopen("/System/Library/PrivateFrameworks/PhotoLibrary.framework/PhotoLibrary", RTLD_LAZY);
		dlopen("/System/Library/PrivateFrameworks/CameraKit.framework/CameraKit", RTLD_LAZY);
		Class CameraView = isiOS8 ? objc_getClass("CAMCameraView") : objc_getClass("PLCameraView");
		Class CameraController = isiOS8 ? objc_getClass("CAMCaptureController") : objc_getClass("PLCameraController");
		if (isiOS45) {
			if (isiOS4) {
				%init(iOS4);
			}
			if (dlopen("/Library/MobileSubstrate/DynamicLibraries/StillCapture2.dylib", RTLD_LAZY) != NULL) {
				%init(SC2iOS45);
			}
		}
		if (isiOS56) {
			%init(iOS56);
		}
		if (isiOS78) {
			if (dlopen("/Library/MobileSubstrate/DynamicLibraries/CameraTweak2.dylib", RTLD_LAZY) != NULL) {
				%init(CT2);
			}
			%init(iOS78, CAMERAVIEW = CameraView);
			if (IPAD) {
				%init(iOS78iPad, CAMERAVIEW = CameraView);
			}
			if (isiOS70) {
				%init(iOS70);
			}
			else if (isiOS71 || isiOS8) {
				%init(iOS718);
			}
		}
		if (!isiOS8) {
			%init(CommonPre8);
		} else {
			%init(iOS8);
		}
		%init(Common, CAMERACONTROLLER = CameraController);
	}
	[pool drain];
}
