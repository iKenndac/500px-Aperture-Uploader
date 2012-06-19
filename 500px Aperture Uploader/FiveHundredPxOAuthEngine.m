//
//  FiveHundredPxOAuthEngine.m
//  Demo
//
//  Created by Daniel Kennett on 17/02/2012.
//  For license information, see LICENSE.markdown
//

// Note: This file is basically a copy+paste of the Instapaper 
// demo project that comes with RSOAuthEngine.

#import "FiveHundredPxApertureExporter.h"
#import "FiveHundredPxOAuthEngine.h"
#import "CJSONDeserializer.h"
#import "Constants.h"

@interface FiveHundredPxOAuthEngine ()

- (void)removeOAuthTokenFromKeychain;
- (void)storeOAuthTokenInKeychain;
- (void)retrieveOAuthTokenFromKeychain;

@property (readwrite, nonatomic, strong) FiveHundredPxCompletionBlock completionBlock;
@property (strong, readwrite, nonatomic) NSString *screenName;
@property (readwrite, nonatomic, strong) MKNetworkEngine *fileUploadEngine;

@property (readwrite, nonatomic, getter = isWorking) BOOL working;

@end

@implementation FiveHundredPxOAuthEngine

NSString *k500pxConsumerKey;
NSString *k500pxConsumerSecret;

// Default hostname and paths
static NSString * const k500pxHostname = @"api.500px.com";
static NSString * const k500pxUploadHostname = @"upload.500px.com";
static NSString * const k500pxGetAccessTokenPath = @"v1/oauth/access_token";
static NSString * const k500pxGetRequestTokenPath = @"v1/oauth/request_token";
static NSString * const k500pxGetPhotosPath = @"v1/photos";
static NSString * const k500pxGetUserDetailsPath = @"v1/users";
static NSString * const k500pxPostPhotoPath = @"v1/photos";
static NSString * const k500pxUploadPhotoPath = @"api/v1/upload";
static NSString * const k500pxPostPhotoTagsPath = @"v1/photos/%@/tags";

#pragma mark - Initialization

- (id)initWithDelegate:(id <FiveHundredPxEngineDelegate>)del
{
    self = [super initWithHostName:k500pxHostname
                customHeaderFields:nil
                   signatureMethod:RSOAuthHMAC_SHA1
                       consumerKey:k500pxConsumerKey
                    consumerSecret:k500pxConsumerSecret
					   callbackURL:@"http://authLocal/auth"];
    
    if (self) {
        self.delegate = del;
		self.fileUploadEngine = [[MKNetworkEngine alloc] initWithHostName:k500pxUploadHostname
													   customHeaderFields:nil];
        
        // Retrieve OAuth access token (if previously stored)
        [self retrieveOAuthTokenFromKeychain];
    }
    
    return self;
}

@synthesize completionBlock;
@synthesize screenName;
@synthesize delegate;
@synthesize fileUploadEngine;
@synthesize working;

#pragma mark - OAuth Access Token store/retrieve

- (void)removeOAuthTokenFromKeychain
{
    // Build the keychain query
    NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          (__bridge_transfer NSString *)kSecClassGenericPassword, (__bridge_transfer NSString *)kSecClass,
                                          self.consumerKey, kSecAttrService,
                                          self.consumerKey, kSecAttrAccount,
                                          kCFBooleanTrue, kSecReturnAttributes,
                                          nil];
    
    // If there's a token stored for this user, delete it
    SecItemDelete((__bridge_retained CFDictionaryRef) keychainQuery);
}

- (void)storeOAuthTokenInKeychain
{
    // Build the keychain query
    NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          (__bridge_transfer NSString *)kSecClassGenericPassword, (__bridge_transfer NSString *)kSecClass,
                                          self.consumerKey, kSecAttrService,
                                          self.consumerKey, kSecAttrAccount,
                                          kCFBooleanTrue, kSecReturnAttributes,
                                          nil];
    
    CFTypeRef resData = NULL;
    
    // If there's a token stored for this user, delete it first
    SecItemDelete((__bridge_retained CFDictionaryRef) keychainQuery);
    
    // Build the token dictionary
    NSMutableDictionary *tokenDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            self.token, @"oauth_token",
                                            self.tokenSecret, @"oauth_token_secret",
                                            self.screenName, @"screen_name",
                                            nil];
    
    // Add the token dictionary to the query
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:tokenDictionary] 
                      forKey:(__bridge_transfer NSString *)kSecValueData];
    
    // Add the token data to the keychain
    // Even if we never use resData, replacing with NULL in the call throws EXC_BAD_ACCESS
    SecItemAdd((__bridge_retained CFDictionaryRef)keychainQuery, (CFTypeRef *) &resData);
}

