//
//  CFIDictaphonicWindow.m
//  CFIDictaphonicsExample
//
//  Created by Robert Widmann on 2/21/13.
//  Copyright (c) 2013 CodaFi. All rights reserved.
//

#import "CFIDictaphonicWindow.h"

#define START_BITMASK_SWITCH(x) \
for (uint64_t bit = 1; x >= bit; bit *= 2) if (x & bit) switch (bit)

NSString *const CFIDictaphonicWindowCanStartDictation = @"CFIDictaphonicWindowCanStartDictation";
NSString *const CFIDictaphonicWindowDidMakeDictationFieldResign = @"CFIDictaphonicWindowDidMakeDictationFieldResign";
NSString *const CFIDictaphonicWindowDidRecognizeCommand = @"CFIDictaphonicWindowDidRecognizeCommand";
NSString *const CFIDictaphonicWindowDidNotRecognizeCommand = @"CFIDictaphonicWindowDidNotRecognizeCommand";
NSString *const CFIDictaphonicTextDidChange = @"CFIDictaphonicTextDidChange";

@interface CFIDictationField : NSControl <NSTextInputClient>
@property (nonatomic, strong) NSTextInputContext *inputContext;
@end

@implementation CFIDictationField {
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		self.inputContext = [[NSTextInputContext alloc] initWithClient:self];
        self.inputContext.acceptsGlyphInfo = NO;
    }
    
    return self;
}

- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange {
	[[NSNotificationCenter defaultCenter]postNotificationName:CFIDictaphonicTextDidChange object:self userInfo:@{@"Command" : aString}];
}

- (NSAttributedString*)attributedSubstringForProposedRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange {
	return nil;
}

- (void) doCommandBySelector:(SEL)aSelector {
    [super doCommandBySelector:aSelector]; // NSResponder's implementation will do nicely
}

- (void)setMarkedText:(id)aString selectedRange:(NSRange)selectedRange replacementRange:(NSRange)replacementRange {
	return;
}

- (void) unmarkText {
	return;
}

- (BOOL) hasMarkedText {
	return NO;
}
- (NSRange) markedRange {
	return NSMakeRange(0, 0);
}

- (NSRange) selectedRange {
	return NSMakeRange(0, 0);
}

- (NSRect) firstRectForCharacterRange:(NSRange)theRange actualRange:(NSRangePointer)actualRange{
	NSRect rect = [self convertRect:NSZeroRect toView:nil];
	rect.origin = [[self window] convertBaseToScreen:rect.origin];
	return rect;
}

- (NSUInteger)characterIndexForPoint:(NSPoint)thePoint {
	return 0;
}

- (NSArray*) validAttributesForMarkedText {
	return @[];
}

- (void)keyDown:(NSEvent *)theEvent {
	//Do nothing, only inputs should be from Dictation
	NSLog(@"%lu", (unsigned long)theEvent.modifierFlags);
}


