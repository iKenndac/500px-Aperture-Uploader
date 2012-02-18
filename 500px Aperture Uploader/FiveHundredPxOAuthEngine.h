//
//  FiveHundredPxOAuthEngine.h
//  Demo
//
//  Created by Daniel Kennett on 17/02/2012.
//  Copyright (c) 2012 KennettNet Software Limited. All rights reserved.
//

#import "RSOAuthEngine.h"

@protocol FiveHundredPxEngineDelegate;

typedef void (^FiveHundredPxCompletionBlock)(NSError *error);
typedef void (^FiveHundredPxCompletionWithValueBlock)(NSDictionary *returnValue, NSError *error);

@interface FiveHundredPxOAuthEngine : RSOAuthEngine

@property (assign, nonatomic, readwrite) __unsafe_unretained id <FiveHundredPxEngineDelegate> delegate;
@property (strong, readonly, nonatomic) NSString *screenName;
@property (readonly, nonatomic, strong) MKNetworkEngine *fileUploadEngine;

- (id)initWithDelegate:(id <FiveHundredPxEngineDelegate>)delegate;
- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password;
- (void)authenticateWithCompletionBlock:(FiveHundredPxCompletionBlock)completionBlock;
- (void)cancelAuthentication;
- (void)forgetStoredToken;

-(void)getPhotosForLoggedInUser:(FiveHundredPxCompletionWithValueBlock)block;
-(void)getDetailsForLoggedInUser:(FiveHundredPxCompletionWithValueBlock)block;
-(void)uploadPhoto:(NSData *)jpgData withTitle:(NSString *)title description:(NSString *)desc uploadProgressBlock:(MKNKProgressBlock)progressBlock completionBlock:(FiveHundredPxCompletionWithValueBlock)block;
@end

@protocol FiveHundredPxEngineDelegate <NSObject>

- (void)fiveHundredPxNeedsAuthentication:(FiveHundredPxOAuthEngine *)engine;
- (void)fiveHundredPx:(FiveHundredPxOAuthEngine *)engine statusUpdate:(NSString *)message;


@end