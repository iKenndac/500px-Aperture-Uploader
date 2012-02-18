//
//  FiveHundredPxApertureExporter.h
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 17/02/2012.
//  Copyright (c) 2012 Daniel Kennett. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ApertureExportManager.h"
#import "ApertureExportPlugIn.h"
#import "FiveHundredPxOAuthEngine.h"
#import <Quartz/Quartz.h>

@interface FiveHundredPxApertureExporter : NSViewController <ApertureExportPlugIn, FiveHundredPxEngineDelegate>

@property (assign) IBOutlet NSView *firstView;
@property (assign) IBOutlet NSView *lastView;

@property (nonatomic, readwrite, strong) id <PROAPIAccessing> apiManager;
@property (nonatomic, readwrite, strong) NSObject <ApertureExportManager, PROAPIObject> *exportManager;
@property (nonatomic, readwrite, strong) NSLock *progressLock;
@property (nonatomic, readwrite, strong) FiveHundredPxOAuthEngine *engine;

// --

@property (nonatomic, readonly, copy) NSString *loggedInUserName;
@property (readwrite, strong) NSArray *metadataContainers;

// -- UI

- (IBAction)logInOut:(id)sender;
- (IBAction)cancelLogInSheet:(id)sender;
- (IBAction)confirmLogInSheet:(id)sender;
- (IBAction)visitWebsite:(id)sender;

@property (weak) IBOutlet NSTextField *loginSheetUsernameField;
@property (weak) IBOutlet NSSecureTextField *loginSheetPasswordField;
@property (strong) IBOutlet NSWindow *loginSheet;
@property (weak) IBOutlet NSPopUpButton *categoriesMenu;
@property (strong) IBOutlet NSArrayController *metadataArrayController;
@property (weak) IBOutlet IKImageBrowserView *imageBrowser;


@property (nonatomic, readonly, strong) NSString *loginStatusText;
@property (nonatomic, readonly, strong) NSString *logInOutButtonTitle;
@property (nonatomic, readwrite, getter = isWorking) BOOL working;


@end
