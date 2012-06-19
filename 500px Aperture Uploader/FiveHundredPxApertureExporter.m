//
//  FiveHundredPxApertureExporter.m
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 17/02/2012.
//  For license information, see LICENSE.markdown
//

#import "FiveHundredPxApertureExporter.h"
#import "Constants.h"
#import "FiveHundredPxExtraMetadata.h"

@implementation FiveHundredPxApertureExporter {
	ApertureExportProgress exportProgress;
}

@synthesize apiManager;
@synthesize exportManager;
@synthesize progressLock;
@synthesize engine;
@synthesize metadataContainers;
@synthesize updater;
@synthesize viewController;
@synthesize logger;
@synthesize hadErrorsDuringExport;
@synthesize hadSuccessesDuringExport;

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
	
	self = [super init];
	
	if (self) {
		self.apiManager	= anApiManager;
		self.exportManager = [self.apiManager apiForProtocol:@protocol(ApertureExportManager)];
        
		if (self.exportManager == nil)
			return nil;
		
		self.progressLock = [[NSLock alloc] init];
		self.engine = [[FiveHundredPxOAuthEngine alloc] initWithDelegate:self];
		self.updater = [[DKBasicUpdateChecker alloc] init];
		self.viewController = [[FiveHundredPxViewController alloc] initWithOAuthEngine:self.engine];
		self.viewController.exporter = self;
		
		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
																 [NSNumber numberWithBool:YES], kAutoCheckForUpdatesUserDefaultsKey,
																 [NSNumber numberWithBool:YES], kCreateLogsUserDefaultsKey,
																 [NSNumber numberWithBool:YES], kAutoOpenLogsUserDefaultsKey,
																 [NSNumber numberWithBool:YES], kAutofillTagsUserDefaultsKey,
																 nil]];
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey:kAutoCheckForUpdatesUserDefaultsKey]) {
			NSDate *lastCheckDate = [[NSUserDefaults standardUserDefaults] valueForKey:kLastAutoCheckDateUserDefaultsKey];
			
			if (lastCheckDate == nil || [[NSDate date] timeIntervalSinceDate:lastCheckDate] > kAutoCheckMinimumInterval) {
				[self.updater checkForUpdates:NO];
				[[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:kLastAutoCheckDateUserDefaultsKey];
			}
		}
			
		memset(&exportProgress, 0, sizeof(exportProgress));
		
		[self pruneLogsIfNeeded];
	}
	
	return self;
}

-(void)pruneLogsIfNeeded {
	
	// Check logs
	
	NSURL *logsDir = [FiveHundredPxExportLogger logsDirectory];
	if (![logsDir checkResourceIsReachableAndReturnError:nil])
		return;

	NSEnumerator *logEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:logsDir
													   includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLCreationDateKey, NSURLNameKey, nil]
																		  options:NSDirectoryEnumerationSkipsSubdirectoryDescendants |
																					NSDirectoryEnumerationSkipsPackageDescendants |
								   NSDirectoryEnumerationSkipsHiddenFiles
																	 errorHandler:nil];
	
	for (NSURL *theURL in logEnumerator) {
		
		NSString *name = nil;
		[theURL getResourceValue:&name forKey:NSURLNameKey error:nil];
		if ([[name pathExtension] isEqualToString:[DKLocalizedStringForClass(@"log filename template") pathExtension]]) {
			
			NSDate *creationDate = nil;
			[theURL getResourceValue:&creationDate forKey:NSURLCreationDateKey error:NULL];
			if ([[NSDate date] timeIntervalSinceDate:creationDate] > kLogDeletionThreshold) {
				
				[[NSFileManager defaultManager] removeItemAtURL:theURL error:nil];
			}
		}
	}
	
}

#pragma mark -
#pragma mark 500px Interaction

-(void)verifyLoginDetails {
	
	[self.engine getDetailsForLoggedInUser:^(NSDictionary *returnValue, NSError *error) {
		if (error != nil) {
			[self.viewController presentLoginFailedError:error];
		} 
	}];
}

#pragma mark -
// UI Methods
#pragma mark UI Methods

-(NSView *)settingsView {
	return self.viewController.view;
}

-(NSView *)firstView {
	return self.viewController.firstView;
}

-(NSView *)lastView {
	return self.viewController.lastView;
}

-(void)willBeActivated {
	if (self.engine.isAuthenticated)
		[self verifyLoginDetails];
	
	NSMutableArray *newContainers = [NSMutableArray arrayWithCapacity:[self.exportManager imageCount]];
	for (unsigned int i = 0; i < [self.exportManager imageCount]; i++) {
		[newContainers addObject:[[FiveHundredPxExtraMetadata alloc] initWithImageProperties:[self.exportManager propertiesForImageAtIndex:i]]];
	}
	
	self.metadataContainers = [NSArray arrayWithArray:newContainers];
}

