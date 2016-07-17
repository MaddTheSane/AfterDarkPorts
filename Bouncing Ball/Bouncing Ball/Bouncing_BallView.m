//
//  Bouncing_BallView.m
//  Bouncing Ball
//
//  Created by C.W. Betts on 5/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include <math.h>
#include <tgmath.h>
#import "Bouncing_BallView.h"

#define BOUNCE_COUNT			10		/* number of bounces before changing direction. */

static NSString *BBDefaults = @"Bouncing Ball";
static NSString *BBColor = @"Color";
static NSString *BBSpeed = @"Speed";
static NSString *BBSize = @"Size";
static NSString *BBPlaySound = @"Play bounce sound";

#if 0
static short BBrandom(short lower, short upper)
{
	short middle = (lower+upper)/2;
	short randValue = middle + (random() % (upper - middle));
	if(randValue < lower)
		return lower;
	if(randValue > upper)
		return upper;
	return randValue;
}
#else

#define BBrandom(lower, upper) SSRandomFloatBetween(lower, upper)

#endif

static inline CGFloat RandomAngle(short lower, short upper)
{
	return (((BBrandom(lower, upper))* M_PI_4) / 45.0);
}

@implementation Bouncing_BallView
{
	NSArray *nibObjects;
}
@synthesize ballSpeed;
@synthesize ballDiameter;
@synthesize soundAvailable;

+ (void)initialize
{
	ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:BBDefaults];
	NSDictionary *dict = @{BBSize: @12,
						   BBSpeed: @10,
						   BBPlaySound: @YES,
						   BBColor: [NSKeyedArchiver archivedDataWithRootObject:[NSColor whiteColor]]};
	
	[defaults registerDefaults:dict];
}

- (NSColor *)getColorFromDefaults
{
	ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:BBDefaults];
	NSData *colorData = [defaults objectForKey:BBColor];
	return [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
}

- (void)setColorForDefaults:(NSColor *)color
{
	ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:BBDefaults];
	[defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:color] forKey:BBColor];
	if (color != ballColor) {
		ballColor = color;
	}
	//[defaults synchronize];
}

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
		srandom(time(NULL) & 0x7fffffff);
        [self setAnimationTimeInterval:1/30.0];
#if 0
		ballSize = NSMakeSize(15, 15);
		ballPosition = SSRandomPointForSizeWithinRect(ballSize, [self bounds]);
		ballDirection = SSRandomFloatBetween(0, (2.0 * M_PI));
		if (ballDirection == (2.0 * M_PI)) {
			ballDirection = 0;
		}
		ballColor = [[NSColor colorWithDeviceRed:1.0 green:0.5 blue:0.0 alpha:1.0] retain];
		NSBundle *ssBundle = [NSBundle bundleForClass:[self class]];
		NSURL *soundURL = [ssBundle URLForResource:@"bounce" withExtension:@"aif"];
		bouncingBall = [[NSSound alloc] initWithContentsOfURL:soundURL byReference:NO];
#else
		
		/* set up a random initial position of ball. */
		xdir = ydir = 1;	/* sign of velocities is positive */
		ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:BBDefaults];
		
		ballDiameter = [defaults integerForKey:BBSize];
#if CGFLOAT_IS_DOUBLE
		ballSpeed = [defaults doubleForKey:BBSpeed];
#else
		ballSpeed = [defaults floatForKey:BBSpeed];
#endif

		soundAvailable = [defaults boolForKey:BBPlaySound];
		
		NSSize ballSize = NSMakeSize(ballDiameter, ballDiameter);
		NSPoint ballPoint = SSRandomPointForSizeWithinRect(ballSize, [self bounds]);
		ballRect.size = ballSize;
		ballRect.origin = ballPoint;
		
		ballColor = [self getColorFromDefaults];
		

		
		/* initialize counter that keeps track of number of bounces that have occurred. */
		bounceCount = BOUNCE_COUNT;
		
		/* choose a random direction for the ball to travel. */
		CGFloat ballAngle = RandomAngle(10, 80);
		ballSin = sin(ballAngle);
		ballCos = cos(ballAngle);
		
		
		NSBundle *ssBundle = [NSBundle bundleForClass:[self class]];
		NSURL *soundURL = [ssBundle URLForResource:@"bounce" withExtension:@"aif"];
		bounceSound = [[NSSound alloc] initWithContentsOfURL:soundURL byReference:NO];

