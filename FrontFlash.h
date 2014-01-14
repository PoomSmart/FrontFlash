#import <UIKit/UIKit.h>

@interface UIApplication (FrontFlash)
- (void)setBacklightLevel:(float)level;
@end

// iOS 5+
@interface PLCameraController : NSObject
@property(assign, nonatomic) int cameraDevice;
+ (id)sharedInstance;
- (BOOL)isCapturingVideo;
@end
#define controller [objc_getClass("PLCameraController") sharedInstance]
#define isCapturingVideo [controller isCapturingVideo]

@interface PLCameraView
@property(assign, nonatomic) int cameraMode;
@property(assign, nonatomic) int cameraDevice;
@end

// iOS 5, 6
@interface PLReorientingButton : UIButton
@end

@interface PLCameraFlashButton : PLReorientingButton
@property(assign, nonatomic) int flashMode;
@end

@interface PLCameraFlashButton (iOS5Up)
@property(assign, nonatomic, getter=isAutoHidden) BOOL autoHidden;
@end

// iOS 7+
@interface CAMFlashButton : UIControl
@property(assign, nonatomic) int flashMode;
@end

@interface CAMTriStateButton : UIControl
@property(assign, nonatomic) int flashMode;
@end

@interface CAMElapsedTimeView : UIView
@end

@interface CAMTopBar
@property(retain, nonatomic) CAMFlashButton* flashButton;
@property(retain, nonatomic) CAMElapsedTimeView* elapsedTimeView;
- (void)setStyle:(int)style animated:(BOOL)animated;
@end

@interface PLCameraView (iOS7)
@property(readonly, assign, nonatomic) CAMTopBar* _topBar;
@end

@interface UIView (PhotoLibraryAdditions)
- (void)pl_setHidden:(BOOL)hidden animated:(BOOL)animated;
@end

#define PreferencesChangedNotification "com.PS.FrontFlash.prefs"
#define PREF_PATH @"/var/mobile/Library/Preferences/com.PS.FrontFlash.plist"
#define isiOS4 (kCFCoreFoundationVersionNumber >= 550.32 && kCFCoreFoundationVersionNumber < 675.00)
#define isiOS5 (kCFCoreFoundationVersionNumber >= 675.00 && kCFCoreFoundationVersionNumber < 793.00)
#define isiOS6 (kCFCoreFoundationVersionNumber == 793.00)
#define isiOS7 (kCFCoreFoundationVersionNumber >= 847.20)
#define isiOS70 (isiOS7 && kCFCoreFoundationVersionNumber < 847.23)
#define isiOS71 (kCFCoreFoundationVersionNumber >= 847.23)

#define declareFlashBtn() \
	id flashBtn; \
	if (isiOS7) \
		flashBtn = MSHookIvar<CAMFlashButton *>(self, "__flashButton"); \
	else \
		flashBtn = MSHookIvar<PLCameraFlashButton *>(self, "_flashButton");
	
#define kDelayDuration 0.22
#define kFadeDuration 0.5

static BOOL FrontFlashOnInPhoto = YES;
static BOOL FrontFlashOnInVideo = YES;
#define FrontFlashOn (FrontFlashOnInPhoto || FrontFlashOnInVideo)
#define FrontFlashOnRecursively ((FrontFlashOnInPhoto && (self.cameraMode == 0 || self.cameraMode == 4)) || (FrontFlashOnInVideo && self.cameraMode == 1))
static BOOL isFrontCamera;
static BOOL frontFlashActive;
static BOOL onFlash = NO;
static BOOL reallyHasFlash;

static float previousBacklightLevel;
static float alpha = 1.0f;
static float red = 1.0f;
static float green = 1.0f;
static float blue = 1.0f;

static int colorProfile = 1;

static UIView *flashView = nil;

static void FFLoader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	FrontFlashOnInPhoto = [dict objectForKey:@"FrontFlashOnInPhoto"] ? [[dict objectForKey:@"FrontFlashOnInPhoto"] boolValue] : YES;
	FrontFlashOnInVideo = [dict objectForKey:@"FrontFlashOnInVideo"] ? [[dict objectForKey:@"FrontFlashOnInVideo"] boolValue] : YES;
	red = [dict objectForKey:@"R"] ? [[dict objectForKey:@"R"] floatValue] : 1.0f;
	green = [dict objectForKey:@"G"] ? [[dict objectForKey:@"G"] floatValue] : 1.0f;
	blue = [dict objectForKey:@"B"] ? [[dict objectForKey:@"B"] floatValue] : 1.0f;
	alpha = [dict objectForKey:@"Alpha"] ? [[dict objectForKey:@"Alpha"] floatValue] : 1.0f;
	colorProfile = [dict objectForKey:@"colorProfile"] ? [[dict objectForKey:@"colorProfile"] intValue] : 1;
}
