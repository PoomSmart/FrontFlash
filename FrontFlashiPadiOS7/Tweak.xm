#import "../FrontFlash.h"
#import <substrate.h>

static BOOL hook;
static BOOL hook2;

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
	return CGSizeMake(200.0, 40.0);
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

%hook CAMCameraView

- (BOOL)_shouldApplyRotationDirectlyToTopBarForOrientation:(int)orientation cameraMode:(int)mode
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
		[self._topBar pl_setHidden:YES animated:NO];
}

- (void)_showControlsForChangeToMode:(int)mode animated:(BOOL)animated
{
	%orig;
	if (self.cameraDevice != 1)
		[self._topBar pl_setHidden:YES animated:NO];
}

- (void)_updateTopBarStyleForDeviceOrientation:(int)orientation
{
	%orig;
	if (self.cameraDevice == 1)
		[self._topBar setStyle:1 animated:NO];
	else
		[self._topBar pl_setHidden:YES animated:NO];
}

- (void)_applyTopBarRotationForDeviceOrientation:(int)orientation
{
	hook = YES;
	%orig;
	hook = NO;
	if (self.cameraDevice == 1) {
		[self._topBar setStyle:1 animated:NO];
		[self _updateTopBarStyleForDeviceOrientation:orientation];
	} else
		[self._topBar pl_setHidden:YES animated:NO];
}

- (void)cameraController:(id)controller willChangeToMode:(int)mode device:(int)device
{
	%orig;
	[self._topBar pl_setHidden:(device != 1) animated:YES];
}

%end