#import "FrontFlash.h"

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	system("killall Camera");
	FFLoader();
}

static void flashScreen()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist"];
	previousBacklightLevel = isiOS4 ? ((dict != nil) ? [[dict objectForKey:@"SBBacklightLevel2"] floatValue] : 0.5) : [UIScreen mainScreen].brightness;
	GSEventSetBacklightLevel(1.0);
	UIWindow* window = [UIApplication sharedApplication].keyWindow;
   	flashView = [[UIView alloc] initWithFrame: CGRectMake(0.0f, 0.0f, window.frame.size.width, window.frame.size.height)];
   	[flashView setTag:9596];
	switch (colorProfile) {
	case 1:
		flashView.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:alpha];
		break;
	case 2:
		flashView.backgroundColor = [UIColor colorWithRed:1.0f green:0.99f blue:0.47f alpha:alpha];
		break;
	case 3:
		flashView.backgroundColor = [UIColor colorWithRed:0.66f green:0.94f blue:1.0f alpha:alpha];
		break;
	case 4:
		flashView.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
		break;
	}
    [window addSubview:flashView];
}

static void unflashScreen()
{
	[UIView animateWithDuration:kFadeDuration delay:0.0 options:0
		animations:^{
			flashView.alpha = 0.0f;
		}
		completion:^(BOOL finished) {
			[flashView removeFromSuperview];
			flashView = nil;
			[flashView release];
			[[UIApplication sharedApplication] setBacklightLevel:previousBacklightLevel];
			GSEventSetBacklightLevel(previousBacklightLevel);
		}
	];
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
    	if (flashView != nil && isFrontCamera)
   			unflashScreen();
   	}
}

- (void)takePictureDuringVideoOpenIrisAnimationFinished
{
    %orig;
    if (FrontFlashOnInVideo) {
    	if (flashView != nil && isFrontCamera)
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
	if (isCapturingVideo && mode == -1 && !reallyHasFlash && self.flashMode == 1)
		%orig(1, delegate);
	else
		%orig;
}

- (void)_collapseAndSetMode:(int)mode animated:(BOOL)animated
{
	if (mode == 0 && isFrontCamera)
		%orig(-1, animated);
	else
		%orig;
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

- (void)captureImage
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
			if (flashView != nil && isFrontCamera && FrontFlashOnInVideo) {
				[UIView animateWithDuration:kFadeDuration delay:0.0 options:0
					animations:^{
						flashView.alpha = 0.0f;
					}
				completion:^(BOOL finished) {
					[flashView removeFromSuperview];
					flashView = nil;
					[flashView release];
					[[UIApplication sharedApplication] setBacklightLevel:previousBacklightLevel];
					GSEventSetBacklightLevel(previousBacklightLevel);
				}];
			}
		});
    } else %orig;
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
					if (flashView != nil && isFrontCamera && FrontFlashOnInVideo) {
						[UIView animateWithDuration:kFadeDuration delay:0.0 options:0
							animations:^{
								flashView.alpha = 0.0f;
							}
						completion:^(BOOL finished) {
							[flashView removeFromSuperview];
							flashView = nil;
							[flashView release];
							[[UIApplication sharedApplication] setBacklightLevel:previousBacklightLevel];
							GSEventSetBacklightLevel(previousBacklightLevel);
						}];
					}
				});
    		}
    	});
    } else %orig;
}

%end

%group iOS71

%hook CAMTriStateButton

- (void)_collapseAndSetMode:(int)mode animated:(BOOL)animated
{
	if (mode == 0 && isFrontCamera)
		%orig(-1, animated);
	else
		%orig;
}

- (void)setFlashMode:(int)mode notifyDelegate:(BOOL)delegate
{
	if (isCapturingVideo && mode == -1 && !reallyHasFlash && self.flashMode == 1)
		%orig(1, delegate);
	else
		%orig;
}

%end

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

- (void)_collapseAndSetMode:(int)mode animated:(BOOL)animated
{
	if (mode == 0 && isFrontCamera)
		%orig(-1, animated);
	else
		%orig;
}

- (void)setFlashMode:(int)mode notifyDelegate:(BOOL)delegate
{
	if (isCapturingVideo && mode == -1 && !reallyHasFlash && self.flashMode == 1)
		%orig(1, delegate);
	else
		%orig;
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
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (isiOS70 ? 0.5 : 0)*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
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
	return CGSizeMake(190, 40);
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

- (void)_createFlashButtonIfNecessary
{
	hook2 = YES;
	%orig;
	hook2 = NO;
}

- (void)_applyTopBarRotationForDeviceOrientation:(int)orientation
{
	hook = YES;
	%orig;
	hook = NO;
	[self._topBar pl_setHidden:!(self.cameraDevice == 1) animated:YES];
}

%end

%end


%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	FFLoader();
	if (FrontFlashOn) {
		if (isiOS4 || isiOS5) {
			if (isiOS4) {
				%init(iOS4);
			}
			void *openSC2 = dlopen("/Library/MobileSubstrate/DynamicLibraries/StillCapture2.dylib", RTLD_LAZY);
			if (openSC2 != NULL) {
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
	}
	[pool drain];
}
