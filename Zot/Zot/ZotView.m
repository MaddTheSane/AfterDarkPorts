//
//  ZotView.m
//  Zot
//
//  Created by C.W. Betts on 5/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ZotView.h"

static NSString *ZotDefaults = @"Zot!";

@implementation ZotView

@synthesize soundAvailable;
@synthesize kinkyness;
@synthesize forkiness;
@synthesize zotDelay;
@synthesize zotColor;

+ (void)initialize
{
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	
	[[ScreenSaverDefaults defaultsForModuleWithName:ZotDefaults] registerDefaults:defaults];
}

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/30.0];
		
		NSBundle *ssBundle = [NSBundle bundleForClass:[self class]];
		NSURL *soundURL = [ssBundle URLForResource:@"Thunder" withExtension:@"aif"];
		thunderSound = [[NSSound alloc] initWithContentsOfURL:soundURL byReference:NO];

    }
    return self;
}

- (void)dealloc
{
	[thunderSound release];
	
	[super dealloc];
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
}

- (void)animateOneFrame
{
    return;
}

- (BOOL)hasConfigureSheet
{
    return YES;
}

- (NSWindow*)configureSheet
{
	if (configureSheet == nil) {
		[NSBundle loadNibNamed:@"ZotPrefs" owner:self];
	}
	return configureSheet;
}

- (IBAction)okayPrefs:(id)sender {
	ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:ZotDefaults];

	[defaults synchronize];
	[NSApp endSheet:configureSheet];
}

- (IBAction)cancelPrefs:(id)sender {
	[NSApp endSheet:configureSheet];
}
@end
