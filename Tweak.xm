#import "FrontFlash.h"

#define declareFlashBtn() \
	id flashBtn; \
	if (isiOS78) \
		flashBtn = MSHookIvar<CAMFlashButton *>(self, "__flashButton"); \
	else \
		flashBtn = MSHookIvar<PLCameraFlashButton *>(self, "_flashButton");
		
#define declareFlashBtn2() \
	id flashBtn; \
	if (isiOS78) \
		flashBtn = MSHookIvar<CAMFlashButton *>([self delegate], "__flashButton"); \
	else \
		flashBtn = MSHookIvar<PLCameraFlashButton *>([self delegate], "_flashButton");
	
#define kDelayDuration .22
#define kFadeDuration .35

static BOOL FrontFlashOnInPhoto = YES;
static BOOL FrontFlashOnInVideo = YES;
#define FrontFlashOn (FrontFlashOnInPhoto || FrontFlashOnInVideo)
#define FrontFlashOnRecursively ((FrontFlashOnInPhoto && ([self cameraMode] == 0 || [self cameraMode] == 4)) || (FrontFlashOnInVideo && [self cameraMode] == 1))
static BOOL isFrontCamera;
static BOOL frontFlashActive;
static BOOL onFlash = NO;
static BOOL reallyHasFlash;

static float previousBacklightLevel;
static CGFloat alpha = 1;
static CGFloat hue = 1;
static CGFloat sat = 1;
static CGFloat bri = 1;

static int colorProfile = 1;

static UIView *flashView = nil;

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

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	system("killall Camera");
	FFLoader();
}

static void flashScreen(id cameraView)
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist"];
	previousBacklightLevel = isiOS4 ? (dict ? [dict[@"SBBacklightLevel2"] floatValue] : .5) : [UIScreen mainScreen].brightness;
	GSEventSetBacklightLevel(1.0);
	CGRect frame = [UIScreen mainScreen].bounds;
	if (flashView == nil) {
   		flashView = [[UIView alloc] initWithFrame:frame];
   		flashView.tag = 9596;
   	}
   	flashView.alpha = 1;
	switch (colorProfile) {
		case 1:
			flashView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
			break;
		case 2:
			flashView.backgroundColor = [UIColor colorWithRed:1 green:.99 blue:.47 alpha:1];
			break;
		case 3:
			flashView.backgroundColor = [UIColor colorWithRed:.66 green:.94 blue:1 alpha:1];
			break;
		case 4:
			flashView.backgroundColor = [UIColor colorWithHue:hue saturation:sat brightness:bri alpha:alpha];
			break;
	}
    [cameraView addSubview:flashView];
}

