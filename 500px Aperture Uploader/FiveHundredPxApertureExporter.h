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

@interface FiveHundredPxApertureExporter : NSViewController <ApertureExportPlugIn>

@property (assign) IBOutlet NSView *firstView;
@property (assign) IBOutlet NSView *lastView;

@property (nonatomic, readwrite, strong) id <PROAPIAccessing> apiManager;
@property (nonatomic, readwrite, strong) NSObject <ApertureExportManager, PROAPIObject> *exportManager;

@property (nonatomic, readwrite, strong) NSLock *progressLock;


@end
