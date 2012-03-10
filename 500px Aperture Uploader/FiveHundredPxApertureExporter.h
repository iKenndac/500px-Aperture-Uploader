//
//  FiveHundredPxApertureExporter.h
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 17/02/2012.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>
#import "ApertureExportManager.h"
#import "ApertureExportPlugIn.h"
#import "FiveHundredPxOAuthEngine.h"
#import <Quartz/Quartz.h>
#import <Growl/Growl.h>
#import "DKBasicUpdateChecker.h"

#define DKLocalizedStringForClass(key) \
[[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:@"" table:@"Localizable"]

static NSString * const kAutoCheckForUpdatesUserDefaultsKey = @"CheckForUpdates";
static NSString * const kLastAutoCheckDateUserDefaultsKey = @"LastUpdateCheck";
static NSTimeInterval const kAutoCheckMinimumInterval = 60 * 60; // Only auto-check for updates once per hour.

static NSString * const k500pxURLMetadataKey = @"500px URL";
static NSString * const k500pxPhotoURLFormatter = @"http://500px.com/photo/%@";
static NSString * const k500pxProfileURLFormatter = @"http://500px.com/%@";

static NSUInteger const k500pxMinimumSizeForStore = 3600;

static void * const k500pxUpdateStoreSizeWarningKVOContext = @"BigPicturesAreAwesome";

static NSString * const kGrowlNotificationNameUploadComplete = @"upload";

@interface FiveHundredPxApertureExporter : NSViewController <ApertureExportPlugIn, FiveHundredPxEngineDelegate, GrowlApplicationBridgeDelegate>

@property (assign) IBOutlet NSView *firstView;
@property (assign) IBOutlet NSView *lastView;

@property (nonatomic, readwrite, strong) id <PROAPIAccessing> apiManager;
@property (nonatomic, readwrite, strong) NSObject <ApertureExportManager, PROAPIObject> *exportManager;
@property (nonatomic, readwrite, strong) NSLock *progressLock;
@property (nonatomic, readwrite, strong) FiveHundredPxOAuthEngine *engine;
@property (nonatomic, readwrite, strong) DKBasicUpdateChecker *updater;
@property (nonatomic, readwrite, strong) NSTimer *presetChangeCheckerTimer;

// --

@property (nonatomic, readonly, copy) NSString *loggedInUserName;
@property (readwrite, strong) NSArray *metadataContainers;
@property (readwrite, nonatomic) BOOL selectedImageIsBigEnoughForStore;

-(BOOL)imageAtIndexIsBigEnoughForStore:(NSUInteger)index;

// -- UI

- (IBAction)logInOut:(id)sender;
- (IBAction)cancelLogInSheet:(id)sender;
- (IBAction)confirmLogInSheet:(id)sender;
- (IBAction)showAboutSheet:(id)sender;
- (IBAction)closeAboutSheet:(id)sender;
- (IBAction)showPreferencesSheet:(id)sender;
- (IBAction)closePreferencesSheet:(id)sender;
- (IBAction)checkForUpdates:(id)sender;
- (IBAction)viewSelectedPhotoOn500px:(id)sender;

@property (weak) IBOutlet NSTextField *loginSheetUsernameField;
@property (weak) IBOutlet NSSecureTextField *loginSheetPasswordField;
@property (strong) IBOutlet NSWindow *loginSheet;
@property (weak) IBOutlet NSPopUpButton *categoriesMenu;
@property (strong) IBOutlet NSArrayController *metadataArrayController;
@property (weak) IBOutlet IKImageBrowserView *imageBrowser;
@property (strong) IBOutlet NSWindow *aboutWindow;
@property (weak) IBOutlet NSImageView *aboutIconImageView;
@property (unsafe_unretained) IBOutlet NSTextView *aboutCreditsView;
@property (weak) IBOutlet NSTextField *aboutVersionView;
@property (strong) IBOutlet NSWindow *preferencesWindow;


@property (nonatomic, readonly, strong) NSString *loginStatusText;
@property (nonatomic, readonly, strong) NSString *logInOutButtonTitle;
@property (nonatomic, readwrite, getter = isWorking) BOOL working;


@end
