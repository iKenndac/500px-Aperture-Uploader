//
//  FiveHundredPxExtraMetadata.h
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 18/02/2012.
//  Copyright (c) 2012 Daniel Kennett. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FiveHundredPxExtraMetadata : NSObject

@property (readwrite, nonatomic) NSInteger categoryId;
@property (readwrite, nonatomic, getter = hasPrivacy) BOOL privacy;

@end