#endif
    }
    return self;
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
	NSBezierPath *ballBezierPath = [NSBezierPath bezierPathWithOvalInRect:ballRect];
	[ballColor set];
	[ballBezierPath fill];
}

- (void)animateOneFrame
{
	CGFloat xVelocity, yVelocity;
	NSRect oldBall = ballRect;
	BOOL bouncing = NO;
	xVelocity = ballSpeed * ballCos;
	yVelocity = ballSpeed * ballSin;
	NSPoint newBallPoint;
	newBallPoint.x = xdir * xVelocity + ballRect.origin.x;
	newBallPoint.y = ydir * yVelocity + ballRect.origin.y;
	NSRect newBall;
	newBall.origin = newBallPoint;
	newBall.size = ballRect.size;
	
	/* now that we've moved the ball, see if it is still visible. */
	/* if not, the ball should bounce off the wall and change direction. */
	{
		NSRect viewRect = [self bounds];
		
		ballRect.origin = newBallPoint;
		
		if (ballRect.origin.y <= viewRect.origin.y) {
			ydir = -ydir;
			ballRect.origin.y = viewRect.origin.y;
			
			bouncing = YES;
		} else if ((ballRect.origin.y + ballRect.size.height) >= viewRect.size.height) {
			ydir = -ydir;
			ballRect.origin.y = viewRect.size.height - ballRect.size.height;
			
			bouncing = YES;
		}
		
		if (ballRect.origin.x <= viewRect.origin.x) {
			xdir = -xdir;
			ballRect.origin.x = viewRect.origin.x;
			
			bouncing = YES;
		} else if ((ballRect.origin.x + ballRect.size.width) >= viewRect.size.width) {
			xdir = -xdir;
			ballRect.origin.x = viewRect.size.width - ballRect.size.width;
			
			bouncing = YES;
		}
	}
	
	if(bouncing) {
		if(bounceCount-- == 0) {
			/* time to choose a new angle to move along. */
			/* choose an angle between 10° and 80°. */
			CGFloat ballAngle = RandomAngle(10, 80);
			bounceCount = BOUNCE_COUNT;
			ballSin = sin(ballAngle);
			ballCos = cos(ballAngle);
		}
		/* play the sound. */
		if(soundAvailable)
			[bounceSound play];
	}
	[self setNeedsDisplayInRect:NSUnionRect(oldBall, ballRect)];
}

- (BOOL)hasConfigureSheet
{
    return YES;
}

- (NSWindow*)configureSheet
{
	if (configureSheet == nil) {
		NSArray *arr;
		[[NSBundle bundleForClass:[self class]] loadNibNamed:@"BallPrefs" owner:self topLevelObjects:&arr];
		nibObjects = arr;
	}
	if (configureSheet) {
		[ballColorWell setColor:[self getColorFromDefaults]];
		[credits readRTFDFromFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Credits" ofType:@"rtf"]];

	}
	return configureSheet;
}

- (IBAction)cancelButton:(id)sender {
	ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:BBDefaults];
	self.ballSpeed = 
#if CGFLOAT_IS_DOUBLE
	[defaults doubleForKey:BBSpeed];
#else
	[defaults floatForKey:BBSpeed];
#endif
	self.soundAvailable = [defaults boolForKey:BBPlaySound];
	[NSApp endSheet:configureSheet];
}

- (IBAction)okayButton:(id)sender {
	ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:BBDefaults];
#if CGFLOAT_IS_DOUBLE
	[defaults setDouble:self.ballSpeed forKey:BBSpeed];
#else
	[defaults setFloat:self.ballSpeed forKey:BBSpeed];
#endif
	[defaults setInteger:self.ballDiameter forKey:BBSize];
	[defaults setBool:self.soundAvailable forKey:BBPlaySound];
	[self setColorForDefaults:[ballColorWell color]];
	[defaults synchronize];
	ballRect.size = NSMakeSize(ballDiameter, ballDiameter);
	[NSApp endSheet:configureSheet];
}

@end
