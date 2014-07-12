#import "FrontFlash.h"

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	system("killall Camera");
	FFLoader();
}

static void flashScreen()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist"];
	previousBacklightLevel = isiOS4 ? ((dict != nil) ? [[dict objectForKey:@"SBBacklightLevel2"] floatValue] : .5) : [UIScreen mainScreen].brightness;
	GSEventSetBacklightLevel(1.0);
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
   	flashView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, window.frame.size.width, window.frame.size.height)];
   	flashView.tag = 9596;
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
		flashView.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
		break;
	}
    [window addSubview:flashView];
}

static void unflashScreen()
{
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	for (UIView *view in window.subviews) {
		if (view.tag == 9596) {
			[UIView animateWithDuration:kFadeDuration delay:0 options:0
				animations:^{
					if (view != nil)
						view.alpha = 0;
				}
				completion:^(BOOL finished) {
					if (finished) {
						if (view != nil) {
							[view removeFromSuperview];
							[view release];
						}
						[[UIApplication sharedApplication] setBacklightLevel:previousBacklightLevel];
						GSEventSetBacklightLevel(previousBacklightLevel);
					}
				}
			];
		}
	}
}


%hook UIImage

+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle
{
	return %orig;
}

%end

%group iOS56

%hook PLCameraView

- (void)takePictureOpenIrisAnimationFinished
{
	%orig;
	if (FrontFlashOnInPhoto) {
		if (isFrontCamera)
			unflashScreen();
	}
}

- (void)takePictureDuringVideoOpenIrisAnimationFinished
{
	%orig;
	if (FrontFlashOnInVideo) {
		if (isFrontCamera)
			unflashScreen();
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
	%orig(isCapturingVideo && mode == -1 && !reallyHasFlash && self.flashMode == 1 ? 1 : mode, delegate);
}

- (void)_collapseAndSetMode:(int)mode animated:(BOOL)animated
{
	%orig(mode == 0 && isFrontCamera ? -1 : mode, animated);
}

%end

%end

%hook PLCameraController

- (BOOL)hasFlash
{
	reallyHasFlash = %orig;
	return onFlash ? YES : reallyHasFlash;
}

%group iOS4

- (void)_setCameraMode:(int)mode cameraDevice:(int)device force:(BOOL)force
{
	isFrontCamera = (device == 1);
	%orig;
}

%end

- (void)_setCameraMode:(int)mode cameraDevice:(int)device
{
	isFrontCamera = (device == 1);
	%orig;
}

- (void)_setFlashMode:(int)mode force:(BOOL)arg2
{
	%orig;
	if (self.cameraDevice == 1)
		frontFlashActive = (mode == 1);
}

%end

%hook PLCameraView

- (BOOL)_flashButtonShouldBeHidden
{
	if (FrontFlashOnRecursively && self.cameraDevice == 1)
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

%group SC2iOS45

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
		flashScreen();
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDelayDuration*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			%orig;
			if (isFrontCamera && FrontFlashOnInVideo)
				unflashScreen();
		});
    } else
    	%orig;
}

%end

- (void)_shutterButtonClicked
{
	declareFlashBtn()
	if (self.cameraDevice == 1) {
		[flashBtn setHidden:NO];
		[flashBtn setUserInteractionEnabled:YES];
	} else {
		if (!reallyHasFlash)
			[flashBtn setHidden:YES];
	}
	BOOL flashModeIsOn = isiOS7 ? (((CAMFlashButton *)flashBtn).flashMode == 1) : (((PLCameraFlashButton *)flashBtn).flashMode == 1);
	if ((flashModeIsOn || frontFlashActive) && isFrontCamera) {
		flashScreen();
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDelayDuration*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			%orig;
			if (isiOS7) {
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDelayDuration*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
					if (isFrontCamera)
						unflashScreen();
				});
			}
		});
	} else
		%orig;
}

%end

%group iOS71

%hook CAMTopBar

- (void)_updateHiddenViewsForButtonExpansionAnimated:(BOOL)animated
{
	%orig;
	if (isCapturingVideo && isFrontCamera)
		[self.flashButton pl_setHidden:NO animated:YES];
}

%end

%end

%group iOS70

%hook CAMFlashButton

- (void)setFlashMode:(int)mode notifyDelegate:(BOOL)delegate
{
	int flashMode = mode;
	if (isCapturingVideo && mode == -1 && !reallyHasFlash && self.flashMode == 1)
		flashMode = 1;
	else if (mode == 0 && isFrontCamera)
		flashMode = -1;
	%orig(flashMode, delegate);
}

%end

%end

%group iOS7

%hook CAMTopBar

- (void)_setFlashButtonExpanded:(BOOL)expand
{
	%orig;
	if (isCapturingVideo && isFrontCamera)
		[self.elapsedTimeView pl_setHidden:expand animated:YES];
}

%end

%hook PLCameraView

- (void)_createDefaultControlsIfNecessary
{
	onFlash = YES;
	%orig;
	onFlash = NO;
}

- (BOOL)_shouldHideFlashButtonForMode:(int)mode
{
	if (FrontFlashOnRecursively && self.cameraDevice == 1)
		return NO;
	return %orig;
}

- (BOOL)_shouldEnableFlashButton
{
	if (FrontFlashOnRecursively && self.cameraDevice == 1)
		return YES;
	return %orig;
}

- (void)_showControlsForCapturingVideoAnimated:(BOOL)animated
{
	%orig;
	if (FrontFlashOnInVideo && self.cameraDevice == 1) {
		[self._topBar setStyle:0 animated:NO];
		[self _updateTopBarStyleForDeviceOrientation:[[%c(PLCameraController) sharedInstance] cameraOrientation]];
		declareFlashBtn()
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (isiOS70 ? .2 : 0)*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			[flashBtn pl_setHidden:NO animated:YES];
		});
	}
}

%end

%end

%group iOS7iPad

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

%hook PLCameraView

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
	[self._topBar setStyle:1 animated:NO];
}

- (void)_applyTopBarRotationForDeviceOrientation:(int)orientation
{
	hook = YES;
	%orig;
	hook = NO;
	[self._topBar pl_setHidden:self.cameraDevice != 1 animated:YES];
	[self._topBar setStyle:1 animated:NO];
	[self _updateTopBarStyleForDeviceOrientation:orientation];
}

- (void)cameraController:(id)cont willChangeToMode:(int)mode device:(int)device
{
	%orig;
	[self._topBar pl_setHidden:device != 1 animated:YES];
}

%end

%end


%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	FFLoader();
	if (!FrontFlashOn) {
		[pool drain];
		return;
	}
	if (isiOS4 || isiOS5) {
		if (isiOS4) {
			%init(iOS4);
		}
		if (dlopen("/Library/MobileSubstrate/DynamicLibraries/StillCapture2.dylib", RTLD_LAZY | RTLD_NOLOAD) != NULL) {
			%init(SC2iOS45);
		}
	}
	if (isiOS5 || isiOS6) {
		%init(iOS56);
	}
	if (isiOS7) {
		%init(iOS7);
		if (IPAD) {
			%init(iOS7iPad);
		}
		if (isiOS70) {
			%init(iOS70);
		}
		else if (isiOS71) {
			%init(iOS71);
		}
	}
	%init();
	[pool drain];
}
