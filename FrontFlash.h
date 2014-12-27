#import <UIKit/UIKit.h>
#import <GraphicsServices/GSEvent.h>
#import "../PS.h"

#define isiOS45 (isiOS4 || isiOS5)
#define isiOS56 (isiOS5 || isiOS6)
#define isiOS78 (isiOS7 || isiOS8)

@interface UIApplication (FrontFlash)
- (void)setBacklightLevel:(float)level;
@end

@interface CAMShutterButton : UIButton
@end

@interface CAMBottomBar : UIControl
- (CAMShutterButton *)shutterButton;
@end

@interface CAMFlashButton : UIControl
@property(assign, nonatomic) int flashMode;
@end

@interface CAMTriStateButton : UIControl
@property(assign, nonatomic) int flashMode;
@end

@interface CAMElapsedTimeView : UIView
@end

@interface CAMTopBar : UIView
@property(retain, nonatomic) CAMFlashButton *flashButton;
@property(retain, nonatomic) CAMElapsedTimeView *elapsedTimeView;
- (void)setBackgroundStyle:(int)style animated:(BOOL)animated;
- (void)setStyle:(int)style animated:(BOOL)animated;
@end

@interface PLCameraButton : UIButton
@end

@interface PLCameraButtonBar : UIToolbar
@property(retain, nonatomic) PLCameraButton *cameraButton;
@end

@interface PLCameraView
@property(assign, nonatomic) int cameraMode;
@property(assign, nonatomic) int cameraDevice;
@property(readonly, assign, nonatomic) CAMTopBar *_topBar;
@property(retain, nonatomic) UIToolbar *bottomButtonBar;
- (BOOL)_isStillImageMode:(int)cameraMode;
- (void)_updateTopBarStyleForDeviceOrientation:(int)orientation;
@end

@interface CAMCameraView
@property(assign, nonatomic) int cameraMode;
@property(assign, nonatomic) int cameraDevice;
@property(readonly, assign, nonatomic) CAMTopBar *_topBar;
- (BOOL)_isStillImageMode:(int)cameraMode;
- (void)_updateTopBarStyleForDeviceOrientation:(int)orientation;
@end

@interface PLCameraController : NSObject
@property(assign, nonatomic) int cameraDevice;
@property(readonly, assign, nonatomic) int cameraOrientation;
+ (PLCameraController *)sharedInstance;
- (PLCameraView *)delegate;
- (BOOL)isCapturingVideo;
- (BOOL)performingTimedCapture;
@end

@interface CAMCaptureController : NSObject
@property(assign, nonatomic) int cameraDevice;
@property(readonly, assign, nonatomic) int cameraOrientation;
+ (CAMCaptureController *)sharedInstance;
- (CAMCameraView *)delegate;
- (BOOL)isCapturingVideo;
- (BOOL)performingTimedCapture;
@end

@interface PLReorientingButton : UIButton
@end

@interface PLCameraFlashButton : PLReorientingButton
@property(assign, nonatomic) int flashMode;
@end

@interface PLCameraFlashButton (iOS5Up)
@property(assign, nonatomic, getter=isAutoHidden) BOOL autoHidden;
@end

@interface UIApplication (Addition)
- (BOOL)isSuspended;
@end

@interface SBScreenFlash : NSObject
+ (SBScreenFlash *)sharedInstance;
+ (SBScreenFlash *)mainScreenFlasher;
- (void)flashColor:(UIColor *)color;
- (void)flashColor:(UIColor *)color withCompletion:(id)completion;
@end

CFStringRef const PreferencesChangedNotification = CFSTR("com.PS.FrontFlash.prefs");
NSString *const PREF_PATH = @"/var/mobile/Library/Preferences/com.PS.FrontFlash.plist";
