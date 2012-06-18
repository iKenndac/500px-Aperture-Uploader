//
//  FiveHundredPxViewController.h
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 10/03/2012.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "FiveHundredPxOAuthEngine.h"
#import "FiveHundredPxApertureExporter.h"

@class FiveHundredPxApertureExporter;

@interface FiveHundredPxViewController : NSViewController

-(id)initWithOAuthEngine:(FiveHundredPxOAuthEngine *)oAuthEngine;

- (IBAction)logInOut:(id)sender;
- (IBAction)cancelLogInSheet:(id)sender;
- (IBAction)confirmLogInSheet:(id)sender;
- (IBAction)showAboutSheet:(id)sender;
- (IBAction)closeAboutSheet:(id)sender;
- (IBAction)showPreferencesSheet:(id)sender;
- (IBAction)closePreferencesSheet:(id)sender;
- (IBAction)checkForUpdates:(id)sender;
- (IBAction)viewSelectedPhotoOn500px:(id)sender;
- (IBAction)logCurrentExportPreset:(id)sender;
- (IBAction)logCurrentImageProperties:(id)sender;
- (IBAction)openLogsDirectory:(id)sender;

-(BOOL)imageAtIndexIsBigEnoughForStore:(NSUInteger)index;

-(void)presentLoginFailedError:(NSError *)error;

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
@property (weak) IBOutlet NSButton *logImagePropertiesButton;
@property (weak) IBOutlet NSButton *logCurrentPresetButton;
@property (weak) IBOutlet NSTokenField *tagField;

@property (nonatomic, readwrite, strong) FiveHundredPxOAuthEngine *engine;
@property (nonatomic, readwrite, weak) FiveHundredPxApertureExporter *exporter;

@property (assign) IBOutlet NSView *firstView;
@property (assign) IBOutlet NSView *lastView;

@property (readwrite, nonatomic) BOOL selectedImageIsBigEnoughForStore;

@property (nonatomic, readonly, strong) NSString *loginStatusText;
@property (nonatomic, readonly, strong) NSString *logInOutButtonTitle;

@end