- (void)mouseDown:(NSEvent *)theEvent {
	[self.inputContext handleEvent:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent {
	[self.inputContext handleEvent:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent {
	[self.inputContext handleEvent:theEvent];
}


- (void)drawRect:(NSRect)dirtyRect {}

@end

@interface CFIDictaphonicWindow ()
@property (nonatomic, strong) NSMutableDictionary *commandMap;
@property (nonatomic, strong) CFIDictationField *dummyField;
@end

@implementation CFIDictaphonicWindow

#pragma mark - Lifecycle

- (id)init {
	self = [super init];
	self.commandMap = @{}.mutableCopy;
	[self awakeFromNib];
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	self.commandMap = @{}.mutableCopy;
	return self;
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
	self.commandMap = @{}.mutableCopy;
	[self awakeFromNib];
	return self;
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag screen:(NSScreen *)screen {
	self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag screen:screen];
	self.commandMap = @{}.mutableCopy;
	[self awakeFromNib];
	return self;
}

- (void) awakeFromNib {
	self.dummyField = [[CFIDictationField alloc] initWithFrame:NSMakeRect(NSWidth(self.frame)/2, NSHeight([self.contentView frame]), 10, [self titleBarHeight])];
	self.dummyField.refusesFirstResponder = YES;
	[self.dummyField setAutoresizingMask:(NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin)];
	[[[self contentView] superview] addSubview:self.dummyField];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:CFIDictaphonicTextDidChange object:self.dummyField queue:[NSOperationQueue currentQueue] usingBlock: ^(NSNotification *note) {
		[self handleCommand:note.userInfo[@"Command"]];
	}];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark - NSResponder Intercepting

- (BOOL) makeFirstResponder:(NSResponder *)aResponder {
	[self delayedCheckResponders];
	return [super makeFirstResponder:aResponder];
}

- (void) delayedCheckResponders {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkResponders) object:nil];
	[self performSelector:@selector(checkResponders) withObject:nil afterDelay:0];
}

- (void) checkResponders {
	if ([self.firstResponder isKindOfClass:[self class]]) {
		self.dummyField.refusesFirstResponder = NO;
		[self makeFirstResponder:self.dummyField];
	} else if ([self.firstResponder isKindOfClass:[self.dummyField class]]) {
		[[NSNotificationCenter defaultCenter]postNotificationName:CFIDictaphonicWindowCanStartDictation object:self];
	}
	else {
		self.dummyField.refusesFirstResponder = YES;
		[[NSNotificationCenter defaultCenter]postNotificationName:CFIDictaphonicWindowDidMakeDictationFieldResign object:self];
	}
}

#pragma mark - Command Handling

- (void) handleCommand:(NSString*)command {
	void (^commandBlock)(NSString *commandStr) = [self.commandMap objectForKey:command.lowercaseString];
	if (commandBlock != nil) {
		commandBlock(command);
		[[NSNotificationCenter defaultCenter]postNotificationName:CFIDictaphonicWindowDidRecognizeCommand object:self userInfo:@{@"Command" : command.lowercaseString}];
	} else {
		[[NSNotificationCenter defaultCenter]postNotificationName:CFIDictaphonicWindowDidNotRecognizeCommand object:self userInfo:@{@"Command" : command.lowercaseString}];
	}
}

- (void)enqueueBlock:(void(^)(NSString *command))commandBlock forCommand:(NSString*)command {
	NSParameterAssert(command);
	[self.commandMap setObject:[commandBlock copy] forKey:command.lowercaseString];
}

#pragma mark - UI

- (CGFloat)titleBarHeight
{
	NSRect outerFrame = [[[self contentView] superview] frame];
	NSRect innerFrame = [[self contentView] frame];
	
	return outerFrame.size.height - innerFrame.size.height;
}

/***************************************UNSAFE*****************************************************/
//1048584, -1048585 - Two Left CMD presses; 1048576, -1048577 - Two CMD presses; 8388608, -8388609 - Two Fn presses; 1048592, -1048593 - Two Right CMD presses
- (void)forceDictation {
	
	NSString *path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:@"Preferences/com.apple.symbolichotkeys.plist"];
	NSDictionary *dictationPrefs = [NSDictionary dictionaryWithContentsOfFile:path];
	NSDictionary *dictationDict = dictationPrefs[@"AppleSymbolicHotKeys"];
	NSDictionary *keyvalueDict = dictationDict[@"164"];
	NSDictionary *valueDict = keyvalueDict[@"value"];
	NSArray *parameters = valueDict[@"parameters"];
	NSInteger firstCode = [[parameters objectAtIndex:0]longLongValue];
	NSInteger secondCode = [[parameters objectAtIndex:0]longLongValue];
	CFDataRef data = CFDataCreate(NULL, &firstCode, 8);
	CGEventRef event = CGEventCreateFromData(NULL, data);
	
	CFDataRef secondData = CFDataCreate(NULL, &secondCode, 8);
	CGEventRef eventUp = CGEventCreateFromData(NULL, data);
//	CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
//	CGEventRef saveCommandDown = CGEventCreateKeyboardEvent(source, kCGEventNull, YES);
//	CGEventSetFlags(saveCommandDown, firstCode);
//	CGEventRef saveCommandUp = CGEventCreateKeyboardEvent(source, kCGEventNull, NO);
//	CGEventSetFlags(saveCommandUp, secondCode);

	CGEventPost(kCGAnnotatedSessionEventTap, event);
	CGEventPost(kCGAnnotatedSessionEventTap, eventUp);
	CGEventPost(kCGAnnotatedSessionEventTap, event);
	CGEventPost(kCGAnnotatedSessionEventTap, eventUp);

//	CFRelease(saveCommandUp);
//	CFRelease(saveCommandDown);
//	CFRelease(source);
	
}


@end