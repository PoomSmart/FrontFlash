#import "../PS.h"
#import <UIKit/UIKit.h>

#define kDelayDuration 0.2
#define kDimDuration 1

CFStringRef const PreferencesChangedNotification = CFSTR("com.PS.FrontFlash.prefs");
NSString *const PREF_PATH = @"/var/mobile/Library/Preferences/com.PS.FrontFlash.plist";