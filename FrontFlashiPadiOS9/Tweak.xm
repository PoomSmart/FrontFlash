#import "../FrontFlash.h"
#import <substrate.h>

%hook CAMViewfinderView

- (CGSize)_topBarSizeForTraitCollection:(id)arg1
{
	return CGSizeMake(200.0f, 40.0f);
}

%end

%hook CAMViewfinderViewController

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

%ctor
{
	%init;
}