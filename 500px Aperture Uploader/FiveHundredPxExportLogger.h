//
//  FiveHundredPxExportLogger.h
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 11/03/2012.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>

@interface FiveHundredPxExportLogger : NSObject

+(NSURL *)logsDirectory;

@property (nonatomic, readwrite, strong) NSDate *startDate;
@property (nonatomic, readwrite, strong) NSDate *endDate;
@property (nonatomic, readwrite, copy) NSString *overallStatus;
@property (nonatomic, readwrite, copy) NSString *userName;
@property (nonatomic, readwrite, copy) NSURL *userUrl;

-(void)addLogRowWithImageName:(NSString *)name status:(NSString *)status url:(NSURL *)url;

-(NSURL *)outputLog:(NSError **)error thenOpen:(BOOL)autoOpen;

@end
