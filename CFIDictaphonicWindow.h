//
//  CFIDictaphonicWindow.h
//  CFIDictaphonicsExample
//
//  Created by Robert Widmann on 2/21/13.
//  Copyright (c) 2013 CodaFi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 * Sent when the window can start dictation, which occurs when all known text fields have given
 * given up first responder status.  Attempting to activate dictation before this notification is
 * sent will be met with either failure or dictation will start in a different text field.
 */
extern NSString *const CFIDictaphonicWindowCanStartDictation;

/*
 * Sent when the window has ended its opportunity for dictation by resigning it's internal dictation 
 * field.
 */
extern NSString *const CFIDictaphonicWindowDidMakeDictationFieldResign;

/*
 * Sent when the window has recognized a command that was dictated.  Use the @"Command" key on the
 * notification's -userInfo field to get the command that was spoken.
 */
extern NSString *const CFIDictaphonicWindowDidRecognizeCommand;

/*
 * Sent when the window has failed to recognized a command that was dictated.  Use the @"Command" 
 * key on the notification's -userInfo field to get the command that was spoken.
 */
extern NSString *const CFIDictaphonicWindowDidNotRecognizeCommand;


@interface CFIDictaphonicWindow : NSWindow

/*
 * The map of command blocks to given commands.
 */
@property (nonatomic, strong, readonly) NSMutableDictionary *commandMap;

/*
 * Maps a command block to a given command.  Commands are lowercase'd before being added to the 
 * commandMap dictionary for the maximum possibility of matches to a given command.
 * 
 * @param commandBlock The block that will be invoked when the given command has been recognized.
 * @param command The command associated with the given command block.
 */
- (void)enqueueBlock:(void(^)(NSString *command))commandBlock forCommand:(NSString*)command;
- (void)forceDictation DEPRECATED_ATTRIBUTE;

@end
