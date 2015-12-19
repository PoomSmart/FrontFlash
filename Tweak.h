#import <Foundation/Foundation.h>

static BOOL FrontFlashOnInPhoto;
static BOOL FrontFlashOnInVideo;
#define FrontFlashOn (FrontFlashOnInPhoto || FrontFlashOnInVideo)
static BOOL onFlash;
static BOOL reallyHasFlash;

CGFloat alpha;
CGFloat hue;
CGFloat sat;
CGFloat bri;

static int colorProfile;

static void FFLoader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	id val = dict[@"FrontFlashOnInPhoto"];
	FrontFlashOnInPhoto = val ? [val boolValue] : YES;
	val = dict[@"FrontFlashOnInVideo"];
	FrontFlashOnInVideo = val ? [val boolValue] : YES;
	val = dict[@"Hue"];
	hue = val ? [val floatValue] : 1;
	val = dict[@"Sat"];
	sat = val ? [val floatValue] : 1;
	val = dict[@"Bri"];
	bri = val ? [val floatValue] : 1;
	val = dict[@"Alpha"];
	alpha = val ? [val floatValue] : 1;
	val = dict[@"colorProfile"];
	colorProfile = val ? [val intValue] : 1;
}

UIColor *frontFlashColor()
{
	UIColor *flashColor = [UIColor whiteColor];
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

static void flashScreen(UIView *keyWindow, void (^completionBlock)(void))
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

#define VOID(name) name(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
static void VOID(PreferencesChangedCallback)
{
	system("killall Camera");
	FFLoader();
}