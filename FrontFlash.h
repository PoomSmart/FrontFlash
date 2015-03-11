#import <UIKit/UIKit.h>
#import <GraphicsServices/GSEvent.h>
#import "../PS.h"

#define kDelayDuration 0.2f
#define kDimDuration 1

CFStringRef const PreferencesChangedNotification = CFSTR("com.PS.FrontFlash.prefs");
NSString *const PREF_PATH = @"/var/mobile/Library/Preferences/com.PS.FrontFlash.plist";
