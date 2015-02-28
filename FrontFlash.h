#import <UIKit/UIKit.h>
#import <GraphicsServices/GSEvent.h>
#import "../PS.h"

@interface SBScreenFlash : NSObject
+ (SBScreenFlash *)sharedInstance;
+ (SBScreenFlash *)mainScreenFlasher;
- (void)flashColor:(UIColor *)color;
- (void)flashColor:(UIColor *)color withCompletion:(id)completion;
@end

#define kDelayDuration 0.25f
#define kDimDuration 1

CFStringRef const PreferencesChangedNotification = CFSTR("com.PS.FrontFlash.prefs");
NSString *const PREF_PATH = @"/var/mobile/Library/Preferences/com.PS.FrontFlash.plist";
