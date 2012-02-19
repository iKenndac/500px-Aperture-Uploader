//
//  FiveHundredPxApertureExporter.m
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 17/02/2012.
//  For license information, see LICENSE.markdown
//

#import "FiveHundredPxApertureExporter.h"
#import "FiveHundredPxExtraMetadata.h"

@implementation FiveHundredPxApertureExporter {
	ApertureExportProgress exportProgress;
}

@synthesize loginSheetUsernameField;
@synthesize loginSheetPasswordField;
@synthesize loginSheet;
@synthesize categoriesMenu;
@synthesize metadataArrayController;
@synthesize imageBrowser;

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

extern NSString *k500pxConsumerKey;
extern NSString *k500pxConsumerSecret;

-(id)initWithAPIManager:(id <PROAPIAccessing>)anApiManager {
	
	#import "../OAuthKeys.c"
	k500pxConsumerKey = [NSString stringWithUTF8String:IveGotTheKey];
	k500pxConsumerSecret = [NSString stringWithUTF8String:IveGotTheSecret];
	
    if ((self = [super initWithNibName:@"FiveHundredPxApertureExporter" bundle:[NSBundle bundleForClass:[self class]]])) {
		
		self.apiManager	= anApiManager;
		self.exportManager = [self.apiManager apiForProtocol:@protocol(ApertureExportManager)];
        
		if (self.exportManager == nil)
			return nil;
		
		self.progressLock = [[NSLock alloc] init];
		self.engine = [[FiveHundredPxOAuthEngine alloc] initWithDelegate:self];
		
		memset(&exportProgress, 0, sizeof(exportProgress));
	}
	
	return self;
}

-(void)awakeFromNib {
    @synchronized(self.exportManager) {
        //[[self.movieNameField cell] setPlaceholderString:[[self.exportManager propertiesWithoutThumbnailForImageAtIndex:0] valueForKey:kExportKeyProjectName]];
    }
	
	NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Categories"
																	  ofType:@"plist"];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:path])
		return;
	
	NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfFile:path]
																	options:0
																	 format:NULL
																	  error:nil];
	
	for (NSDictionary *category in [plist valueForKey:@"Categories"]) {
		
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[category valueForKey:@"name"]
													  action:nil
											   keyEquivalent:@""];
		[item setTag:[[category valueForKey:@"id"] integerValue]];
		[[categoriesMenu menu] addItem:item];
	}
}

@synthesize firstView;
@synthesize lastView;
@synthesize apiManager;
@synthesize exportManager;
@synthesize progressLock;
@synthesize engine;
@synthesize metadataContainers;

@synthesize working;

+(NSSet *)keyPathsForValuesAffectingLoginStatusText {
	return [NSSet setWithObjects:@"working", @"engine.isAuthenticated", nil];
}

-(NSString *)loginStatusText {
	
	if (self.isWorking) {
		return @"Authorizing…";
	} else {
		return self.engine.isAuthenticated ? [NSString stringWithFormat:@"Logged in as %@.", self.loggedInUserName] : @"Not Logged In.";
	}
}

+(NSSet *)keyPathsForValuesAffectingLoggedInUserName {
	return [NSSet setWithObject:@"engine.screenName"];
}

-(NSString *)loggedInUserName {
	return self.engine.screenName;
}

+(NSSet *)keyPathsForValuesAffectingLogInOutButtonTitle {
	return [NSSet setWithObject:@"engine.isAuthenticated"];
}

-(NSString *)logInOutButtonTitle {
	return self.engine.isAuthenticated ? @"Log Out" : @"Log In…";
}

#pragma mark -
#pragma mark 500px Interaction

