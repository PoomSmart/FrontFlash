#import "../PS.h"
#import "../PSPrefs.x"

NSString *tweakIdentifier = @"com.PS.FrontFlash";

NSString *FrontFlashOnInPhotoKey = @"FrontFlashOnInPhoto";
NSString *FrontFlashOnInVideoKey = @"FrontFlashOnInVideo";
NSString *HueKey = @"Hue";
NSString *SatKey = @"Sat";
NSString *BriKey = @"Bri";
NSString *AlphaKey = @"Alpha";
NSString *colorProfileKey = @"colorProfile";

#ifdef TWEAK

#define kDelayDuration 0.35
#define kDimDuration 1

BOOL FrontFlashOnInPhoto;
BOOL FrontFlashOnInVideo;
#ifndef SUPPRESS_SETTINGS
#define FrontFlashOn (FrontFlashOnInPhoto || FrontFlashOnInVideo)
#else
#define FrontFlashOn YES
#endif
BOOL onFlash;
BOOL reallyHasFlash;

CGFloat alpha;
CGFloat hue;
CGFloat sat;
CGFloat bri;

NSInteger colorProfile;

UIColor *frontFlashColor() {
	UIColor *flashColor = UIColor.whiteColor;
	switch (colorProfile) {
		case 2:
			flashColor = [UIColor colorWithRed:1.0 green:0.99 blue:0.47 alpha:1.0];
			break;
		case 3:
			flashColor = [UIColor colorWithRed:0.66 green:0.94 blue:1.0 alpha:1.0];
			break;
		case 4:
			flashColor = [UIColor colorWithHue:hue saturation:sat brightness:bri alpha:alpha];
			break;
	}
	return flashColor;
}

void flashScreen(UIView *keyWindow, void (^completionBlock)(void)) {
	float previousBacklightLevel = [UIScreen mainScreen].brightness;
	UIScreen.mainScreen.brightness = 1;
	UIView *flashView = [[UIView alloc] initWithFrame:keyWindow.frame];
	UIColor *flashColor = frontFlashColor();
	flashView.backgroundColor = flashColor;
	flashView.alpha = 0;
	[keyWindow addSubview:flashView];
	[UIView animateWithDuration:kDelayDuration delay:0 options:UIViewAnimationCurveEaseOut
		animations:^{
			flashView.alpha = 1;
		}
		completion:^(BOOL finished1) {
			if (finished1) {
				if (completionBlock)
					completionBlock();
				[UIView animateWithDuration:kDimDuration delay:0 options:UIViewAnimationCurveEaseOut
					animations:^{
						flashView.alpha = 0;
					}
					completion:^(BOOL finished2) {
						if (finished2) {
							[flashView removeFromSuperview];
							[flashView release];
							UIScreen.mainScreen.brightness = previousBacklightLevel;
						}
					}];
			}
	}];
}

#ifndef SUPPRESS_SETTINGS

HaveCallback() {
	GetPrefs()
	GetBool2(FrontFlashOnInPhoto, YES)
	GetBool2(FrontFlashOnInVideo, YES)
	GetCGFloat(hue, HueKey, 1.0)
	GetCGFloat(sat, SatKey, 1.0)
	GetCGFloat(bri, BriKey, 1.0)
	GetCGFloat(alpha, AlphaKey, 1.0)
	GetInt2(colorProfile, 1)
}

#endif

#endif
