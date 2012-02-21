//
//  FiveHundredPxExtraMetadata.m
//  500px Aperture Uploader
//
//  Created by Daniel Kennett on 18/02/2012.
//  For license information, see LICENSE.markdown
//

#import "FiveHundredPxApertureExporter.h"
#import "FiveHundredPxExtraMetadata.h"
#import "ApertureExportPlugIn.h"
#import <Quartz/Quartz.h>

@implementation FiveHundredPxExtraMetadata

-(id)initWithImageProperties:(NSDictionary *)props {
	self = [super init];
	
	if (self) {
		self.imageProperties = props;
		
		self.title = [[self.imageProperties valueForKey:kExportKeyIPTCProperties] valueForKey:@"ObjectName"];
		if (self.title.length == 0) // No title, fall back to version name.
			self.title = [self.imageProperties valueForKey:kExportKeyVersionName];
		self.imageDescription = [[self.imageProperties valueForKey:kExportKeyIPTCProperties] valueForKey:@"Caption/Abstract"];
		self.lens = [[self.imageProperties valueForKey:kExportKeyEXIFProperties] valueForKey:@"LensModel"];
		
		NSString *existingUrlString = [[self.imageProperties valueForKey:kExportKeyCustomProperties] valueForKey:k500pxURLMetadataKey];
		if (existingUrlString.length > 0)
			self.existing500pxURL = [NSURL URLWithString:existingUrlString];
		
		#if DEBUG
		NSLog(@"%@", self.imageProperties);
		#endif
	}
	return self;
}

@synthesize categoryId;
@synthesize privacy;
@synthesize title;
@synthesize imageDescription;
@synthesize lens;
@synthesize existing500pxURL;
@synthesize imageProperties;

+(NSSet *)keyPathsForValuesAffectingExistsOn500px {
	return [NSSet setWithObject:@"existing500pxURL"];
}

-(BOOL)existsOn500px {
	return self.existing500pxURL != nil;
}

-(NSDictionary *)dictionaryValue {
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	if (self.categoryId > 0)
		[dict setValue:[NSString stringWithFormat:@"%lu", self.categoryId] forKey:@"category"];
	
	if (self.imageDescription.length > 0)
		[dict setValue:self.imageDescription forKey:@"description"];
	
	if (self.title.length > 0)
		[dict setValue:self.title forKey:@"name"];

	if (self.lens.length > 0)
		[dict setValue:self.lens forKey:@"lens"];
	
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
