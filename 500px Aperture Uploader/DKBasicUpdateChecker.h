//
//  DKBasicUpdateChecker.h
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 21/02/2012.
//  For license information, see LICENSE.markdown
//


#import <Foundation/Foundation.h>

static NSString * const kDKBasicUpdateCheckerNewestBundleVersionKey = @"BundleVersion";
static NSString * const kDKBasicUpdateCheckerNewestVersionStringKey = @"VersionString";
static NSString * const kDKBasicUpdateCheckerMoreInfoURLKey = @"MoreInfoURL";

static NSString * const kDKBasicUpdateCheckerUpdateFileURLInfoPlistKey = @"DKBUCUpdateFileUrl";

@interface DKBasicUpdateChecker : NSObject <NSURLConnectionDelegate>

@property (nonatomic, readonly, getter = isCheckingForUpdates) BOOL checkingForUpdates;

-(void)checkForUpdates:(BOOL)withUi;

@end
