//
//  CFIAppDelegate.h
//  CFIDictaphonicsExample
//
//  Created by Robert Widmann on 2/21/13.
//  Copyright (c) 2013 CodaFi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CFIDictaphonicWindow;

@interface CFIAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet CFIDictaphonicWindow *window;
@property (assign) IBOutlet NSTextField *textField;
@property (assign) IBOutlet NSTextField *statusField;


-(IBAction)resignResponders:(id)sender;

@end