- (void)retrieveOAuthTokenFromKeychain
{
    // Build the keychain query
    NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          (__bridge_transfer NSString *)kSecClassGenericPassword, (__bridge_transfer NSString *)kSecClass,
                                          self.consumerKey, kSecAttrService,
                                          self.consumerKey, kSecAttrAccount,
                                          kCFBooleanTrue, kSecReturnData,
                                          kSecMatchLimitOne, kSecMatchLimit,
                                          nil];
    
    // Get the token data from the keychain
    CFTypeRef resData = NULL;
    
    // Get the token dictionary from the keychain
    if (SecItemCopyMatching((__bridge_retained CFDictionaryRef) keychainQuery, (CFTypeRef *) &resData) == noErr)
    {
        NSData *resultData = (__bridge_transfer NSData *)resData;
        
        if (resultData)
        {
            NSMutableDictionary *tokenDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:resultData];
            
            if (tokenDictionary) {
                [self setAccessToken:[tokenDictionary objectForKey:@"oauth_token"]
                              secret:[tokenDictionary objectForKey:@"oauth_token_secret"]];
                
                self.screenName = [tokenDictionary objectForKey:@"screen_name"];
            }
        }
    }
}

#pragma mark - OAuth Authentication Flow

- (void)authenticateWithCompletionBlock:(FiveHundredPxCompletionBlock)block
{
    // First we reset the OAuth token, so we won't send previous tokens in the request
    [self resetOAuthToken];
    
    // Store the Completion Block to call after Authenticated
    self.completionBlock = [block copy];
    
    [self.delegate fiveHundredPx:self statusUpdate:DKLocalizedStringForClass(@"waiting for auth title")];
    [self.delegate fiveHundredPxNeedsAuthentication:self];
}

- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password
{
	
    // Fill the post body with the xAuth parameters
    NSMutableDictionary *postParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       username, @"x_auth_username",
                                       password, @"x_auth_password",
                                       @"client_auth", @"x_auth_mode",
                                       nil];
	
	MKNetworkOperation *requestTokenOp = [self operationWithPath:k500pxGetRequestTokenPath
														  params:nil
													  httpMethod:@"POST"
															 ssl:YES];
    
    [requestTokenOp onCompletion:^(MKNetworkOperation *completedOperation)
	 {
		 [self fillTokenWithResponseBody:completedOperation.responseString type:RSOAuthAccessToken];	 
		 
		 // Now, request PW
		 MKNetworkOperation *op = [self operationWithPath:k500pxGetAccessTokenPath
												   params:postParams
											   httpMethod:@"POST"
													  ssl:YES];
		 
		 [op onCompletion:^(MKNetworkOperation *completedOperation)
		  {
			  // Fill the access token with the returned data
			  [self fillTokenWithResponseBody:[completedOperation responseString] type:RSOAuthAccessToken];
			  
			  // Set the user's screen name
			  self.screenName = [username copy];
			  
			  // Store the OAuth access token
			  [self storeOAuthTokenInKeychain];
			  
			  self.working = NO;
			  
			  // Finished, return to previous method
			  if (self.completionBlock) self.completionBlock(nil);
			  self.completionBlock = nil;
		  } 
				  onError:^(NSError *error)
		  {
			  if (error.code != NSURLErrorNotConnectedToInternet && error.code != NSURLErrorNetworkConnectionLost) {
				  [self resetOAuthToken];
				  self.screenName = nil;
			  }
			  self.working = NO;
			  if (self.completionBlock) self.completionBlock(error);
			  self.completionBlock = nil;
		  }];
		 
		 [self.delegate fiveHundredPx:self statusUpdate:DKLocalizedStringForClass(@"authenticating title")];
		 [self enqueueSignedOperation:op];
		 
	 } 
		onError:^(NSError *error)
	 {
		 if (error.code != NSURLErrorNotConnectedToInternet && error.code != NSURLErrorNetworkConnectionLost) {
			 [self resetOAuthToken];
			 self.screenName = nil;
		 }
		 self.working = NO;
		 if (self.completionBlock) self.completionBlock(error);
		 self.completionBlock = nil;
	 }];
	
	[self enqueueSignedOperation:requestTokenOp];
	self.working = YES;
    
}

- (void)cancelAuthentication
{
    NSDictionary *ui = [NSDictionary dictionaryWithObjectsAndKeys:DKLocalizedStringForClass(@"auth cancelled title"), NSLocalizedDescriptionKey, nil];
    NSError *error = [NSError errorWithDomain:@"org.danielkennett.500px.ErrorDomain" code:401 userInfo:ui];
    
    if (self.completionBlock) self.completionBlock(error);
    self.completionBlock = nil;
}

