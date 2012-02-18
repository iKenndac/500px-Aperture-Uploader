//
//  FiveHundredPxExtraMetadata.h
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 18/02/2012.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>

@interface FiveHundredPxExtraMetadata : NSObject

-(id)initWithImageProperties:(NSDictionary *)props;

@property (readwrite, nonatomic) NSInteger categoryId;
@property (readwrite, nonatomic, getter = hasPrivacy) BOOL privacy;
@property (readwrite, nonatomic, strong) NSDictionary *imageProperties;

-(NSDictionary *)dictionaryValue;

@end
