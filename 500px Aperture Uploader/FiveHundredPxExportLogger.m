//
//  FiveHundredPxExportLogger.m
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 11/03/2012.
//  For license information, see LICENSE.markdown
//

#import "FiveHundredPxExportLogger.h"
#import "Constants.h"

@interface FiveHundredPxExportLogger ()

@property (nonatomic, readwrite, strong) NSArray *logEntries;

-(NSString *)outputForLogEntry:(NSDictionary *)entry;
-(NSString *)stringByReplacingKeysInSource:(NSString *)string withEntries:(NSDictionary *)entries;

@end

@implementation FiveHundredPxExportLogger

+(NSURL *)logsDirectory {
	return [[[[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory
													inDomain:NSUserDomainMask
										   appropriateForURL:nil
													  create:YES
													   error:nil] 
			 URLByAppendingPathComponent:@"Logs"] 
			URLByAppendingPathComponent:kLogsDirectoryName];
}

-(id)init {
	self = [super init];
	
	if (self) {
		self.startDate = [NSDate date];
		self.endDate = self.startDate;
		self.logEntries = [NSArray array];
	}
	return self;
}

@synthesize startDate;
@synthesize endDate;
@synthesize overallStatus;
@synthesize userName;
@synthesize userUrl;
@synthesize logEntries;

-(void)addLogRowWithImageName:(NSString *)name status:(NSString *)status url:(NSURL *)url {

	NSDictionary *rowDict = [NSDictionary dictionaryWithObjectsAndKeys:
							 name == nil ? @"" : name, kPhotoNameLogKey,
							 status == nil ? @"" : status, kPhotoStatusLogKey,
							 url == nil ? @"" : [url absoluteString], kPhotoURLLogKey,
							 nil];
	
	self.logEntries = [self.logEntries arrayByAddingObject:rowDict];
}

-(NSURL *)outputLog:(NSError **)error thenOpen:(BOOL)autoOpen {
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	[dict setValue:self.userUrl == nil ? @"" : [self.userUrl absoluteString] forKey:kUserProfileURLLogKey];
	[dict setValue:self.userName == nil ? @"" : self.userName forKey:kUserNameLogKey];
	[dict setValue:self.overallStatus == nil ? @"" : self.overallStatus forKey:kOverallStatusLogKey];
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	formatter.dateStyle = NSDateFormatterShortStyle;
	formatter.timeStyle = NSDateFormatterShortStyle;
	
	[dict setValue:self.startDate == nil ? @"" : [formatter stringFromDate:self.startDate] forKey:kUploadStartDateLogKey];
	[dict setValue:self.endDate == nil ? @"" : [formatter stringFromDate:self.endDate] forKey:kUploadEndDateLogKey];

	NSMutableString *rows = [NSMutableString string];
	
	for (NSDictionary *row in self.logEntries) {
		[rows appendString:[self outputForLogEntry:row]];
	}
	
	[dict setValue:rows forKey:kLogRowsLogKey];
	
	NSString *sourcePath = [[NSBundle bundleForClass:[self class]] pathForResource:kLogSourceName ofType:kLogSourceType];
	NSString *source = [[NSString alloc] initWithContentsOfFile:sourcePath
													   encoding:NSUTF8StringEncoding
														  error:nil];
	
	NSString *log = [self stringByReplacingKeysInSource:source withEntries:dict];
	
	NSURL *logsDir = [FiveHundredPxExportLogger logsDirectory];
	if (![[NSFileManager defaultManager] createDirectoryAtURL:logsDir withIntermediateDirectories:YES attributes:nil error:nil])
		return nil;
	
	NSURL *logLocation = [logsDir URLByAppendingPathComponent:[self fileNameForLogAtDate:self.startDate]];
	
	if (![log writeToURL:logLocation 
		 atomically:YES
		   encoding:NSUTF8StringEncoding
			  error:error])
		return nil;
	
	if (autoOpen)
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?auto_opened=true", [logLocation absoluteString]]]];
	
	return logLocation;
};

#pragma mark - Internal

-(NSString *)fileNameForLogAtDate:(NSDate *)date {
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	formatter.dateStyle = NSDateFormatterShortStyle;
	formatter.timeStyle = NSDateFormatterShortStyle;
	
	return [[NSString stringWithFormat:DKLocalizedStringForClass(@"log filename template"),
			 [formatter stringFromDate:date]] stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	
}

-(NSString *)outputForLogEntry:(NSDictionary *)entry {

	NSString *sourcePath = [[NSBundle bundleForClass:[self class]] pathForResource:kLogEntrySourceName ofType:kLogEntrySourceType];
	NSString *source = [[NSString alloc] initWithContentsOfFile:sourcePath
													   encoding:NSUTF8StringEncoding
														  error:nil];
	
	return [self stringByReplacingKeysInSource:source withEntries:entry];
	
}

-(NSString *)stringByReplacingKeysInSource:(NSString *)string withEntries:(NSDictionary *)entries {
	
	NSMutableString *mutableSource = [string mutableCopy];
	
	for (NSString *key in entries.allKeys) {
		
		[mutableSource replaceOccurrencesOfString:key
									   withString:[NSString stringWithFormat:@"%@", [entries valueForKey:key]]
										  options:0
											range:NSMakeRange(0, mutableSource.length)];
		
	}
	
	return [[NSString alloc] initWithString:mutableSource];
}

@end
