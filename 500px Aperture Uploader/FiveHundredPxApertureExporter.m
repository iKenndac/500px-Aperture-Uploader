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
@synthesize aboutWindow;
@synthesize aboutIconImageView;
@synthesize aboutCreditsView;
@synthesize aboutVersionView;
@synthesize preferencesWindow;
@synthesize firstView;
@synthesize lastView;
@synthesize apiManager;
@synthesize exportManager;
@synthesize progressLock;
@synthesize engine;
@synthesize metadataContainers;
@synthesize updater;

@synthesize working;

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
    [GrowlApplicationBridge setGrowlDelegate:self];
	
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
		self.updater = [[DKBasicUpdateChecker alloc] init];
		
		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
																 [NSNumber numberWithBool:YES], kAutoCheckForUpdatesUserDefaultsKey,
																 nil]];
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey:kAutoCheckForUpdatesUserDefaultsKey]) {
			NSDate *lastCheckDate = [[NSUserDefaults standardUserDefaults] valueForKey:kLastAutoCheckDateUserDefaultsKey];
			
			if (lastCheckDate == nil || [[NSDate date] timeIntervalSinceDate:lastCheckDate] > kAutoCheckMinimumInterval) {
				[self.updater checkForUpdates:NO];
				[[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:kLastAutoCheckDateUserDefaultsKey];
			}
		}
			
		memset(&exportProgress, 0, sizeof(exportProgress));
		
		[self addObserver:self
			   forKeyPath:@"metadataArrayController.selection"
				  options:NSKeyValueObservingOptionInitial
				  context:k500pxUpdateStoreSizeWarningKVOContext];
		
		[self addObserver:self
			   forKeyPath:@"exportManager.selectedExportPresetDictionary"
				  options:NSKeyValueObservingOptionInitial
				  context:k500pxUpdateStoreSizeWarningKVOContext];
		
		// ^ The above property isn't KVO-compliant, so we poll it. UGH.
		self.presetChangeCheckerTimer = [NSTimer timerWithTimeInterval:0.5
																target:self
															  selector:@selector(pollVersionPreset:)
															  userInfo:nil
															   repeats:YES];
		[[NSRunLoop currentRunLoop] addTimer:self.presetChangeCheckerTimer
									 forMode:NSRunLoopCommonModes];
	}
	
	return self;
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"metadataArrayController.selection"];
	[self removeObserver:self forKeyPath:@"exportManager.selectedExportPresetDictionary"];
	[self.presetChangeCheckerTimer invalidate];
}

-(void)awakeFromNib {

	NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
	
	[self.aboutCreditsView setEditable:NO];
	[self.aboutCreditsView readRTFDFromFile:[myBundle pathForResource:@"Credits"
															   ofType:@"rtf"]];
	
	self.aboutVersionView.stringValue = [NSString stringWithFormat:DKLocalizedStringForClass(@"version formatter"),
										 [myBundle.infoDictionary valueForKey:@"CFBundleShortVersionString"],
										 [myBundle.infoDictionary valueForKey:@"CFBundleVersion"]];
	
	NSString *categoriesPath = [myBundle pathForResource:@"Categories"
												  ofType:@"plist"];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:categoriesPath])
		return;
	
	NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfFile:categoriesPath]
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == k500pxUpdateStoreSizeWarningKVOContext) {
		self.selectedImageIsBigEnoughForStore = [self imageAtIndexIsBigEnoughForStore:self.metadataArrayController.selectionIndex];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)pollVersionPreset:(NSTimer *)timer {
	self.selectedImageIsBigEnoughForStore = [self imageAtIndexIsBigEnoughForStore:self.metadataArrayController.selectionIndex];
}

+(NSSet *)keyPathsForValuesAffectingLoginStatusText {
	return [NSSet setWithObjects:@"working", @"engine.isAuthenticated", nil];
}

