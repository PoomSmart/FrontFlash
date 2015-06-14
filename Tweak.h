#import <Foundation/Foundation.h>

static BOOL FrontFlashOnInPhoto;
static BOOL FrontFlashOnInVideo;
#define FrontFlashOn (FrontFlashOnInPhoto || FrontFlashOnInVideo)
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
	id val = dict[@"FrontFlashOnInPhoto"];
	FrontFlashOnInPhoto = val ? [val boolValue] : YES;
	val = dict[@"FrontFlashOnInVideo"];
	FrontFlashOnInVideo = val ? [val boolValue] : YES;
	val = dict[@"Hue"];
	hue = val ? [val floatValue] : 1.0f;
	val = dict[@"Sat"];
	sat = val ? [val floatValue] : 1.0f;
	val = dict[@"Bri"];
	bri = val ? [val floatValue] : 1.0f;
	val = dict[@"Alpha"];
	alpha = val ? [val floatValue] : 1.0f;
	val = dict[@"colorProfile"];
	colorProfile = val ? [val intValue] : 1;
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

#define VOID(name) name(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
static void VOID(PreferencesChangedCallback)
{
	system("killall Camera");
	FFLoader();
}
