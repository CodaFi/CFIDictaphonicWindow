//
//  CFIAppDelegate.m
//  CFIDictaphonicsExample
//
//  Created by Robert Widmann on 2/21/13.
//  Copyright (c) 2013 CodaFi. All rights reserved.
//

#import "CFIAppDelegate.h"
#import "CFIDictaphonicWindow.h"

@implementation CFIAppDelegate

-     (void) applicationDidBecomeActive:(NSNotification *)note {

	NSArray  *verbs = [VERBS componentsSeparatedByString:@","],
				*words = [WORDS componentsSeparatedByString:@" "],
	*__unused names = [[[NSString stringWithContentsOfFile:@"/usr/share/dict/propernames" usedEncoding:NULL error:NULL] 
							componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]
										sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]; 

	for (int i = 0; i < 100; i++) {
		NSString *fragment = [NSString stringWithFormat:@"Please %@ my %@",
		verbs[arc4random() % verbs.count],	words[arc4random() % words.count]];
		[self.window enqueueBlock:^(NSString *command){ [self doTextyStuff:command]; } forCommand:fragment description:fragment];
	}
	
	[@{ 	CFIDictaphonicWindowCanStartDictation:
				@"Dictations is available!\n Activate dictation now.",
			CFIDictaphonicWindowDidMakeDictationFieldResign :
			 	_statusField.stringValue = @"Other text fields are designated first responders.\nPlease resign them to use Dictation",
			CFIDictaphonicWindowDidNotRecognizeCommand : 
				@"Command not recognized!  We thought you said: %@"}
					enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
	
		[NSNotificationCenter.defaultCenter addObserverForName:key object:nil 
																		 queue:NSOperationQueue.mainQueue  
																  usingBlock:^(NSNotification *note) {

		_statusField.stringValue = [obj rangeOfString:@"%@"].location == NSNotFound  
										 ?  obj : [NSString stringWithFormat:obj, note.userInfo[@"Command"]];
		}];
	}];

}

- (IBAction) resignResponders:(id)sender { [_window makeFirstResponder:nil]; [_window forceDictation]; }

-	   (void) doTextyStuff:(NSString*)command {

	_statusField.stringValue = [NSString stringWithFormat:@"Command recognized!  You said: %@", command];
}

@end

int main(int argc, char *argv[])	{ return NSApplicationMain(argc, (const char **)argv); }

