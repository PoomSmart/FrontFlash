#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Social/Social.h>
#import "NKOColorPickerView.h"
#import "FrontFlash.h"

__attribute__((visibility("hidden")))
@interface FrontFlashPreferenceController : PSListController
@end

@interface FrontFlashColorPickerViewController : UIViewController
@end

@implementation FrontFlashColorPickerViewController

NKOColorPickerDidChangeColorBlock colorDidChangeBlock = ^(UIColor *color){
    NSMutableDictionary *dict = [[NSMutableDictionary dictionaryWithContentsOfFile:PREF_PATH] mutableCopy] ?: [NSMutableDictionary dictionary];
    CGFloat hue, sat, bri;
    BOOL getColor = [color getHue:&hue saturation:&sat brightness:&bri alpha:nil];
    if (getColor) {
		[dict setObject:@(hue) forKey:@"Hue"];
		[dict setObject:@(sat) forKey:@"Sat"];
		[dict setObject:@(bri) forKey:@"Bri"];
		[dict writeToFile:PREF_PATH atomically:YES];
	}
};

- (UIColor *)savedCustomColor
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	if (dict[@"Hue"] == nil || dict[@"Sat"] == nil|| dict[@"Bri"] == nil)
		return [UIColor whiteColor];
	CGFloat hue, sat, bri;
	hue = [dict[@"Hue"] floatValue];
	sat = [dict[@"Sat"] floatValue];
	bri = [dict[@"Bri"] floatValue];
	UIColor *color = [UIColor colorWithHue:hue saturation:sat brightness:bri alpha:1];
	return color;
}

- (id)init
{
	if (self == [super init]) {
		NKOColorPickerView *colorPickerView = [[[NKOColorPickerView alloc] initWithFrame:CGRectMake(0, 0, 300, 340) color:[[self savedCustomColor] retain] andDidChangeColorBlock:colorDidChangeBlock] autorelease];
		colorPickerView.backgroundColor = [UIColor blackColor];
		self.view = colorPickerView;
		self.navigationItem.title = @"Select Color";
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:0 target:self action:@selector(dismissPicker)] autorelease];
	}
	return self;
}

- (void)dismissPicker
{
	[[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
}

@end

@implementation FrontFlashPreferenceController

- (id)init
{
	if (self == [super init]) {
		UIButton *heart = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
		[heart setImage:[UIImage imageNamed:@"Heart" inBundle:[NSBundle bundleWithPath:@"/Library/PreferenceBundles/CamBlur7Settings.bundle"]] forState:UIControlStateNormal];
		[heart sizeToFit];
		[heart addTarget:self action:@selector(love) forControlEvents:UIControlEventTouchUpInside];
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:heart] autorelease];
	}
	return self;
}

- (void)love
{
	SLComposeViewController *twitter = [[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter] retain];
	[twitter setInitialText:@"#FrontFlash by @PoomSmart is awesome!"];
	if (twitter != nil)
		[[self navigationController] presentViewController:twitter animated:YES completion:nil];
	[twitter release];
}

- (void)donate:(id)param
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:PS_DONATE_URL]];
}

- (void)twitter:(id)param
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:PS_TWITTER_URL]];
}

- (void)showColorPicker:(id)param
{
	FrontFlashColorPickerViewController *picker = [[[FrontFlashColorPickerViewController alloc] init] autorelease];
	UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:picker] autorelease];
	nav.modalPresentationStyle = 2;
	[[self navigationController] presentViewController:nav animated:YES completion:nil];
}

- (NSArray *)specifiers
{
	if (_specifiers == nil) {
		NSMutableArray *specs = [NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"FrontFlash" target:self]];
		_specifiers = [specs copy];
	}
	return _specifiers;
}

@end