-(void)verifyLoginDetails {
	
	self.working = YES;
	
	[self.engine getDetailsForLoggedInUser:^(NSDictionary *returnValue, NSError *error) {
		
		self.working = NO;
		
		if (error != nil) {
			[self presentError:error];
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
		[self verifyLoginDetails];
	
	NSMutableArray *newContainers = [NSMutableArray arrayWithCapacity:[self.exportManager imageCount]];
	for (unsigned int i = 0; i < [self.exportManager imageCount]; i++) {
		[newContainers addObject:[[FiveHundredPxExtraMetadata alloc] initWithImageProperties:[self.exportManager propertiesForImageAtIndex:i]]];
	}
	
	self.metadataContainers = [NSArray arrayWithArray:newContainers];
	[self.imageBrowser reloadData];
	[self.imageBrowser setSelectionIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[self.metadataArrayController setSelectionIndex:0];
}

-(void)willBeDeactivated {
	// Nothing needed here
}

#pragma mark -
#pragma mark Image Browser

-(NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser {
	return [self.metadataArrayController.arrangedObjects count];
}

-(id)imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)index {
	return [self.metadataArrayController.arrangedObjects objectAtIndex:index];
}

-(void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser {
	self.metadataArrayController.selectionIndexes = aBrowser.selectionIndexes;
}

#pragma mark -
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
		
		if ([[self.exportManager.selectedExportPresetDictionary valueForKey:@"ImageFormat"] integerValue] != 0) {
			
			[[NSAlert alertWithMessageText:@"Unsupported image format in selected Version Preset"
							 defaultButton:@"OK"
						   alternateButton:@""
							   otherButton:@""
				 informativeTextWithFormat:@"500px.com only supports uploading JPEG images."] runModal];
			
			return;
		}
		
		if (!self.engine.isAuthenticated) {
			
			[[NSAlert alertWithMessageText:@"Not logged in!"
							 defaultButton:@"OK"
						   alternateButton:@""
							   otherButton:@""
				 informativeTextWithFormat:@"Please log in to 500px using the Log In button at the top of this window."] runModal];
			
			return;
		}
		
		
		
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
	
	__block BOOL isRunning = YES;
	NSDictionary *metadata = [[self.metadataContainers objectAtIndex:index] dictionaryValue];
	
	// Do something with image...
	[self.engine uploadPhoto:imageData
				withMetaData:metadata 
		 uploadProgressBlock:^(double progress) { DLog(@"%1.2f", progress); } 
			 completionBlock:^(NSDictionary *returnValue, NSError *error) {
				 if (error != nil) {
					 DLog(@"%@", error);
				 }
				 
				 isRunning = NO;
			 }
	 ];
	
	while (isRunning)
		[NSThread sleepForTimeInterval:0.1];
	
	DLog(@"Done!");
    
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

- (void)fiveHundredPxNeedsAuthentication:(FiveHundredPxOAuthEngine *)eng {
	[eng authenticateWithUsername:self.loginSheetUsernameField.stringValue
						 password:self.loginSheetPasswordField.stringValue];
}

- (void)fiveHundredPx:(FiveHundredPxOAuthEngine *)engine statusUpdate:(NSString *)message {
	DLog(@"%@", message);
}


- (IBAction)logInOut:(id)sender {
	
	if (self.engine.isAuthenticated) {
		[self.engine forgetStoredToken];
	} else {
		[NSApp beginSheet:self.loginSheet
		   modalForWindow:self.view.window
			modalDelegate:nil
		   didEndSelector:nil
			  contextInfo:nil];
	}
	
}

- (IBAction)cancelLogInSheet:(id)sender {
	[NSApp endSheet:self.loginSheet];
	[self.loginSheet close];
}

- (IBAction)confirmLogInSheet:(id)sender {
	
	if (self.loginSheetPasswordField.stringValue.length == 0) {
		NSBeep();
		[self.loginSheetPasswordField becomeFirstResponder];
		return;
	}
	
	if (self.loginSheetUsernameField.stringValue.length == 0) {
		NSBeep();
		[self.loginSheetUsernameField becomeFirstResponder];
		return;
	}
	
	[self cancelLogInSheet:sender];
	self.working = YES;
	
	[self.engine authenticateWithCompletionBlock:^(NSError *error) {
		if (error != nil)
			[self presentError:error];
		self.working = NO;
	}];
}

- (IBAction)visitWebsite:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/iKenndac/500px-Aperture-Uploader"]];
}

@end
