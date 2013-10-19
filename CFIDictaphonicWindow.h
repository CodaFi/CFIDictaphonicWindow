
//  CFIDictaphonicWindow.h  CFIDictaphonicsExample
//  Created by Robert Widmann on 2/21/13.  Copyright (c) 2013 CodaFi. All rights reserved.

typedef void(^CommandBlock)(NSString *command);
/*!
 * Sent when the window can start dictation, which occurs when all known text fields have given
 * given up first responder status.  Attempting to activate dictation before this notification is
 * sent will be met with either failure or dictation will start in a different text field.
 */
#define CFIDictaphonicWindowCanStartDictation @"CFIDictaphonicWindowCanStartDictation"
/*!
 * Sent when the window has ended its opportunity for dictation by resigning it's internal dictation 
 * field.
 */
#define CFIDictaphonicWindowDidMakeDictationFieldResign @"CFIDictaphonicWindowDidMakeDictationFieldResign"
/*!
 * Sent when the window has recognized a command that was dictated.  Use the @"Command" key on the
 * notification's -userInfo field to get the command that was spoken.
 */
#define CFIDictaphonicWindowDidRecognizeCommand @"CFIDictaphonicWindowDidRecognizeCommand"
/*!
 * Sent when the window has failed to recognized a command that was dictated.  Use the @"Command" 
 * key on the notification's -userInfo field to get the command that was spoken.
 */
#define CFIDictaphonicWindowDidNotRecognizeCommand @"CFIDictaphonicWindowDidNotRecognizeCommand"

@interface CFIDictaphonicWindow : NSWindow
/*!
 * The map of command blocks to given commands.
 */
@property (readonly) 		    NSMutableDictionary * commandMap;
@property (assign) IBOutlet NSDictionaryController * commandMapController;
/*!
 * Maps a command block to a given command.  Commands are lowercase'd before being added to the 
 * commandMap dictionary for the maximum possibility of matches to a given command.
 * @param commandBlock The block that will be invoked when the given command has been recognized.
 * @param command The command associated with the given command block.
 */
- (void)enqueueBlock:(CommandBlock)comBlk forCommand:(NSString*)com description:(NSString*)d;
/*!
 * Forces the window to activate dictation by resigning all first responders.
 */
- (void)forceDictation;

@end


