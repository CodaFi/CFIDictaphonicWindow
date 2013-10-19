
//  CFIDictaphonicWindow.m    CFIDictaphonicsExample
//  Created by Robert Widmann on 2/21/13.  Copyright (c) 2013 CodaFi. All rights reserved.

#import "CFIDictaphonicWindow.h"

#define START_BITMASK_SWITCH(x) for (uint64_t bit = 1; x >= bit; bit *= 2) if (x & bit) switch (bit)
#define CFIDictaphonicTextDidChange @"CFIDictaphonicTextDidChange"

@interface 				  CFIDictationField : NSControl <NSTextInputClient>
@property (nonatomic) NSTextInputContext * inputContext;							@end

@implementation CFIDictationField

-   (id) initWithFrame:(NSRect)frame	{    if (self != [super initWithFrame:frame]) return nil;
	_inputContext 							= [NSTextInputContext.alloc initWithClient:self];
	_inputContext.acceptsGlyphInfo 	= NO;
	return self;
}
- (void) doCommandBySelector:(SEL)sel 	{ [super doCommandBySelector:sel];  /*NSResponder's implementation is OK*/ }

- (void) insertText:(id)aString 				replacementRange:(NSRange)replacementRange 							{
	
	[NSNotificationCenter.defaultCenter postNotificationName:CFIDictaphonicTextDidChange 
																	  object:self userInfo:@{@"Command" : aString}];
}
- (NSAttributedString*)attributedSubstringForProposedRange:(NSRange)p  actualRange:(NSRangePointer)a 		{ return nil; }
- (void) setMarkedText:(id)txt 			      selectedRange:(NSRange)selR replacementRange:(NSRange)repR 	{	return; }
- (void) unmarkText 				{ return; 							}
- (BOOL) hasMarkedText 			{ return NO; 						}
-    (NSRange) markedRange 	{ return NSMakeRange(0, 0); 	}
-    (NSRange) selectedRange 	{ return NSMakeRange(0, 0);   }
-     (NSRect) firstRectForCharacterRange:	(NSRange)theRange actualRange:(NSRangePointer)actualRange{

	NSRect rect = [self convertRect:NSZeroRect toView:nil];
	rect.origin = [self.window convertBaseToScreen:rect.origin];
	return rect;
}
- (NSUInteger) characterIndexForPoint:			(NSPoint)thePoint { 	return 0; }
-   (NSArray*) validAttributesForMarkedText 	{ 	return @[]; }

- (void) keyDown:			(NSEvent*)e {	NSLog(@"%lu", (unsigned long)e.modifierFlags); 	//Do nothing, only inputs should be from Dictation
}
- (void) mouseDown:		(NSEvent*)e { [self.inputContext handleEvent:e]; }
- (void) mouseDragged:	(NSEvent*)e { [self.inputContext handleEvent:e]; }
- (void) mouseUp:			(NSEvent*)e { [self.inputContext handleEvent:e]; }
- (void) drawRect:(NSRect)dirtyRect { [NSColor.purpleColor set]; NSRectFill(dirtyRect); }
@end

@interface CFIDictaphonicWindow ()
@property (nonatomic) NSMutableDictionary *commandMap;
@property (nonatomic) CFIDictationField *dummyField;
@end

@implementation CFIDictaphonicWindow

#pragma mark - Lifecycle

- (id)init {
	self = [super init];
	_commandMap = @{}.mutableCopy;
	[self awakeFromNib];
	return self;
}
- (id)initWithCoder:		  (NSCoder*)aDecoder {
	self = [super initWithCoder:aDecoder];
	_commandMap = @{}.mutableCopy;
	return self;
}
- (id)initWithContentRect:(NSRect)contentRect  styleMask:(NSUInteger)aStyle 
						backing:(NSBackingStoreType)buff defer:(BOOL)flag 									{
	self = [super initWithContentRect:contentRect styleMask:aStyle backing:buff defer:flag];
	_commandMap = @{}.mutableCopy;
	[self awakeFromNib];
	return self;
}
- (id)initWithContentRect:(NSRect)contentRect  styleMask:(NSUInteger)aStyle 
						backing:(NSBackingStoreType)buff defer:(BOOL)flag screen:(NSScreen*)screen {
	self = [super initWithContentRect:contentRect styleMask:aStyle backing:buff defer:flag screen:screen];
	_commandMap = @{}.mutableCopy;
	[self awakeFromNib];
	return self;
}
- (void) awakeFromNib 	{

	CGFloat titleHeight 	=  [self.contentView superview].frame.size.height - [self.contentView frame].size.height;	
	NSRect dRect 			= (NSRect){NSWidth(self.frame)-10, NSHeight([self.contentView frame]), 10, titleHeight };

	[[self.contentView superview] addSubview:_dummyField 	= [CFIDictationField.alloc initWithFrame:dRect]];
	_dummyField.refusesFirstResponder 	= YES;
	_dummyField.autoresizingMask 			= NSViewMinXMargin|NSViewMaxXMargin|NSViewMinYMargin;
	
	[NSNotificationCenter.defaultCenter addObserverForName:CFIDictaphonicTextDidChange 		  object:self.dummyField 
																	 queue:NSOperationQueue.currentQueue usingBlock:^(NSNotification *note) {
		[self handleCommand:note.userInfo[@"Command"]];
	}];

	CALayer *l; [self.contentView setLayer:l = CALayer.new]; [self.contentView setWantsLayer:YES];  // Just for effect!
	[_commandMapController bind:NSContentDictionaryBinding toObject:self withKeyPath:@"commandMap" options:nil]; // In carge of the table view.
}
- (void) dealloc 			{ [NSNotificationCenter.defaultCenter removeObserver:self]; }

