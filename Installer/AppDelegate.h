//
//  AppDelegate.h
//  Installer
//
//  Created by Daniel Kennett on 13/03/2012.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSImageView *imageView;
@property (weak) IBOutlet NSTextField *headerTextField;

- (IBAction)performInstallation:(id)sender;

-(void)presentError:(NSError *)error;

@end
