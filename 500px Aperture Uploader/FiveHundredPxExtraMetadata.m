//
//  FiveHundredPxExtraMetadata.m
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 18/02/2012.
//  Copyright (c) 2012 Daniel Kennett. All rights reserved.
//

#import "FiveHundredPxExtraMetadata.h"
#import "ApertureExportPlugIn.h"
#import <Quartz/Quartz.h>

@implementation FiveHundredPxExtraMetadata

-(id)initWithImageProperties:(NSDictionary *)props {
	self = [super init];
	
	if (self)
		self.imageProperties = props;
	
	return self;
}

@synthesize categoryId;
@synthesize privacy;
@synthesize imageProperties;

-(NSDictionary *)dictionaryValue {
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	if (self.categoryId > 0)
		[dict setValue:[NSString stringWithFormat:@"%lu", self.categoryId] forKey:@"category"];
	
	[dict setValue:self.privacy ? @"1" : @"0" forKey:@"privacy"];

	return [NSDictionary dictionaryWithDictionary:dict];
}

-(NSString *)imageUID {
	return [self.imageProperties valueForKey:kExportKeyVersionName];
}

-(NSString *)imageRepresentationType {
	return IKImageBrowserNSImageRepresentationType;
}

-(id)imageRepresentation {
	return [self.imageProperties valueForKey:kExportKeyThumbnailImage];
}

@end
