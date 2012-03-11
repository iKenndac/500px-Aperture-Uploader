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
#import <Growl/Growl.h>
#import "DKBasicUpdateChecker.h"
#import "FiveHundredPxViewController.h"
#import "FiveHundredPxExportLogger.h"

@class FiveHundredPxViewController;

@interface FiveHundredPxApertureExporter : NSObject <ApertureExportPlugIn, FiveHundredPxEngineDelegate, GrowlApplicationBridgeDelegate>

@property (nonatomic, readwrite, strong) id <PROAPIAccessing> apiManager;
@property (nonatomic, readwrite, strong) NSObject <ApertureExportManager, PROAPIObject> *exportManager;
@property (nonatomic, readwrite, strong) NSLock *progressLock;
@property (nonatomic, readwrite, strong) FiveHundredPxOAuthEngine *engine;
@property (nonatomic, readwrite, strong) DKBasicUpdateChecker *updater;
@property (nonatomic, readwrite, strong) FiveHundredPxViewController *viewController;
@property (nonatomic, readwrite, strong) FiveHundredPxExportLogger *logger;

@property (nonatomic, readwrite) BOOL hadErrorsDuringExport;
@property (nonatomic, readwrite) BOOL hadSuccessesDuringExport;

// --

@property (readwrite, strong) NSArray *metadataContainers;

@end
