#import <UIKit/UIKit.h>
#import <Cephei/HBListController.h>
#import <Cephei/HBAppearanceSettings.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>
#import <Social/Social.h>
#import "NKOColorPickerView.h"
#import "Tweak.h"
#import <HBPreferences.h>
#import <dlfcn.h>

@interface FrontFlashPreferenceController : HBListController
@end

@interface FrontFlashColorPickerViewController : UIViewController <NKOColorPickerViewDelegate>
@property (retain) UIColor *color;
@end

NSString *updateCellColorNotification = @"com.PS.FrontFlash.prefs.colorUpdate";
NSString *IdentifierKey = @"FrontFlashColorCellIdentifier";

@interface FrontFlashColorCell : PSTableCell
@end

UIColor *savedCustomColor()
{
	CGFloat hue, sat, bri;
	hue = [preferences floatForKey:HueKey];
	sat = [preferences floatForKey:SatKey];
	bri = [preferences floatForKey:BriKey];
	UIColor *color = [UIColor colorWithHue:hue saturation:sat brightness:bri alpha:1];
	return color;
}

@implementation FrontFlashColorCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(PSSpecifier *)specifier
{
	if (self == [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier]) {
		[self updateColorCell];
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateColorCell:) name:updateCellColorNotification object:nil];
	}
	return self;
}

- (UIView *)colorCell
{
	UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
	circle.layer.cornerRadius = 14;
	circle.backgroundColor = savedCustomColor();
	return [circle autorelease];
}

- (void)updateColorCell:(NSNotification *)notification
{
	[self updateColorCell];
}

- (void)updateColorCell
{
	self.accessoryView = [[self colorCell] retain];
	self.titleLabel.textColor = savedCustomColor();
}

- (void)dealloc
{
	[NSNotificationCenter.defaultCenter removeObserver:self];
	[super dealloc];
}

@end

@implementation FrontFlashColorPickerViewController

- (void)colorDidChange:(UIColor *)color
{
	self.color = color;
}

- (UIColor *)savedCustomColor
{
	return savedCustomColor();
}

- (id)init
{
	if (self == [super init]) {
		UIColor *color = [[self savedCustomColor] retain];
		NKOColorPickerView *colorPickerView = [[[NKOColorPickerView alloc] initWithFrame:CGRectMake(0, 0, 300, 340) color:color delegate:self] autorelease];
		colorPickerView.backgroundColor = UIColor.blackColor;
		self.view = colorPickerView;
		self.navigationItem.title = @"Select Color";
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:0 target:self action:@selector(dismissPicker)] autorelease];
	}
	return self;
}

- (void)dismissPicker
{
	CGFloat hue, sat, bri;
    BOOL getColor = [self.color getHue:&hue saturation:&sat brightness:&bri alpha:nil];
    if (getColor) {
    	[preferences setFloat:hue forKey:HueKey];
		[preferences setFloat:sat forKey:SatKey];
		[preferences setFloat:bri forKey:BriKey];
		[preferences synchronize];
		[NSNotificationCenter.defaultCenter postNotificationName:updateCellColorNotification object:nil userInfo:nil];
	}
	[self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

@end

@implementation FrontFlashPreferenceController

+ (nullable NSString *)hb_specifierPlist
{
	return @"FrontFlash";
}

- (void)loadView
{
	[super loadView];
	UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 110)];
	UILabel *tweakLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 16, 320, 50)];
	tweakLabel.text = @"FrontFlash";
	tweakLabel.textColor = isiOS7Up ? UIColor.systemYellowColor : UIColor.yellowColor;
	tweakLabel.backgroundColor = UIColor.clearColor;
	tweakLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:50.0];
	tweakLabel.textAlignment = 1;
	tweakLabel.autoresizingMask = 0x12;
	[headerView addSubview:tweakLabel];
	[tweakLabel release];
	UILabel *des = [[UILabel alloc] initWithFrame:CGRectMake(0, 75, 320, 20)];
	des.text = @"Bright at night";
	des.alpha = 0.8;
	des.font = [UIFont systemFontOfSize:14.0];
	des.backgroundColor = UIColor.clearColor;
	des.textAlignment = 1;
	des.autoresizingMask = 0xa;
	[headerView addSubview:des];
	[des release];
	self.table.tableHeaderView = headerView;
	[headerView release];
}

- (id)init
{
	if (self == [super init]) {
		HBAppearanceSettings *appearanceSettings = [[HBAppearanceSettings alloc] init];
		if (isiOS7Up)
			appearanceSettings.tintColor = UIColor.systemYellowColor;
		appearanceSettings.tableViewBackgroundColor = UIColor.whiteColor;
		appearanceSettings.invertedNavigationBar = YES;
		self.hb_appearanceSettings = appearanceSettings;
		UIButton *heart = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
		UIImage *image = [UIImage imageNamed:@"Heart" inBundle:[NSBundle bundleWithPath:@"/Library/PreferenceBundles/FrontFlashSettings.bundle"]];
		if (isiOS7Up)
			image = [image _flatImageWithColor:UIColor.whiteColor];
		[heart setImage:image forState:UIControlStateNormal];
		[heart sizeToFit];
		[heart addTarget:self action:@selector(love) forControlEvents:UIControlEventTouchUpInside];
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:heart] autorelease];
		preferences = [[HBPreferences alloc] initWithIdentifier:tweakIdentifier];
		registerPref(preferences);
	}
	return self;
}

- (void)love
{
	SLComposeViewController *twitter = [[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter] retain];
	twitter.initialText = @"#FrontFlash by @PoomSmart is really awesome!";
	[self.navigationController presentViewController:twitter animated:YES completion:nil];
	[twitter release];
}

- (void)showColorPicker:(id)param
{
	FrontFlashColorPickerViewController *picker = [[[FrontFlashColorPickerViewController alloc] init] autorelease];
	UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:picker] autorelease];
	nav.modalPresentationStyle = 2;
	[self.navigationController presentViewController:nav animated:YES completion:nil];
}

@end

__attribute__((constructor)) static void ctor()
{
	if (isiOS56)
		dlopen("/Library/Application Support/FrontFlash/Workaround_Cephei_iOS56.dylib", RTLD_LAZY);
}