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

@interface FiveHundredPxApertureExporter : NSViewController <ApertureExportPlugIn, FiveHundredPxEngineDelegate>

@property (assign) IBOutlet NSView *firstView;
@property (assign) IBOutlet NSView *lastView;

@property (nonatomic, readwrite, strong) id <PROAPIAccessing> apiManager;
@property (nonatomic, readwrite, strong) NSObject <ApertureExportManager, PROAPIObject> *exportManager;

@property (nonatomic, readwrite, strong) NSLock *progressLock;

@property (nonatomic, readwrite, strong) FiveHundredPxOAuthEngine *engine;

// --

@property (nonatomic, readwrite, copy) NSString *loggedInUserName;

// -- UI
- (IBAction)logInOut:(id)sender;
- (IBAction)cancelLogInSheet:(id)sender;
- (IBAction)confirmLogInSheet:(id)sender;

@property (weak) IBOutlet NSTextField *loginSheetUsernameField;
@property (weak) IBOutlet NSSecureTextField *loginSheetPasswordField;
@property (strong) IBOutlet NSWindow *loginSheet;

@property (nonatomic, readwrite, strong) NSString *loginStatusText;
@property (nonatomic, readwrite, strong) NSString *logInOutButtonTitle;
@property (nonatomic, readwrite, getter = isWorking) BOOL working;


@end
