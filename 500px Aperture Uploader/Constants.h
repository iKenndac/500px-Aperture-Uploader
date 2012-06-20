//
//  Constants.h
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 10/03/2012.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>

#define DKLocalizedStringForClass(key) \
[[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:@"" table:@"Localizable"]

static void * const k500pxUpdateStoreSizeWarningKVOContext = @"BigPicturesAreAwesome";

// Keychain

static NSString * const k500pxKeychainServiceName = @"500px Aperture Uploader";

// 500px Values

static NSString * const k500pxURLMetadataKey = @"500px URL";
static NSString * const k500pxPhotoURLFormatter = @"http://500px.com/photo/%@";
static NSString * const k500pxProfileURLFormatter = @"http://500px.com/%@";
static NSUInteger const k500pxMinimumSizeForStore = 3600;

// Growl

static NSString * const kGrowlNotificationNameUploadComplete = @"upload";

// Tags

static NSString * const kAutofillTagsUserDefaultsKey = @"AutofillTags";
static NSUInteger const kTagAttemptCount = 24;
static NSTimeInterval const kTagAttemptDelay = 5.0;

// Updates

static NSString * const kAutoCheckForUpdatesUserDefaultsKey = @"CheckForUpdates";
static NSString * const kLastAutoCheckDateUserDefaultsKey = @"LastUpdateCheck";
static NSTimeInterval const kAutoCheckMinimumInterval = 60 * 60; // Only auto-check for updates once per hour.

static NSString * const kDKBasicUpdateCheckerNewestBundleVersionKey = @"BundleVersion";
static NSString * const kDKBasicUpdateCheckerNewestVersionStringKey = @"VersionString";
static NSString * const kDKBasicUpdateCheckerMoreInfoURLKey = @"MoreInfoURL";
static NSString * const kDKBasicUpdateCheckerUpdateFileURLInfoPlistKey = @"DKBUCUpdateFileUrl";

// Logging

static NSTimeInterval const kLogDeletionThreshold = 60 * 60 * 24 * 14; // 14 days

static NSString * const kCreateLogsUserDefaultsKey = @"CreateLogs";
static NSString * const kAutoOpenLogsUserDefaultsKey = @"AutoOpenLogs";

static NSString * const kLogsDirectoryName = @"500px Aperture Uploader";

static NSString * const kLogEntrySourceName = @"log_chunk";
static NSString * const kLogEntrySourceType = @"html";
static NSString * const kLogSourceName = @"log_template";
static NSString * const kLogSourceType = @"html";

static NSString * const kPhotoNameLogKey = @"$PHOTO_NAME";
static NSString * const kPhotoStatusLogKey = @"$PHOTO_STATUS";
static NSString * const kPhotoURLLogKey = @"$PHOTO_URL";
static NSString * const kUserProfileURLLogKey = @"$USER_PROFILE_URL";
static NSString * const kUserNameLogKey = @"$USER_NAME";
static NSString * const kUploadStartDateLogKey = @"$UPLOAD_START_DATE";
static NSString * const kUploadEndDateLogKey = @"$UPLOAD_END_DATE";
static NSString * const kOverallStatusLogKey = @"$OVERALL_UPLOAD_STATUS";
static NSString * const kLogRowsLogKey = @"$LOG_ROWS";
