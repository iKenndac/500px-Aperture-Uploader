//
//  DKBasicUpdateChecker.m
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 21/02/2012.
//  For license information, see LICENSE.markdown
//

#import "FiveHundredPxApertureExporter.h"
#import "DKBasicUpdateChecker.h"
#import "Constants.h"

@interface DKBasicUpdateChecker ()

@property (nonatomic, readwrite, strong) NSURLConnection *connection;
@property (nonatomic, readwrite) BOOL shouldShowFailureUI;
@property (nonatomic, readwrite, strong) NSMutableData *downloadedData;

-(void)presentError:(NSError *)error;

@end

@implementation DKBasicUpdateChecker

+(NSSet *)keyPathsForValuesAffectingCheckingForUpdates {
	return [NSSet setWithObject:@"connection"];
}

-(BOOL)isCheckingForUpdates {
	return self.connection != nil;
}

@synthesize connection;
@synthesize shouldShowFailureUI;
@synthesize downloadedData;

-(void)checkForUpdates:(BOOL)withUi {
	
	if (self.connection) return;
	
	self.shouldShowFailureUI = withUi;
	self.downloadedData = [NSMutableData data];
	
	NSString *urlString = [[NSBundle bundleForClass:[self class]].infoDictionary valueForKey:kDKBasicUpdateCheckerUpdateFileURLInfoPlistKey];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString.length == 0 ? @"" : urlString]
											 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
										 timeoutInterval:2.0];
	
	self.connection = [[NSURLConnection alloc] initWithRequest:request
													  delegate:self
											  startImmediately:NO];
	
	[self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[self.connection start];
	
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.downloadedData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	self.connection = nil;
	self.downloadedData = nil;
	
	[self presentError:error];
	
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	self.connection = nil;
	
	if (self.downloadedData == nil) {
		[self presentError:[NSError errorWithDomain:@"com.dkbasicupdatechecker.nodata" 
											   code:0 
										   userInfo:[NSDictionary dictionaryWithObject:DKLocalizedStringForClass(@"no update data received error title")
																				forKey:NSLocalizedDescriptionKey]]];
		return;
	}
	
	NSError *error = nil;
	NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:self.downloadedData
																	options:0
																	 format:NULL
																	  error:&error];
	
	self.downloadedData = nil;
	
	if (error != nil) {
		[self presentError:error];
		return;
	}
	
	NSNumber *newestCFBundleVersion = [plist valueForKey:kDKBasicUpdateCheckerNewestBundleVersionKey];
	NSString *newestShortVersionString = [plist valueForKey:kDKBasicUpdateCheckerNewestVersionStringKey];
	NSString *moreInfoURLString = [plist valueForKey:kDKBasicUpdateCheckerMoreInfoURLKey];
	
	if (newestCFBundleVersion.integerValue == 0 || newestShortVersionString.length == 0 || moreInfoURLString.length == 0) {
		[self presentError:[NSError errorWithDomain:@"com.dkbasicupdatechecker.invaliddata" 
											   code:0 
										   userInfo:[NSDictionary dictionaryWithObject:DKLocalizedStringForClass(@"invalid update data received error title")
																				forKey:NSLocalizedDescriptionKey]]];
		return;
	}
	
	NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
	NSString *shortVersionString = [myBundle.infoDictionary valueForKey:@"CFBundleShortVersionString"];
	NSNumber *cfBundleVersion = [myBundle.infoDictionary valueForKey:@"CFBundleVersion"];
	
	if (newestCFBundleVersion.integerValue > cfBundleVersion.integerValue) {
		
		NSString *informativeText = nil;
		if ([shortVersionString isEqualToString:newestShortVersionString]) 
			informativeText = [NSString stringWithFormat:DKLocalizedStringForClass(@"new version with build id description"), shortVersionString, cfBundleVersion, newestShortVersionString, newestCFBundleVersion];
		else
			informativeText = [NSString stringWithFormat:DKLocalizedStringForClass(@"new version description"), shortVersionString, newestShortVersionString];
		
		if ([[NSAlert alertWithMessageText:[NSString stringWithFormat:DKLocalizedStringForClass(@"new version available title"), [myBundle.infoDictionary valueForKey:@"CFBundleName"]]
							 defaultButton:DKLocalizedStringForClass(@"more info title")
						   alternateButton:DKLocalizedStringForClass(@"later title")
							   otherButton:@""
				 informativeTextWithFormat:informativeText] runModal] == NSAlertDefaultReturn) {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:moreInfoURLString]];
		};
		
	} else if (self.shouldShowFailureUI)
		[[NSAlert alertWithMessageText:DKLocalizedStringForClass(@"up to date title")
						 defaultButton:DKLocalizedStringForClass(@"ok title")
					   alternateButton:@""
						   otherButton:@""
			 informativeTextWithFormat:[NSString stringWithFormat:DKLocalizedStringForClass(@"up to date description"), newestShortVersionString]] runModal];
}

-(void)presentError:(NSError *)error {
	
	if (!self.shouldShowFailureUI)
		return;
	
	[[NSAlert alertWithMessageText:DKLocalizedStringForClass(@"update error title")
					 defaultButton:DKLocalizedStringForClass(@"ok title")
				   alternateButton:@""
					   otherButton:@""
		 informativeTextWithFormat:[NSString stringWithFormat:DKLocalizedStringForClass(@"update error description"), error.localizedDescription]] runModal];
}

@end
