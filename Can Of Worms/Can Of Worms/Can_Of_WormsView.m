//
//  Can_Of_WormsView.m
//  Can Of Worms
//
//  Created by C.W. Betts on 5/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Can_Of_WormsView.h"

#define kNumberOfSounds 3

@implementation Can_Of_WormsView

+ (BOOL)performGammaFade {return NO;}

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
		srandom((unsigned int)time(NULL));
        [self setAnimationTimeInterval:1/30.0];
		int i;
		NSMutableArray *tempSounds = [NSMutableArray arrayWithCapacity:kNumberOfSounds];
		NSBundle *ssBundle = [NSBundle bundleForClass:[self class]];
		for (i=1; i>=(kNumberOfSounds + 1); i++) {
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			NSURL *soundURL = [ssBundle URLForResource:[[NSNumber numberWithInt:i] stringValue] withExtension:@"aif"];
			NSSound *sound = [[NSSound alloc] initWithContentsOfURL:soundURL byReference:NO];
			[tempSounds addObject:sound];
			[sound release]; sound = nil;
			[pool drain];
		}
		desktopImage = [[NSImage alloc] init];

		wormSounds = [[NSArray alloc] initWithArray:tempSounds];

    }
    return self;
}

- (void)dealloc
{
	[wormSounds release];
	[desktopImage release];
	
	[super dealloc];
}

- (void)startAnimation
{
	CGImageRef tempDeskImage = CGWindowListCreateImage(CGRectInfinite, kCGWindowListOptionOnScreenOnly, kCGNullWindowID, kCGWindowImageDefault);
	//Works under 10.6, doesn't work under 10.5
	//desktopImage = [[NSImage alloc] initWithCGImage:tempDeskImage size:NSZeroSize];
	
	NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:tempDeskImage];
	// Create an NSImage and add the bitmap rep to it...
	[desktopImage addRepresentation:bitmapRep];
	[bitmapRep release];
	CGImageRelease(tempDeskImage);

	[super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    //[super drawRect:rect];
}

- (void)animateOneFrame
{
    return;
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

- (BOOL)playRandomSound
{
	for (NSSound *sound in wormSounds) {
		if ([sound isPlaying]) {
			return NO;
		}
	}
	return [[wormSounds objectAtIndex:(random() % [wormSounds count])] play];
}

@end