-(void)willBeDeactivated {
	// Nothing needed here
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
		
		self.logger = [[FiveHundredPxExportLogger alloc] init];
		self.logger.startDate = [NSDate date];
		self.logger.userName = self.engine.screenName;
		self.logger.userUrl = [NSURL URLWithString:[NSString stringWithFormat:k500pxProfileURLFormatter, self.engine.screenName]];
		
		self.hadErrorsDuringExport = NO;
		self.hadSuccessesDuringExport = NO;
		
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
					 self.hadErrorsDuringExport = YES;
					 [self.logger addLogRowWithImageName:[[self.metadataContainers objectAtIndex:index] title]
												  status:[NSString stringWithFormat:DKLocalizedStringForClass(@"log error status"), error]
													 url:DKLocalizedStringForClass(@"log error URL")]; 
					 DLog(@"%@", error);
					 isRunning = NO;
				 } else {
					 self.hadSuccessesDuringExport = YES;
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
						 
						 // Now, set the tags
						 NSArray *tags = [[self.metadataContainers objectAtIndex:index] tags];
						 
						 if (tags.count == 0) {
							 [self.logger addLogRowWithImageName:[[self.metadataContainers objectAtIndex:index] title]
														  status:DKLocalizedStringForClass(@"log success status")
															 url:photoUrlString];
							 isRunning = NO;
						 } else {
							 [self attemptToSetTags:tags forImageWithId:photoId completionBlock:^(NSError *tagError) {
								 
								 if (tagError != nil) {
									 [self.logger addLogRowWithImageName:[[self.metadataContainers objectAtIndex:index] title]
																  status:DKLocalizedStringForClass(@"log tag timeout status")
																	 url:photoUrlString];
								 } else {
									 [self.logger addLogRowWithImageName:[[self.metadataContainers objectAtIndex:index] title]
																  status:DKLocalizedStringForClass(@"log success status")
																	 url:photoUrlString];
								 }
								 isRunning = NO;
							 }];
						 }
					 }
				 }
			 }];
	
	while (isRunning)
		[NSThread sleepForTimeInterval:0.1];
	
	DLog(@"Done!");
    
	// Tell Aperture to write the file out if needed.
	BOOL shouldAlsoWriteImageFileSomewhere = NO;
	return shouldAlsoWriteImageFileSomewhere;
}

-(void)attemptToSetTags:(NSArray *)tags forImageWithId:(NSString *)photoId completionBlock:(FiveHundredPxCompletionBlock)block {
	[self attemptToSetTags:tags forImageWithId:photoId attemptNumber:1 completionBlock:block];
}

-(void)attemptToSetTags:(NSArray *)tags forImageWithId:(NSString *)photoId attemptNumber:(NSUInteger)attempt completionBlock:(FiveHundredPxCompletionBlock)block {
	
	__weak FiveHundredPxApertureExporter *weakSelf = self;
	DLog(@"Setting tags, attempt number %lu", attempt);
	
	[weakSelf.engine setTags:tags forPhotoWithId:photoId completionBlock:^(NSDictionary *returnValue, NSError *error) {
		
		if (error != nil) {
			
			if (attempt == kTagAttemptCount) {
				if (block) block([NSError errorWithDomain:@"org.danielkennett.500px.ErrorDomain"
													 code:4
												 userInfo:[NSDictionary dictionaryWithObject:DKLocalizedStringForClass(@"tag timeout error")
																					  forKey:NSLocalizedDescriptionKey]]);
			} else {
				double delayInSeconds = kTagAttemptDelay;
				dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
				dispatch_after(popTime, dispatch_get_current_queue(), ^(void){
					[weakSelf attemptToSetTags:tags forImageWithId:photoId attemptNumber:attempt + 1 completionBlock:block];
				});
			}
		} else {
			if (block) block(nil);
		}
	}];
}

-(void)exportManagerDidWriteImageDataToRelativePath:(NSString *)relativePath forImageAtIndex:(unsigned)index {
}

-(void)exportManagerDidFinishExport {
	
	NSURL *logUrl = nil;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kCreateLogsUserDefaultsKey]) {
		self.logger.endDate = [NSDate date];
		
		if (self.hadErrorsDuringExport && self.hadSuccessesDuringExport) {
			self.logger.overallStatus = DKLocalizedStringForClass(@"log status some failed");
		} else if (self.hadErrorsDuringExport) {
			self.logger.overallStatus = DKLocalizedStringForClass(@"log status all failed");
		} else if (self.hadSuccessesDuringExport) {
			self.logger.overallStatus = DKLocalizedStringForClass(@"log status all succeeded");
		} else {
			// Nothing happened? Shouldn't really get here.
			self.logger.overallStatus = DKLocalizedStringForClass(@"log status nothing happened");
		}
		
		logUrl = [self.logger outputLog:nil
							   thenOpen:[[NSUserDefaults standardUserDefaults] boolForKey:kAutoOpenLogsUserDefaultsKey]];
	}
	
    
    @synchronized(exportManager) {
        [self.exportManager shouldFinishExport];
        
		NSString *urlToClick = logUrl == nil ? [NSString stringWithFormat:k500pxProfileURLFormatter, self.engine.screenName] : [logUrl absoluteString];
		
        [GrowlApplicationBridge notifyWithTitle:DKLocalizedStringForClass(@"growl upload complete title")
                                    description:DKLocalizedStringForClass(@"growl upload complete description")
                               notificationName:kGrowlNotificationNameUploadComplete 
                                       iconData:nil
                                       priority:0 
                                       isSticky:NO 
                                   clickContext:urlToClick];
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
	[eng authenticateWithUsername:self.viewController.loginSheetUsernameField.stringValue
						 password:self.viewController.loginSheetPasswordField.stringValue];
}

- (void)fiveHundredPx:(FiveHundredPxOAuthEngine *)engine statusUpdate:(NSString *)message {
	DLog(@"%@", message);
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
