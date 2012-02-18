//
//  FiveHundredPxApertureExporter.m
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 17/02/2012.
//  Copyright (c) 2012 Daniel Kennett. All rights reserved.
//

#import "FiveHundredPxApertureExporter.h"

@implementation FiveHundredPxApertureExporter {
	ApertureExportProgress exportProgress;
}
@synthesize loginSheetUsernameField;
@synthesize loginSheetPasswordField;
@synthesize loginSheet;


//---------------------------------------------------------
// initWithAPIManager:
//
// This method is called when a plug-in is first loaded, and
// is a good point to conduct any checks for anti-piracy or
// system compatibility. This is also your only chance to
// obtain a reference to Aperture's export manager. If you
// do not obtain a valid reference, you should return nil.
// Returning nil means that a plug-in chooses not to be accessible.
//---------------------------------------------------------

-(id)initWithAPIManager:(id <PROAPIAccessing>)anApiManager {
	
    if ((self = [super initWithNibName:@"TimeLapseApertureExporter" bundle:[NSBundle bundleForClass:[self class]]])) {
		self.apiManager	= anApiManager;
		self.exportManager = [self.apiManager apiForProtocol:@protocol(ApertureExportManager)];
        
		if (self.exportManager == nil)
			return nil;
		
		self.progressLock = [[NSLock alloc] init];
		
		memset(&exportProgress, 0, sizeof(exportProgress));
        
		self.engine = [[FiveHundredPxOAuthEngine alloc] initWithDelegate:self];
	}
	
	return self;
}

-(void)awakeFromNib {
    @synchronized(self.exportManager) {
        //[[self.movieNameField cell] setPlaceholderString:[[self.exportManager propertiesWithoutThumbnailForImageAtIndex:0] valueForKey:kExportKeyProjectName]];
    }
}

@synthesize firstView;
@synthesize lastView;
@synthesize apiManager;
@synthesize exportManager;
@synthesize progressLock;
@synthesize engine;
@synthesize loggedInUserName;

@synthesize working;
@synthesize logInOutButtonTitle;
@synthesize loginStatusText;

#pragma mark -
#pragma mark 500px Interaction

-(void)verifyLoginDetails {
	
	self.loginStatusText = @"Logging in…";
	self.working = YES;
	
	[self.engine getDetailsForLoggedInUser:^(NSDictionary *returnValue, NSError *error) {
		
		self.working = NO;
		
		if (error != nil) {
			self.loginStatusText = @"Not logged in.";
			self.logInOutButtonTitle = @"Log In…";
			[self presentError:error];
		} else {
			self.logInOutButtonTitle = @"Log Out";
			self.loginStatusText = [NSString stringWithFormat:@"Logged in as %@.",
									[[returnValue valueForKey:@"user"] valueForKey:@"username"]];
		}
		
	}];
}

#pragma mark -
// UI Methods
#pragma mark UI Methods

-(NSView *)settingsView {
	return self.view;
}

-(void)willBeActivated {
	
	if (self.engine.isAuthenticated)
		self.loggedInUserName = self.engine.screenName;
	else
		[self.engine authenticateWithCompletionBlock:^(NSError *error) {}];
}

-(void)willBeDeactivated {
	// Nothing needed here
}

#pragma mark
// Aperture UI Controls
#pragma mark Aperture UI Controls

-(BOOL)allowsOnlyPlugInPresets {
	return NO;	
}

-(BOOL)allowsMasterExport {
	return NO;	
}

-(BOOL)allowsVersionExport {
	return YES;	
}

-(BOOL)wantsFileNamingControls {
	return NO;	
}

-(void)exportManagerExportTypeDidChange {
	// No masters so it should never get this call.
}

#pragma mark -
// Save Path Methods
#pragma mark Save/Path Methods

-(BOOL)wantsDestinationPathPrompt {
	return NO;
}

-(NSString *)destinationPath {
	return nil;
}

-(NSString *)defaultDirectory {
	return nil;
}

#pragma mark -
// Export Process Methods
#pragma mark Export Process Methods

-(void)exportManagerShouldBeginExport {
	// Resizer doesn't need to perform any initialization here.
	// As an improvement, it could check to make sure the user entered at least one size
    @synchronized(exportManager) {
        [self.exportManager shouldBeginExport];
    }
}

-(void)exportManagerWillBeginExportToPath:(NSString *)path {
	
	// Update the progress structure to say Beginning Export... with an indeterminate progress bar.
	[self lockProgress];
	exportProgress.totalValue = [self.exportManager imageCount];
	exportProgress.indeterminateProgress = YES;
	exportProgress.message = (__bridge void *)NSLocalizedStringFromTableInBundle(@"beginning export", @"Localizable", [NSBundle bundleForClass:[self class]], @"Beginning Export...");
	[self unlockProgress];
}

-(BOOL)exportManagerShouldExportImageAtIndex:(unsigned)index {
	// Resizer always exports all of the selected images.
	return YES;
}

-(void)exportManagerWillExportImageAtIndex:(unsigned)index {
	// Nothing to confirm here.
}

-(BOOL)exportManagerShouldWriteImageData:(NSData *)imageData toRelativePath:(NSString *)path forImageAtIndex:(unsigned)index {
    // Update the progress
	[self lockProgress];
	exportProgress.message = (__bridge void *)NSLocalizedStringFromTableInBundle(@"exporting", @"Localizable", [NSBundle bundleForClass:[self class]], @"Exporting...");
	exportProgress.currentValue = index + 1;
	[self unlockProgress];
	
	// Do something with image...
    
	// Tell Aperture to write the file out if needed.
	BOOL shouldAlsoWriteImageFileSomewhere = NO;
	return shouldAlsoWriteImageFileSomewhere;
}

-(void)exportManagerDidWriteImageDataToRelativePath:(NSString *)relativePath forImageAtIndex:(unsigned)index {
	
}

-(void)exportManagerDidFinishExport {
    
    @synchronized(exportManager) {
        [self.exportManager shouldFinishExport];
    }
}

-(void)exportManagerShouldCancelExport {
    
    @synchronized(exportManager) {
        [self.exportManager shouldCancelExport];
    }
}

#pragma mark -
// Progress Methods
#pragma mark Progress Methods

-(ApertureExportProgress *)progress {
	return &exportProgress;
}

-(void)lockProgress {
	[self.progressLock lock];
}

-(void)unlockProgress {
	[self.progressLock unlock];
}

#pragma mark -
#pragma mark OAuth Delegtes

- (void)fiveHundredPxNeedsAuthentication:(FiveHundredPxOAuthEngine *)engine {
	
}

- (void)fiveHundredPx:(FiveHundredPxOAuthEngine *)engine statusUpdate:(NSString *)message {
	DLog(@"%@", message);
}


- (IBAction)logInOut:(id)sender {
}

- (IBAction)cancelLogInSheet:(id)sender {
}

- (IBAction)confirmLogInSheet:(id)sender {
}
@end