-(NSString *)loginStatusText {
	
	if (self.isWorking) {
		return DKLocalizedStringForClass(@"authenticating title");
	} else {
		return self.engine.isAuthenticated ?
		[NSString stringWithFormat:DKLocalizedStringForClass(@"logged in title"), self.loggedInUserName] 
		: DKLocalizedStringForClass(@"not logged in title");
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
	return self.engine.isAuthenticated ? DKLocalizedStringForClass(@"log out title") : DKLocalizedStringForClass(@"log in title");
}

-(BOOL)imageAtIndexIsBigEnoughForStore:(NSUInteger)index {
	
	NSDictionary *preset = self.exportManager.selectedExportPresetDictionary;
	NSDictionary *image = [self.exportManager propertiesWithoutThumbnailForImageAtIndex:index];
	
	NSSize nativeSize = [[image valueForKey:kExportKeyImageSize] sizeValue];
	NSInteger sizeMode = [[preset valueForKey:@"ExportSizeStyle"] integerValue];
	NSUInteger longestSideAfterPreset = 0;
	
	if (sizeMode == 0 /* Pixels */) {
		
		NSNumber *widthInPixels = [preset valueForKey:@"DestinationPixelWidth"];
		NSNumber *heightInPixels = [preset valueForKey:@"DestinationPixelHeight"];
		longestSideAfterPreset = MAX([widthInPixels unsignedIntegerValue], [heightInPixels unsignedIntegerValue]);
		
	} else if (sizeMode == 1 /* Percent */) {
		
		NSNumber *percent = [preset valueForKey:@"PercentToSizeBy"];
		double scaleFactor = [percent doubleValue] / 100.0;
		longestSideAfterPreset = MAX(nativeSize.width * scaleFactor, nativeSize.height * scaleFactor);

	} else if (sizeMode == 2 /* Original size */) {
	
		longestSideAfterPreset = MAX(nativeSize.width, nativeSize.height);
		
	} else if (sizeMode == 3 /* Fit in inches */) {
		
		double widthInIn = [[preset valueForKey:@"DestinationPhysicalWidth"] doubleValue];
		double heightInIn = [[preset valueForKey:@"DestinationPhysicalHeight"] doubleValue];
		double dpi = [[preset valueForKey:@"DestinationDPI"] doubleValue];
		longestSideAfterPreset = MAX(widthInIn * dpi, heightInIn * dpi);
		
	} else if (sizeMode == 4 /* Fit in cm */) {
		
		double widthInCm = [[preset valueForKey:@"DestinationPhysicalWidthInCentimeters"] doubleValue];
		double heightInCm = [[preset valueForKey:@"DestinationPhysicalHeightInCentimeters"] doubleValue];
		double dpcm = [[preset valueForKey:@"DestinationDPI"] doubleValue] / 2.54;
		longestSideAfterPreset = MAX(widthInCm * dpcm, heightInCm * dpcm);
	}
	
	return longestSideAfterPreset >= k500pxMinimumSizeForStore;
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
			
			[[NSAlert alertWithMessageText:DKLocalizedStringForClass(@"unsupported image format error title")
							 defaultButton:DKLocalizedStringForClass(@"ok title")
						   alternateButton:@""
							   otherButton:@""
				 informativeTextWithFormat:DKLocalizedStringForClass(@"unsupported image format error description")] runModal];
			
			return;
		}
		
		if (!self.engine.isAuthenticated) {
			
			[[NSAlert alertWithMessageText:DKLocalizedStringForClass(@"not logged in error title")
							 defaultButton:DKLocalizedStringForClass(@"ok title")
						   alternateButton:@""
							   otherButton:@""
				 informativeTextWithFormat:DKLocalizedStringForClass(@"not logged in error description")] runModal];
			
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
	exportProgress.message = (__bridge void *)DKLocalizedStringForClass(@"beginning export title");
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
	exportProgress.message = (__bridge void *)DKLocalizedStringForClass(@"exporting title");
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
				 } else {
					 // Write the id back to the image.
					 NSString *photoId = [[[returnValue valueForKey:@"photo"] valueForKey:@"id"] stringValue];
					 NSString *photoUrlString = [NSString stringWithFormat:k500pxPhotoURLFormatter, photoId];
					 if (photoId.length > 0) {
						 // Only write back if we got a valid id
						 @synchronized(exportManager) {
							 NSDictionary *metadata = [NSDictionary dictionaryWithObject:photoUrlString forKey:k500pxURLMetadataKey];
							 [self.exportManager addCustomMetadataKeyValues:metadata
															 toImageAtIndex:index];
							 DLog(@"Setting 500px URL in metadata: %@", photoUrlString);
						 }
					 }
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
        
        
        
        [GrowlApplicationBridge notifyWithTitle:DKLocalizedStringForClass(@"growl upload complete title")
                                    description:DKLocalizedStringForClass(@"growl upload complete description")
                               notificationName:kGrowlNotificationNameUploadComplete 
                                       iconData:nil
                                       priority:0 
                                       isSticky:NO 
                                   clickContext:[NSString stringWithFormat:k500pxProfileURLFormatter, self.engine.screenName]];
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

- (IBAction)showAboutSheet:(id)sender {
	[NSApp beginSheet:self.aboutWindow
	   modalForWindow:self.view.window
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
}

- (IBAction)closeAboutSheet:(id)sender {
	[NSApp endSheet:self.aboutWindow];
	[self.aboutWindow close];
}

- (IBAction)showPreferencesSheet:(id)sender {
	[NSApp beginSheet:self.preferencesWindow
	   modalForWindow:self.view.window
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
}

- (IBAction)closePreferencesSheet:(id)sender {
	[NSApp endSheet:self.preferencesWindow];
	[self.preferencesWindow close];
}

- (IBAction)checkForUpdates:(id)sender {
	[self.updater checkForUpdates:YES];
}

- (IBAction)viewSelectedPhotoOn500px:(id)sender {
	
	FiveHundredPxExtraMetadata *metadata = [self.metadataContainers objectAtIndex:self.metadataArrayController.selectionIndex];
	if (metadata.existing500pxURL != nil)
		[[NSWorkspace sharedWorkspace] openURL:metadata.existing500pxURL];
	else
		NSBeep();
}

#pragma mark - GrowlApplicationBridgeDelegate Methods

- (NSDictionary *) registrationDictionaryForGrowl
{
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSArray arrayWithObject:kGrowlNotificationNameUploadComplete], [NSArray arrayWithObject:kGrowlNotificationNameUploadComplete], nil]
                                       forKeys:[NSArray arrayWithObjects:GROWL_NOTIFICATIONS_ALL, GROWL_NOTIFICATIONS_DEFAULT, nil ]];
}

- (NSString *) applicationNameForGrowl
{
    return DKLocalizedStringForClass(@"application name for growl");
}

- (void) growlNotificationWasClicked:(id)clickContext
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:clickContext]];
}

- (void) growlIsReady
{
    DLog(@"Growl is ready");
}

@end
