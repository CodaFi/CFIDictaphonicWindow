//
//  CFIAppDelegate.h
//  CFIDictaphonicsExample
//
//  Created by Robert Widmann on 2/21/13.
//  Copyright (c) 2013 CodaFi. All rights reserved.
//

@class					  CFIDictaphonicWindow ;
@interface 								 CFIAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet CFIDictaphonicWindow * window;
@property (assign) IBOutlet 			 NSTextField * textField, 
																 * statusField;

- (IBAction) resignResponders:(id)x;

@end
