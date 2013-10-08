//
//  FiveHundredPx32BitDummyExporter.m
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 10/03/2012.
//  For license information, see LICENSE.markdown
//

#import "FiveHundredPx32BitDummyExporter.h"

#define DKLocalizedStringForClass(key) \
[[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:@"" table:@"Localizable"]

static NSString * const k32BitHelpURL = @"https://github.com/iKenndac/500px-Aperture-Uploader/wiki/500px-Aperture-Uploader-Cannot-Run-in-32-bit-Mode";

@implementation FiveHundredPxApertureExporter

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
	
	NSAlert *alert = [NSAlert alertWithMessageText:DKLocalizedStringForClass(@"64-bit only error title")
									 defaultButton:DKLocalizedStringForClass(@"ok title")
								   alternateButton:DKLocalizedStringForClass(@"more information title")
									   otherButton:@""
						 informativeTextWithFormat:@"%@", DKLocalizedStringForClass(@"64-bit only error description")];
	
	if ([alert runModal] == NSAlertAlternateReturn) {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:k32BitHelpURL]];
	}
	
	[self release];
	return nil;
}

-(NSView *)settingsView { return nil; }
-(NSView *)firstView { return nil; }
-(NSView *)lastView { return nil; }
-(void)willBeActivated {}
-(void)willBeDeactivated {}
-(BOOL)allowsOnlyPlugInPresets { return NO; }
-(BOOL)allowsMasterExport { return NO; }
-(BOOL)allowsVersionExport { return YES; }
-(BOOL)wantsFileNamingControls { return NO; }
-(void)exportManagerExportTypeDidChange {}
-(BOOL)wantsDestinationPathPrompt { return NO; }
-(NSString *)destinationPath { return nil; }
-(NSString *)defaultDirectory { return nil; }
-(void)exportManagerShouldBeginExport {}
-(void)exportManagerWillBeginExportToPath:(NSString *)path {}
-(BOOL)exportManagerShouldExportImageAtIndex:(unsigned)index { return NO; }
-(void)exportManagerWillExportImageAtIndex:(unsigned)index {}
-(BOOL)exportManagerShouldWriteImageData:(NSData *)imageData toRelativePath:(NSString *)path forImageAtIndex:(unsigned)index { return NO; }
-(void)exportManagerDidWriteImageDataToRelativePath:(NSString *)relativePath forImageAtIndex:(unsigned)index {}
-(void)exportManagerDidFinishExport {}
-(void)exportManagerShouldCancelExport {}
-(ApertureExportProgress *)progress { return nil; }
-(void)lockProgress {}
-(void)unlockProgress {}

@end
