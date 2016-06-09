#import <substrate.h>
#import "../../PS.h"

BOOL override = NO;

%hook CAMViewfinderView

- (CGSize)_topBarSizeForTraitCollection:(id)arg1
{
	return CGSizeMake(200.0, 40.0);
}

%end

%hook CAMTopBar

- (CGFloat)_backgroundCornerRadiusForStyle:(int)style
{
	return %orig(1);
}

%end

%hook CAMBottomBar

+ (BOOL)wantsVerticalBarForTraitCollection:(id)arg1
{
	return override ? NO : %orig;
}

%end

%hook CAMViewfinderViewController

- (void)_embedFlashButtonWithTraitCollection:(id)arg1
{
	override = YES;
	%orig;
	override = NO;
}

- (int)_topBarBackgroundStyleForMode:(int)mode
{
	return self._currentDevice == 1 ? 0 : %orig;
}

- (BOOL)_shouldRotateTopBarForMode:(int)mode device:(int)device
{
	return YES;
}

- (BOOL)_shouldHideTopBarForMode:(int)mode device:(int)device
{
	return device == 1 ? NO : %orig;
}

%end