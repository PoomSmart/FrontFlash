#define UIFUNCTIONS_NOT_C
#import <UIKit/UIKit.h>
#import <UIKit/UIColor+Private.h>
#import <Cephei/HBListController.h>
#import <Cephei/HBAppearanceSettings.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>
#import <Social/Social.h>
#import "NKOColorPickerView.h"
#import "Tweak.h"
#import <dlfcn.h>
#import "../PSPrefs.x"

DeclarePrefsTools()

@interface FrontFlashPreferenceController : HBListController
@end

@interface FrontFlashColorPickerViewController : UIViewController <NKOColorPickerViewDelegate>
@property (retain) UIColor *color;
+ (UIColor *)savedCustomColor;
@end

NSString *updateCellColorNotification = @"com.PS.FrontFlash.prefs.colorUpdate";
NSString *IdentifierKey = @"FrontFlashColorCellIdentifier";

@interface FrontFlashColorCell : PSTableCell
@end

@implementation FrontFlashColorCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(PSSpecifier *)specifier {
    if (self == [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier]) {
        [self updateColorCell];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateColorCell:) name:updateCellColorNotification object:nil];
    }
    return self;
}

- (UIColor *)savedCustomColor {
    return [FrontFlashColorPickerViewController savedCustomColor];
}

- (UIView *)colorCell {
    UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 28.0, 28.0)];
    circle.layer.cornerRadius = 14.0;
    circle.backgroundColor = [self savedCustomColor];
    return [circle autorelease];
}

- (void)updateColorCell:(NSNotification *)notification {
    [self updateColorCell];
}

- (void)updateColorCell {
    self.accessoryView = [[self colorCell] retain];
    self.titleLabel.textColor = self.accessoryView.backgroundColor;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [super dealloc];
}

@end

@implementation FrontFlashColorPickerViewController

- (void)colorDidChange:(UIColor *)color {
    self.color = color;
}

+ (UIColor *)savedCustomColor {
    return [UIColor colorWithHue:cgfloatForKey(HueKey, 1.0) saturation:cgfloatForKey(SatKey, 1.0) brightness:cgfloatForKey(BriKey, 1.0) alpha:1.0];
}

- (id)init {
    if (self == [super init]) {
        UIColor *color = [[[self class] savedCustomColor] retain];
        NKOColorPickerView *colorPickerView = [[[NKOColorPickerView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 340.0) color:color delegate:self] autorelease];
        colorPickerView.backgroundColor = UIColor.blackColor;
        self.view = colorPickerView;
        self.navigationItem.title = @"Select Color";
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:0 target:self action:@selector(dismissPicker)] autorelease];
    }
    return self;
}

- (void)dismissPicker {
    CGFloat hue, sat, bri;
    if ([self.color getHue:&hue saturation:&sat brightness:&bri alpha:nil]) {
        setFloatForKey(hue, HueKey);
        setFloatForKey(sat, SatKey);
        setFloatForKey(bri, BriKey);
        DoPostNotification();
        [NSNotificationCenter.defaultCenter postNotificationName:updateCellColorNotification object:nil userInfo:nil];
    }
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

@end

@implementation FrontFlashPreferenceController

+ (NSString *)hb_specifierPlist {
    return @"FrontFlash";
}

HavePrefs()

HaveBanner2(@"FrontFlash", isiOS7Up ? UIColor.systemYellowColor : UIColor.yellowColor, @"Bright at night", UIColor.grayColor)

- (id)init {
    if (self == [super init]) {
        if (isiOS6Up) {
            HBAppearanceSettings *appearanceSettings = [[HBAppearanceSettings alloc] init];
            if (isiOS7Up)
                appearanceSettings.tintColor = UIColor.systemYellowColor;
            appearanceSettings.tableViewBackgroundColor = UIColor.whiteColor;
            appearanceSettings.invertedNavigationBar = YES;
            self.hb_appearanceSettings = appearanceSettings;
            self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"💛" style:UIBarButtonItemStylePlain target:self action:@selector(love)] autorelease];
        }
    }
    return self;
}

- (void)love {
    SLComposeViewController *twitter = [[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter] retain];
    if (twitter) {
        twitter.initialText = @"#FrontFlash by @PoomSmart is really awesome!";
        [self.navigationController presentViewController:twitter animated:YES completion:nil];
        [twitter release];
    }
}

- (void)showColorPicker:(id)param {
    FrontFlashColorPickerViewController *picker = [[[FrontFlashColorPickerViewController alloc] init] autorelease];
    UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:picker] autorelease];
    nav.modalPresentationStyle = 2;
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

@end
