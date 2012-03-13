//
//  AppDelegate.m
//  Installer
//
//  Created by Daniel Kennett on 13/03/2012.
//  For license information, see LICENSE.markdown
//

#import "AppDelegate.h"
#import "Constants.h"

static NSString * const kPluginFileName = @"500px Aperture Uploader.ApertureExport";

@implementation AppDelegate

@synthesize window = _window;
@synthesize imageView = _imageView;
@synthesize headerTextField = _headerTextField;

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	
	NSURL *sourceUrl = [[NSBundle mainBundle] URLForResource:kPluginFileName withExtension:@""];
	NSBundle *sourceBundle = [NSBundle bundleWithURL:sourceUrl];
	NSString *iconName = [[sourceBundle infoDictionary] valueForKey:@"CFBundleIconFile"];
	
	NSImage *icon = [[NSImage alloc] initWithContentsOfURL:[sourceBundle URLForResource:iconName withExtension:@""]];
	
	if (icon != nil)
		self.imageView.image = icon;
	else
		self.imageView.image = [NSImage imageNamed:NSImageNameApplicationIcon];
	
	self.headerTextField.stringValue = [NSString stringWithFormat:DKLocalizedStringForClass(@"installer header"),
										[sourceBundle.infoDictionary valueForKey:@"CFBundleShortVersionString"]];
	
	[self.window center];
}

- (IBAction)performInstallation:(id)sender {
	
	NSURL *folderUrl = [[[[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
																 inDomain:NSUserDomainMask
														appropriateForURL:nil
																   create:YES
																	error:nil] 
						  URLByAppendingPathComponent:@"Aperture" isDirectory:YES] 
						 URLByAppendingPathComponent:@"Plug-Ins" isDirectory:YES]
						URLByAppendingPathComponent:@"Export" isDirectory:YES];
	
	NSError *error = nil;
	if (![folderUrl checkResourceIsReachableAndReturnError:&error]) {
		if (![[NSFileManager defaultManager] createDirectoryAtURL:folderUrl
									  withIntermediateDirectories:YES
													   attributes:nil
															error:&error]) {
			[self presentError:error];
			return;
		}
	}
	
	NSURL *sourceUrl = [[NSBundle mainBundle] URLForResource:kPluginFileName withExtension:@""];
	NSURL *pluginUrl = [folderUrl URLByAppendingPathComponent:kPluginFileName isDirectory:YES];
	
	// Does it already exist?
	
	if ([pluginUrl checkResourceIsReachableAndReturnError:&error]) {
		if (![[NSFileManager defaultManager] removeItemAtURL:pluginUrl error:&error]) {
			[self presentError:error];
			return;
		}
	}

	// Copy to destination
	
	if (![[NSFileManager defaultManager] copyItemAtURL:sourceUrl
												 toURL:pluginUrl
												 error:&error]) {
		[self presentError:error];
		return;
	}
	
	// If we get here, success!
	
	NSString *version = [[[NSBundle bundleWithURL:sourceUrl] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
	
	NSAlert *alert = [NSAlert alertWithMessageText:DKLocalizedStringForClass(@"installation succeeded title")
									 defaultButton:DKLocalizedStringForClass(@"ok title")
								   alternateButton:@""
									   otherButton:@""
						 informativeTextWithFormat:DKLocalizedStringForClass(@"installation succeeded description"), version];
	
	alert.icon = self.imageView.image;
	
	[alert beginSheetModalForWindow:self.window
					  modalDelegate:self
					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
						contextInfo:nil];
	
}

-(void)presentError:(NSError *)error {
	
	NSAlert *alert = [NSAlert alertWithMessageText:DKLocalizedStringForClass(@"installation failed error title")
									 defaultButton:DKLocalizedStringForClass(@"ok title")
								   alternateButton:@""
									   otherButton:@""
						 informativeTextWithFormat:DKLocalizedStringForClass(@"installation failed error description"), error];
	
	alert.icon = self.imageView.image;
	
	[alert beginSheetModalForWindow:self.window
					  modalDelegate:self
					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
						contextInfo:nil];

}

-(void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[(NSApplication *)NSApp terminate:self];	
}


@end
