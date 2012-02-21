//
//  DKBasicUpdateChecker.m
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 21/02/2012.
//  For license information, see LICENSE.markdown
//


#import "DKBasicUpdateChecker.h"

@interface DKBasicUpdateChecker ()

@property (nonatomic, readwrite, strong) NSURLConnection *connection;
@property (nonatomic, readwrite) BOOL shouldShowFailureUI;
@property (nonatomic, readwrite, strong) NSMutableData *downloadedData;

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
										   userInfo:[NSDictionary dictionaryWithObject:@"No update data received."
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
										   userInfo:[NSDictionary dictionaryWithObject:@"Invalid update data received."
																				forKey:NSLocalizedDescriptionKey]]];
		return;
	}
	
	NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
	NSString *shortVersionString = [myBundle.infoDictionary valueForKey:@"CFBundleShortVersionString"];
	NSNumber *cfBundleVersion = [myBundle.infoDictionary valueForKey:@"CFBundleVersion"];
	
	if (newestCFBundleVersion.integerValue > cfBundleVersion.integerValue) {
		
		NSString *informativeText = nil;
		if ([shortVersionString isEqualToString:newestShortVersionString]) 
			informativeText = [NSString stringWithFormat:@"You have version %@ (%@) — the newest version is %@ (%@).", shortVersionString, cfBundleVersion, newestShortVersionString, newestCFBundleVersion];
		else
			informativeText = [NSString stringWithFormat:@"You have version %@ — the newest version is %@.", shortVersionString, newestShortVersionString];
		
		if ([[NSAlert alertWithMessageText:[NSString stringWithFormat:@"A new version of %@ is available!", [myBundle.infoDictionary valueForKey:@"CFBundleName"]]
							 defaultButton:@"More Info…"
						   alternateButton:@"Later"
							   otherButton:@""
				 informativeTextWithFormat:informativeText] runModal] == NSAlertDefaultReturn) {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:moreInfoURLString]];
		};
		
	} else if (self.shouldShowFailureUI)
		[[NSAlert alertWithMessageText:@"You're up-to-date!"
						 defaultButton:@"OK"
					   alternateButton:@""
						   otherButton:@""
			 informativeTextWithFormat:[NSString stringWithFormat:@"Version %@ is the newest version available.", newestShortVersionString]] runModal];
}

-(void)presentError:(NSError *)error {
	
	if (!self.shouldShowFailureUI)
		return;
	
	[[NSAlert alertWithMessageText:@"An error occurred when checking for updates!"
					 defaultButton:@"OK"
				   alternateButton:@""
					   otherButton:@""
		 informativeTextWithFormat:[NSString stringWithFormat:@"The error encountered was: %@", error.localizedDescription]] runModal];
}

@end