- (void)forgetStoredToken
{
    [self removeOAuthTokenFromKeychain];
    [self resetOAuthToken];
    self.screenName = nil;
}

#pragma mark - Public Methods

-(void)performAuthenticatedRequestToPath:(NSString *)path
							  parameters:(NSMutableDictionary *)parameters
								  method:(NSString *)httpMethod 
						   callbackBlock:(FiveHundredPxCompletionWithValueBlock)block {

	
	if (!self.isAuthenticated) {
		
		[self authenticateWithCompletionBlock:^(NSError *error) {
            if (error) {
                // Authentication failed, return the error
                block(nil, error);
            } else {
                // Authentication succeeded, call this method again
                [self performAuthenticatedRequestToPath:path
											 parameters:parameters
												 method:httpMethod
										  callbackBlock:block];
            }
        }];
        
        // This method will be called again once the authentication completes
        return;
	}
	
	MKNetworkOperation *op = [self operationWithPath:path
                                              params:parameters
                                          httpMethod:httpMethod
                                                 ssl:YES];
    
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
		self.working = NO;
		NSDictionary *dict = [[CJSONDeserializer deserializer] deserializeAsDictionary:completedOperation.responseData
																				 error:nil];
        block(dict, nil);
    } onError:^(NSError *error) {
		self.working = NO;
        block(nil, error);
    }];
    
    [self enqueueSignedOperation:op];
	self.working = YES;
}

-(void)setTags:(NSArray *)tags forPhotoWithId:(NSString *)photoId completionBlock:(FiveHundredPxCompletionWithValueBlock)block {
	
	NSMutableDictionary *postParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									   [tags componentsJoinedByString:@","], @"tags",
									   nil];
	
	[self performAuthenticatedRequestToPath:[NSString stringWithFormat:k500pxPostPhotoTagsPath, photoId]
								 parameters:postParams
									 method:@"POST"
							  callbackBlock:block];
}

-(void)getPhotosForLoggedInUser:(FiveHundredPxCompletionWithValueBlock)block {
	
	NSMutableDictionary *postParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       self.screenName, @"username",
                                       @"user", @"feature",
									   self.consumerKey, @"consumer_key",
                                       nil];
	
	[self performAuthenticatedRequestToPath:k500pxGetPhotosPath
								 parameters:postParams
									 method:@"GET"
							  callbackBlock:block];
}

-(void)getDetailsForLoggedInUser:(FiveHundredPxCompletionWithValueBlock)block {
	
	[self performAuthenticatedRequestToPath:k500pxGetUserDetailsPath
								 parameters:nil
									 method:@"GET"
							  callbackBlock:block];
}

-(void)uploadPhoto:(NSData *)jpgData withMetaData:(NSDictionary *)metaData uploadProgressBlock:(MKNKProgressBlock)progressBlock completionBlock:(FiveHundredPxCompletionWithValueBlock)block {
	
	[self performAuthenticatedRequestToPath:k500pxPostPhotoPath
								 parameters:[metaData mutableCopy] // Why on earth does this take a mutable dictionary?!
									 method:@"POST"
							  callbackBlock:^(NSDictionary *returnValue, NSError *error) {
								  
								  if (error == nil) {
									  
									  NSString *photoId = [[[returnValue valueForKey:@"photo"] valueForKey:@"id"] stringValue];
									  NSString *uploadKey = [returnValue valueForKey:@"upload_key"];
									  
									  NSMutableDictionary *postParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:
																		 photoId, @"photo_id",
																		 self.consumerKey, @"consumer_key",
																		 self.token, @"access_key",
																		 uploadKey, @"upload_key",
																		 nil];
									  
									  MKNetworkOperation *op = [self.fileUploadEngine operationWithPath:k500pxUploadPhotoPath
																								 params:postParams
																							 httpMethod:@"POST"
																									ssl:NO];
									  [op addData:jpgData
										   forKey:@"file"];
									  
									  [op onCompletion:^(MKNetworkOperation *completedOperation) {
										  // The response from the upload call is actually pretty useless - give back from the first call instead
										  block(returnValue, nil);
									  } onError:^(NSError *error) {
										  block(nil, error);
									  }];
									  
									  [op onUploadProgressChanged:progressBlock];
									  
									  [self.fileUploadEngine enqueueOperation:op];
									  
								  } else {
									  block(nil, error);
								  }
							  }];
	
}

@end
