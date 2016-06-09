#import <HBPreferences.h>
#import "../PS.h"

NSString *tweakIdentifier = @"com.PS.FrontFlash";

NSString *FrontFlashOnInPhotoKey = @"FrontFlashOnInPhoto";
NSString *FrontFlashOnInVideoKey = @"FrontFlashOnInVideo";
NSString *HueKey = @"Hue";
NSString *SatKey = @"Sat";
NSString *BriKey = @"Bri";
NSString *AlphaKey = @"Alpha";
NSString *colorProfileKey = @"colorProfile";

HBPreferences *preferences;

#ifdef TWEAK

#define kDelayDuration 0.35
#define kDimDuration 1

BOOL FrontFlashOnInPhoto;
BOOL FrontFlashOnInVideo;
#define FrontFlashOn (FrontFlashOnInPhoto || FrontFlashOnInVideo)
BOOL onFlash;
BOOL reallyHasFlash;

CGFloat alpha;
CGFloat hue;
CGFloat sat;
CGFloat bri;

NSInteger colorProfile;

UIColor *frontFlashColor()
{
	UIColor *flashColor = UIColor.whiteColor;
	switch (colorProfile) {
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
	return flashColor;
}

void flashScreen(UIView *keyWindow, void (^completionBlock)(void))
{
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

#endif

void registerPref(HBPreferences *preferences)
{
	[preferences registerDefaults:@{
		FrontFlashOnInPhotoKey : @YES,
		FrontFlashOnInVideoKey : @YES,
		HueKey : @1.0,
		SatKey : @1.0,
		BriKey : @1.0,
		AlphaKey : @1.0,
		colorProfileKey : @1
	}];
	#ifdef TWEAK
	[preferences registerBool:&FrontFlashOnInPhoto default:YES forKey:FrontFlashOnInPhotoKey];
	[preferences registerBool:&FrontFlashOnInVideo default:YES forKey:FrontFlashOnInVideoKey];
	[preferences registerFloat:&hue default:1.0 forKey:HueKey];
	[preferences registerFloat:&sat default:1.0 forKey:SatKey];
	[preferences registerFloat:&bri default:1.0 forKey:BriKey];
	[preferences registerFloat:&alpha default:1.0 forKey:AlphaKey];
	[preferences registerInteger:&colorProfile default:1 forKey:colorProfileKey];
	#endif
}