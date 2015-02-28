#import "../FrontFlash.h"
#import <substrate.h>

static BOOL FrontFlashOnInPhoto;
static BOOL FrontFlashOnInVideo;
#define FrontFlashOn (FrontFlashOnInPhoto || FrontFlashOnInVideo)
#define FrontFlashOnRecursively ((self.cameraDevice == 1) && ((FrontFlashOnInPhoto && (self.cameraMode == 0)) || (FrontFlashOnInVideo && (self.cameraMode == 1))))
static BOOL frontFlashActive;
static BOOL onFlash;
static BOOL reallyHasFlash;

static CGFloat alpha;
static CGFloat hue;
static CGFloat sat;
static CGFloat bri;

static int colorProfile;

static void FFLoader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	FrontFlashOnInPhoto = dict[@"FrontFlashOnInPhoto"] ? [dict[@"FrontFlashOnInPhoto"] boolValue] : YES;
	FrontFlashOnInVideo = dict[@"FrontFlashOnInVideo"] ? [dict[@"FrontFlashOnInVideo"] boolValue] : YES;
	hue = dict[@"Hue"] ? [dict[@"Hue"] floatValue] : 1.0f;
	sat = dict[@"Sat"] ? [dict[@"Sat"] floatValue] : 1.0f;
	bri = dict[@"Bri"] ? [dict[@"Bri"] floatValue] : 1.0f;
	alpha = dict[@"Alpha"] ? [dict[@"Alpha"] floatValue] : 1;
	colorProfile = dict[@"colorProfile"] ? [dict[@"colorProfile"] intValue] : 1;
}

static void flashScreen(void (^completionBlock)(void))
{
	UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
	float previousBacklightLevel = [UIScreen mainScreen].brightness;
	[UIScreen mainScreen].brightness = 1.0f;
	UIView *flashView = [[UIView alloc] initWithFrame:keyWindow.bounds];
	UIColor *flashColor;
	switch (colorProfile) {
		case 1:
			flashColor = [UIColor whiteColor];
			break;
		case 2:
			flashColor = [UIColor colorWithRed:1.0f green:0.99f blue:0.47f alpha:1.0f];
			break;
		case 3:
			flashColor = [UIColor colorWithRed:0.66f green:0.94f blue:1.0f alpha:1.0f];
			break;
		case 4:
			flashColor = [UIColor colorWithHue:hue saturation:sat brightness:bri alpha:alpha];
			break;
	}
	flashView.backgroundColor = flashColor;
	flashView.alpha = 0.0f;
	[keyWindow addSubview:flashView];
	[UIView animateWithDuration:kDelayDuration delay:0.0f options:UIViewAnimationCurveEaseOut
		animations:^{
			flashView.alpha = 1.0f;
		}
		completion:^(BOOL finished1) {
			if (finished1) {
				if (completionBlock)
					completionBlock();
				[UIView animateWithDuration:kDimDuration delay:0.0f options:UIViewAnimationCurveEaseOut
					animations:^{
						flashView.alpha = 0.0f;
					}
					completion:^(BOOL finished2) {
						if (finished2) {
							[flashView removeFromSuperview];
							[flashView release];
							[UIScreen mainScreen].brightness = previousBacklightLevel;
						}
					}];
			}
	}];
}

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

#define VOID(name) name(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
static void VOID(PreferencesChangedCallback)
{
	system("killall Camera");
	FFLoader();
}

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
