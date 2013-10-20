//
//  CFIAppDelegate.m
//  CFIDictaphonicsExample
//
//  Created by Robert Widmann on 2/21/13.
//  Copyright (c) 2013 CodaFi. All rights reserved.
//  Released under the MIT license.
//

#import "CFIAppDelegate.h"
#import "CFIDictaphonicWindow.h"

@implementation CFIAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
}

- (void)awakeFromNib {
	[self.window enqueueBlock:^(NSString *command){
		[self doTextyStuff:command];
	} forCommand:@"Text"];
	[self.window enqueueBlock:^(NSString *command){
		[self doTextyStuff:command];
	} forCommand:@"Red"];
	[self.window enqueueBlock:^(NSString *command){
		[self doTextyStuff:command];
	} forCommand:@"Blue"];
	[self.window enqueueBlock:^(NSString *command){
		[self doTextyStuff:command];
	} forCommand:@"Firetruck"];
	[self.window enqueueBlock:^(NSString *command){
		[self doTextyStuff:command];
	} forCommand:@"Test"];
	[self.window enqueueBlock:^(NSString *command){
		[self doTextyStuff:command];
	} forCommand:@"Balloon"];
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateWithCanSpeak) name:CFIDictaphonicWindowCanStartDictation object:nil];
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateWithCannotSpeak) name:CFIDictaphonicWindowDidMakeDictationFieldResign object:nil];
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateWithDidNotRecognize:) name:CFIDictaphonicWindowDidNotRecognizeCommand object:nil];

}

-(IBAction)resignResponders:(id)sender {
	[self.window makeFirstResponder:nil];
	[self.window startDictation];
}

- (void)doTextyStuff:(NSString*)command {
	[self.statusField setStringValue:[NSString stringWithFormat:@"Command recognized!  You said: %@", command]];
}

- (void)updateWithCanSpeak {
	[self.statusField setStringValue:@"Dictations is available!\n Activate dictation now."];
}

- (void)updateWithCannotSpeak {
	[self.statusField setStringValue:@"Other text fields are designated first responders. \
	 Please resign them to use Dictation"];
}

- (void)updateWithDidNotRecognize:(NSNotification*)commandNotif {
	NSString *command = commandNotif.userInfo[@"Command"];
	[self.statusField setStringValue:[NSString stringWithFormat:@"Command not recognized!  We thought you said: %@", command]];
}

@end