#pragma mark - NSResponder Intercepting

- (BOOL) makeFirstResponder:(NSResponder *)aResponder {
	[self delayedCheckResponders];
	return [super makeFirstResponder:aResponder];
}
- (void) delayedCheckResponders 	{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkResponders) object:nil];
	[self performSelector:@selector(checkResponders) withObject:nil afterDelay:0];
}
- (void) checkResponders 			{

		[self.firstResponder isKindOfClass:self.class] ? ^{ 	
		
			_dummyField.refusesFirstResponder = NO; [self makeFirstResponder:_dummyField];

}() : [self.firstResponder isKindOfClass:_dummyField.class] ?

			[NSNotificationCenter.defaultCenter postNotificationName:CFIDictaphonicWindowCanStartDictation 
																			  object:self]
	 : ^{																		
			_dummyField.refusesFirstResponder = YES;
			[NSNotificationCenter.defaultCenter postNotificationName:CFIDictaphonicWindowDidMakeDictationFieldResign 
																		  object:self];
	}();
}

#pragma mark - Command Handling

- (void) handleCommand:(NSString*)command {  CommandBlock commandBlock; 

	BOOL yeaNea = (commandBlock = _commandMap[command.lowercaseString][@"command"]) != nil;

	yeaNea ? commandBlock(command) : nil;
	yeaNea ? ^{ 	NSUInteger x = [[_commandMapController.arrangedObjects valueForKey:@"key"] 
																		  indexOfObject:command.lowercaseString];

		[_commandMapController setSelectionIndex:x];  }() : (void)nil;
	[self animationForRecognized:yeaNea];
	[NSNotificationCenter.defaultCenter postNotificationName: yeaNea ? CFIDictaphonicWindowDidRecognizeCommand 
																						  : CFIDictaphonicWindowDidNotRecognizeCommand  
																	  object:self 
																  userInfo: @{@"Command" : command.lowercaseString}];
}
- (void) enqueueBlock: (CommandBlock)comBlk forCommand:(NSString*)com description:(NSString*)d {

	NSParameterAssert(com);
	id newObject = _commandMapController.newObject;
	[newObject setKey:com.lowercaseString]; 	// Use NSDictionaryControllerKeyValuePair Protocol setKey 
	[newObject setValue:@{@"command":[comBlk copy],@"description":d}];	// Use Protocol setValue
	[self.commandMapController addObject:newObject];	// Add the object to the controller
}

#pragma mark - UI

- (void) forceDictation 						{	[self makeFirstResponder:nil];
	[NSApp  performSelector:@selector(startDictation:) withObject:_dummyField afterDelay:0.1];
}
- (void) animationForRecognized:(BOOL)yea {  // does a  little flashing number, based on if you got a match

	CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"backgroundColor"];
	NSMutableArray *a = NSMutableArray.new, *times = NSMutableArray.new; float index;
	CGColorRef c = yea ? NSColor.greenColor.CGColor : NSColor.redColor.CGColor;
	for (index = 0; index < 7; ++index){
		[a addObject:(int)floor(index) % 2 ? (id)NSColor.blackColor.CGColor : (__bridge id)c];
		[times addObject:@(index * (1/6.0))];
	}
	shakeAnimation.values 	= a;
	shakeAnimation.keyTimes = times;
	shakeAnimation.duration = .7;
	shakeAnimation.removedOnCompletion = YES;
	[[self.contentView layer] addAnimation:shakeAnimation forKey:nil];
}

@end