static void unflashScreen(id cameraView)
{
	UIView *flashViewHere = [cameraView viewWithTag:9596];
	if (flashViewHere == nil)
		return;
	[UIView animateWithDuration:kFadeDuration delay:0 options:0
		animations:^{
			flashViewHere.alpha = 0;
	}
	completion:^(BOOL finished) {
		if (finished) {
			[[UIApplication sharedApplication] setBacklightLevel:previousBacklightLevel];
			GSEventSetBacklightLevel(previousBacklightLevel);
		}
	}];
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


%group iOS56

%hook UIImage

+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle
{
	return %orig;
}

%end

%hook PLCameraView

- (void)takePictureOpenIrisAnimationFinished
{
	%orig;
	if (FrontFlashOnInPhoto) {
		if (isFrontCamera)
			unflashScreen(self);
	}
}

- (void)takePictureDuringVideoOpenIrisAnimationFinished
{
	%orig;
	if (FrontFlashOnInVideo) {
		if (isFrontCamera)
			unflashScreen(self);
	}
}

- (void)cameraShutterClicked:(id)arg1
{
	%orig;
	declareFlashBtn()
	if (self.cameraDevice == 1) {
		[flashBtn setHidden:NO];
		[flashBtn setUserInteractionEnabled:YES];
	} else {
		if (!reallyHasFlash)
			[flashBtn setHidden:YES];
	}
}

- (void)_updateOverlayControls
{
	onFlash = YES;
	%orig;
	onFlash = NO;
	declareFlashBtn()
	if (self.cameraDevice == 1)
		[flashBtn setHidden:NO];
	else {
		if (!reallyHasFlash)
			[flashBtn setHidden:YES];
	}
}

- (void)_postCaptureCleanup
{
	%orig;
	declareFlashBtn()
	if (self.cameraDevice == 1)
		[flashBtn setHidden:NO];
	else {
		if (!reallyHasFlash)
			[flashBtn setHidden:YES];
	}
}

- (void)_commonPostVideoCaptureCleanup
{
	%orig;
	declareFlashBtn()
	if (self.cameraDevice == 1)
		[flashBtn setHidden:NO];
	else {
		if (!reallyHasFlash)
			[flashBtn setHidden:YES];
	}
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
	if (cameraDevice() == 1)
		frontFlashActive = (mode == 1);
}

- (void)captureOutput:(id)arg1 didStartRecordingToOutputFileAtURL:(id)arg2 fromConnections:(id)arg3
{
	%orig;
	declareFlashBtn2()
	if (cameraDevice() == 1)
		[flashBtn setAutoHidden:NO];
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
	declareFlashBtn()
	if (self.cameraDevice == 1) {
		if (!isiOS4)
			[flashBtn setAutoHidden:NO];
	}
}

- (void)_shutterButtonClicked
{
	declareFlashBtn()
	if (cameraDevice() == 1) {
		[flashBtn setHidden:NO];
		[flashBtn setUserInteractionEnabled:YES];
	} else {
		if (!reallyHasFlash)
			[flashBtn setHidden:YES];
	}
	if (!isFrontCamera) {
		%orig;
		return;
	}
	if (isiOS78) {
		if ([cameraInstance() performingTimedCapture]) {
			%orig;
			return;
		}
	}
	/*else if (isiOS56) {
		PLCameraButton *button = (PLCameraButton *)[(PLCameraButtonBar *)self.bottomButtonBar cameraButton];
		BOOL BurstModeEnabled = [[[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.PS.BurstMode.plist"] objectForKey:@"BurstModeEnabled"] boolValue];
		if ([button respondsToSelector:@selector(burst)] && BurstModeEnabled && button.highlighted) {
			%orig;
			return;
		}
	}*/
	BOOL flashModeIsOn = isiOS78 ? (((CAMFlashButton *)flashBtn).flashMode == 1) : (((PLCameraFlashButton *)flashBtn).flashMode == 1);
	if ((flashModeIsOn || frontFlashActive)) {
		flashScreen(self);
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDelayDuration*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			%orig;
			if (isiOS78) {
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDelayDuration*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
					unflashScreen(self);
				});
			}
		});
	} else
		%orig;
}

%end

%end

%group SC2iOS45

%hook PLCameraView

- (void)sc2_captureImage
{
	declareFlashBtn()
	if (FrontFlashOnInVideo) {
		if (reallyHasFlash) {
			[flashBtn setHidden:NO];
			[flashBtn setUserInteractionEnabled:YES];
		}
	}
	if ((((PLCameraFlashButton *)flashBtn).flashMode == 1 || frontFlashActive) && isFrontCamera) {
		flashScreen(self);
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDelayDuration*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			%orig;
			if (isFrontCamera && FrontFlashOnInVideo)
				unflashScreen(self);
		});
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
		declareFlashBtn()
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (isiOS70 ? .2 : 0)*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			[flashBtn pl_setHidden:NO animated:YES];
		});
	}
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

- (void)_captureStillImageWithRequest:(id)arg1
{
	declareFlashBtn()
	if (cameraDevice() == 1) {
		[flashBtn setHidden:NO];
		[flashBtn setUserInteractionEnabled:YES];
	} else {
		if (!reallyHasFlash)
			[flashBtn setHidden:YES];
	}
	if (!isFrontCamera || [cameraInstance() performingTimedCapture]) {
		%orig;
		return;
	}

	BOOL flashModeIsOn = ((CAMFlashButton *)flashBtn).flashMode == 1;
	if ((flashModeIsOn || frontFlashActive)) {
		flashScreen(self);
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDelayDuration*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			%orig;
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDelayDuration*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
				unflashScreen(self);
			});
		});
	} else
		%orig;
}
	
%end
	
%end

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	FFLoader();
	if (FrontFlashOn) {
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
