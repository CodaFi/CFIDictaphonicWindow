//
//  CFIDictaphonicWindow.m
//  CFIDictaphonicsExample
//
//  Created by Robert Widmann on 2/21/13.
//  Copyright (c) 2013 CodaFi. All rights reserved.
//  Released under the MIT license.
//

#import "CFIDictaphonicWindow.h"
#include <objc/runtime.h>

#define START_BITMASK_SWITCH(x) \
for (uint64_t bit = 1; x >= bit; bit *= 2) if (x & bit) switch (bit)

NSString *const CFIDictaphonicWindowCanStartDictation = @"CFIDictaphonicWindowCanStartDictation";
NSString *const CFIDictaphonicWindowDidMakeDictationFieldResign = @"CFIDictaphonicWindowDidMakeDictationFieldResign";
NSString *const CFIDictaphonicWindowDidRecognizeCommand = @"CFIDictaphonicWindowDidRecognizeCommand";
NSString *const CFIDictaphonicWindowDidNotRecognizeCommand = @"CFIDictaphonicWindowDidNotRecognizeCommand";
NSString *const CFIDictaphonicTextDidChange = @"CFIDictaphonicTextDidChange";

static NSString *const CFIDictaphonicCommandKey = @"CFIDictaphonicCommandKey";
static Class CFIDictaphonicFieldClass = Nil;

@interface CFIDictationField : NSControl <NSTextInputClient>
@property (nonatomic, strong) NSTextInputContext *inputContext;
@end

@implementation CFIDictationField

#pragma mark - Lifecycle

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];

	_inputContext = [[NSTextInputContext alloc] initWithClient:self];
	_inputContext.acceptsGlyphInfo = NO;
	
	return self;
}

#pragma mark - Text Attributes

- (NSAttributedString *)attributedSubstringForProposedRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange {
	return nil;
}

- (void)setMarkedText:(id)aString selectedRange:(NSRange)selectedRange replacementRange:(NSRange)replacementRange { }

- (void) unmarkText { }

- (BOOL) hasMarkedText {
	return NO;
}

- (NSRange)markedRange {
	return NSMakeRange(0, 0);
}

- (NSRange)selectedRange {
	return NSMakeRange(0, 0);
}

- (NSRect)firstRectForCharacterRange:(NSRange)theRange actualRange:(NSRangePointer)actualRange{
	NSRect rect = [self convertRect:NSZeroRect toView:nil];
	rect.origin = [self.window convertBaseToScreen:rect.origin];
	return rect;
}

- (NSUInteger)characterIndexForPoint:(NSPoint)thePoint {
	return 0;
}

- (NSArray *) validAttributesForMarkedText {
	return @[];
}

#pragma mark - Event Handling

- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange {
	[NSNotificationCenter.defaultCenter postNotificationName:CFIDictaphonicTextDidChange object:self userInfo:@{ CFIDictaphonicCommandKey : aString }];
}

//Do nothing, only inputs should be from Dictation
- (void)keyDown:(NSEvent *)theEvent { }

- (void)mouseDown:(NSEvent *)theEvent {
	[self.inputContext handleEvent:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent {
	[self.inputContext handleEvent:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent {
	[self.inputContext handleEvent:theEvent];
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect { }

@end

@interface CFIDictaphonicWindow ()
@property (nonatomic, strong) NSMutableDictionary *commandMap;
@property (nonatomic, strong) CFIDictationField *dummyField;
@end

@implementation CFIDictaphonicWindow

#pragma mark - Lifecycle

- (id)init {
	self = [super init];
	
	CFIDictaphonicWindowCommonInit(self);
	
	return self;
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];

	CFIDictaphonicWindowCommonInit(self);

	return self;
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag screen:(NSScreen *)screen {
	self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag screen:screen];

	CFIDictaphonicWindowCommonInit(self);

	return self;
}

- (void)awakeFromNib {
	CFIDictaphonicWindowCommonInit(self);
}

- (void)dealloc {
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

static void CFIDictaphonicWindowCommonInit(CFIDictaphonicWindow *self){
	self->_commandMap = @{}.mutableCopy;
	self->_dummyField = [[CFIDictationField alloc] initWithFrame:NSMakeRect(NSWidth(self.frame)/2, NSHeight([self.contentView frame]), 10, CFIDictaphonicWindowTitleBarHeight(self))];
	self->_dummyField.refusesFirstResponder = YES;
	self->_dummyField.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin;
	[[[self contentView] superview] addSubview:self.dummyField];
	
	if (CFIDictaphonicFieldClass == Nil) {
		CFIDictaphonicFieldClass = object_getClass(self->_dummyField);
	}
	
	[NSNotificationCenter.defaultCenter addObserverForName:CFIDictaphonicTextDidChange object:self.dummyField queue:nil usingBlock: ^(NSNotification *note) {
		[self handleCommand:note.userInfo[CFIDictaphonicCommandKey]];
	}];
}

#pragma mark - NSResponder Intercepting

- (BOOL)makeFirstResponder:(NSResponder *)aResponder {
	[self delayedCheckResponders];
	return [super makeFirstResponder:aResponder];
}

- (void)delayedCheckResponders {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkResponders) object:nil];
	[self performSelector:@selector(checkResponders) withObject:nil afterDelay:0];
}

- (void)checkResponders {
	if (self.firstResponder == self) {
		self.dummyField.refusesFirstResponder = NO;
		[self makeFirstResponder:self.dummyField];
	} else if ([self.firstResponder isKindOfClass:CFIDictaphonicFieldClass]) {
		[NSNotificationCenter.defaultCenter postNotificationName:CFIDictaphonicWindowCanStartDictation object:self];
	}
	else {
		self.dummyField.refusesFirstResponder = YES;
		[NSNotificationCenter.defaultCenter postNotificationName:CFIDictaphonicWindowDidMakeDictationFieldResign object:self];
	}
}

#pragma mark - Command Handling

- (void)handleCommand:(NSString*)command {
	void (^commandBlock)(NSString *commandStr) = [self.commandMap objectForKey:command.lowercaseString];
	if (commandBlock != nil) {
		commandBlock(command);
		[NSNotificationCenter.defaultCenter postNotificationName:CFIDictaphonicWindowDidRecognizeCommand object:self userInfo:@{ CFIDictaphonicCommandKey : command.lowercaseString }];
	} else {
		[NSNotificationCenter.defaultCenter postNotificationName:CFIDictaphonicWindowDidNotRecognizeCommand object:self userInfo:@{ CFIDictaphonicCommandKey : command.lowercaseString }];
	}
}

- (void)enqueueBlock:(void(^)(NSString *command))commandBlock forCommand:(NSString *)command {
	NSParameterAssert(command);
	NSParameterAssert(commandBlock);

	self.commandMap[command.lowercaseString] = [commandBlock copy];
}

- (void)startDictation {
	[self makeFirstResponder:nil];
	[NSApp performSelector:@selector(startDictation:) withObject:self.dummyField afterDelay:0.2];
}

#pragma mark - Private

static inline CGFloat CFIDictaphonicWindowTitleBarHeight(CFIDictaphonicWindow *self) {
	NSRect outerFrame = [[[self contentView] superview] frame];
	NSRect innerFrame = [[self contentView] frame];
	return outerFrame.size.height - innerFrame.size.height;
}

@end
