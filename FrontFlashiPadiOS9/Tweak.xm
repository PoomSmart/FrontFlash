#import "../FrontFlash.h"
#import <substrate.h>

static BOOL hook;
static BOOL hook2;

%hook CMKPadApplicationSpec

- (BOOL)shouldCreateTopBar
{
	return YES;
}

- (BOOL)shouldCreateFlashButton
{
	return YES;
}

%end

%hook CMKTopBar

- (CGSize)sizeThatFits:(CGSize)size
{
	return CGSizeMake(200.0f, 40.0f);
}

%end

%hook CMKCameraSpec

- (BOOL)isPad
{
	return hook ? NO : YES;
}
- (BOOL)isPhone
{
	return hook2 ? YES : NO;
}

%end

%hook CMKCameraView

- (BOOL)_shouldApplyRotationDirectlyToTopBarForOrientation:(NSInteger)orientation cameraMode:(NSInteger)mode
{
	return YES;
}

- (BOOL)_shouldHideTopBarForMode:(NSInteger)mode
{
	return self.cameraDevice != 1;
}

- (void)_createFlashButtonIfNecessary
{
	hook2 = YES;
	%orig;
	hook2 = NO;
}

- (void)_showControlsForReturningFromSuspensionAnimated:(BOOL)animated
{
	%orig;
	if (self.cameraDevice != 1)
		[self._topBar cam_setHidden:YES animated:NO];
}

- (void)_showControlsForChangeToMode:(NSInteger)mode animated:(BOOL)animated
{
	%orig;
	if (self.cameraDevice != 1)
		[self._topBar cam_setHidden:YES animated:NO];
}

- (void)_updateTopBarStyleForDeviceOrientation:(NSInteger)orientation
{
	%orig;
	if (self.cameraDevice == 1)
		[self._topBar setStyle:1 animated:NO];
	else
		[self._topBar cam_setHidden:YES animated:NO];
}

- (void)_applyTopBarRotationForDeviceOrientation:(NSInteger)orientation
{
	hook = YES;
	%orig;
	hook = NO;
	if (self.cameraDevice == 1) {
		[self._topBar setStyle:1 animated:NO];
		[self _updateTopBarStyleForDeviceOrientation:orientation];
	} else
		[self._topBar cam_setHidden:YES animated:NO];
}

- (void)cameraController:(id)controller willChangeToMode:(NSInteger)mode device:(NSInteger)device
{
	%orig;
	[self._topBar cam_setHidden:(device != 1) animated:YES];
}

%end

%ctor
{
	%init;
}
