//
//  FiveHundredPxViewController.m
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 10/03/2012.
//  For license information, see LICENSE.markdown
//

#import "FiveHundredPxViewController.h"
#import "Constants.h"
#import "FiveHundredPxExtraMetadata.h"

@interface FiveHundredPxViewController ()

@end

@implementation FiveHundredPxViewController

-(id)initWithOAuthEngine:(FiveHundredPxOAuthEngine *)oAuthEngine {
    
	self = [super initWithNibName:@"FiveHundredPxViewController" bundle:[NSBundle bundleForClass:[self class]]];
   
	if (self) {
        // Initialization code here.
		self.engine = oAuthEngine;
		
		[self addObserver:self
			   forKeyPath:@"metadataArrayController.selection"
				  options:NSKeyValueObservingOptionInitial
				  context:k500pxUpdateStoreSizeWarningKVOContext];
		
		[self addObserver:self
			   forKeyPath:@"exporter.exportManager.selectedExportPresetDictionary"
				  options:NSKeyValueObservingOptionInitial
				  context:k500pxUpdateStoreSizeWarningKVOContext];
		
		[self addObserver:self
			   forKeyPath:@"exporter.metadataContainers"
				  options:NSKeyValueObservingOptionInitial
				  context:nil];
		
		
		// ^ The above property isn't KVO-compliant, so we look for ALL menu actions to get the preset menu changing. UGH.
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(presetMenuMayHaveChanged:)
													 name:NSMenuDidChangeItemNotification
												   object:nil];

	}
    
    return self;
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"metadataArrayController.selection"];
	[self removeObserver:self forKeyPath:@"exporter.exportManager.selectedExportPresetDictionary"];
	[self removeObserver:self forKeyPath:@"exporter.metadataContainers"];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSMenuDidChangeItemNotification object:nil];
}

#pragma mark - Properties

@synthesize firstView;
@synthesize lastView;
@synthesize selectedImageIsBigEnoughForStore;
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
@synthesize logImagePropertiesButton;
@synthesize logCurrentPresetButton;
@synthesize tagField;
@synthesize engine;
@synthesize exporter;

+(NSSet *)keyPathsForValuesAffectingLoginStatusText {
	return [NSSet setWithObjects:@"engine.working", @"engine.isAuthenticated", nil];
}

-(NSString *)loginStatusText {
	
	if (self.engine.isWorking) {
		return DKLocalizedStringForClass(@"authenticating title");
	} else {
		return self.engine.isAuthenticated ?
		[NSString stringWithFormat:DKLocalizedStringForClass(@"logged in title"), self.engine.screenName] 
		: DKLocalizedStringForClass(@"not logged in title");
	}
}

+(NSSet *)keyPathsForValuesAffectingLogInOutButtonTitle {
	return [NSSet setWithObject:@"engine.isAuthenticated"];
}

-(NSString *)logInOutButtonTitle {
	return self.engine.isAuthenticated ? DKLocalizedStringForClass(@"log out title") : DKLocalizedStringForClass(@"log in title");
}

#pragma mark - Internal Logic

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
	
#if !DEBUG
	if (([NSEvent modifierFlags] & NSAlternateKeyMask) != NSAlternateKeyMask) {
		[self.logImagePropertiesButton setHidden:YES];
		[self.logCurrentPresetButton setHidden:YES];
	}
#endif
	
	self.tagField.tokenizingCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@","];
	
	[self.imageBrowser reloadData];
}

-(BOOL)imageAtIndexIsBigEnoughForStore:(NSUInteger)index {
	
	NSDictionary *preset = self.exporter.exportManager.selectedExportPresetDictionary;
	NSDictionary *image = [self.exporter.exportManager propertiesWithoutThumbnailForImageAtIndex:(unsigned)index];
	
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

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == k500pxUpdateStoreSizeWarningKVOContext) {
		self.selectedImageIsBigEnoughForStore = [self imageAtIndexIsBigEnoughForStore:self.metadataArrayController.selectionIndex];
    } else if ([keyPath isEqualToString:@"exporter.metadataContainers"]) {
		[self.imageBrowser reloadData];
		[self.imageBrowser setSelectionIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
		[self.metadataArrayController setSelectionIndex:0];
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)presetMenuMayHaveChanged:(NSNotification *)not {
	self.selectedImageIsBigEnoughForStore = [self imageAtIndexIsBigEnoughForStore:self.metadataArrayController.selectionIndex];
}

-(void)presentLoginFailedError:(NSError *)error {
	NSString *description = error.code == 401 ? 
	DKLocalizedStringForClass(@"cannot login error description") :
	DKLocalizedStringForClass(@"cannot login auth failed description");
	
	
	NSAlert *alert = [NSAlert alertWithMessageText:DKLocalizedStringForClass(@"cannot login error title")
									 defaultButton:DKLocalizedStringForClass(@"ok title")
								   alternateButton:@""
									   otherButton:@""
						 informativeTextWithFormat:description];
	
	[alert runModal];
}

#pragma mark - Actions

- (IBAction)logCurrentExportPreset:(id)sender {
	NSLog(@"%@", self.exporter.exportManager.selectedExportPresetDictionary);
}

- (IBAction)logCurrentImageProperties:(id)sender {
	NSLog(@"%@", [self.exporter.exportManager propertiesWithoutThumbnailForImageAtIndex:(unsigned)self.metadataArrayController.selectionIndex]);
}

- (IBAction)openLogsDirectory:(id)sender {
	
	NSURL *logsDir = [FiveHundredPxExportLogger logsDirectory];
	[[NSFileManager defaultManager] createDirectoryAtURL:logsDir withIntermediateDirectories:YES attributes:nil error:nil];
	
	[[NSWorkspace sharedWorkspace] openURL:logsDir];
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
	
	if (self.loginSheetUsernameField.stringValue.length == 0) {
		NSBeep();
		[self.loginSheetUsernameField becomeFirstResponder];
		return;
	}
	
	if (self.loginSheetPasswordField.stringValue.length == 0) {
		NSBeep();
		[self.loginSheetPasswordField becomeFirstResponder];
		return;
	}
	
	[self cancelLogInSheet:sender];
	
	[self.engine authenticateWithCompletionBlock:^(NSError *error) {
		if (error != nil) {
			[self presentLoginFailedError:error];			
		}
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
	[self.exporter.updater checkForUpdates:YES];
}

- (IBAction)viewSelectedPhotoOn500px:(id)sender {
	
	FiveHundredPxExtraMetadata *metadata = [self.exporter.metadataContainers objectAtIndex:self.metadataArrayController.selectionIndex];
	if (metadata.existing500pxURL != nil)
		[[NSWorkspace sharedWorkspace] openURL:metadata.existing500pxURL];
	else
		NSBeep();
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


@end
