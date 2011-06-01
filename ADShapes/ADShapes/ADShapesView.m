//
//  ADShapesView.m
//  ADShapes
//
//  Created by C.W. Betts on 5/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ADShapesView.h"

static NSString *ADSDefault = @"Shapes";
static NSString *ADSFadeScreen = @"Fade Screen";
static NSString *ADSShapeMode = @"Mode";
static NSString *ADSIntensityNumber = @"Intensity";

//#define kQuarterCircle 90

enum
{
	ADSTransparent = 0,
	ADSOpaque,
	ADSMixed
};

@interface NSBezierPath (ADShapesPrivate)
+ (void)ADSfillRectWithOval:(NSRect)oval;
+ (void)ADSFillRectWithTriangle:(NSRect)triangle;
@end

@implementation NSBezierPath (ADShapesPrivate)
+ (void)ADSfillRectWithOval:(NSRect)oval
{
	NSBezierPath *ballBezierPath = [NSBezierPath bezierPathWithOvalInRect:oval];
	[ballBezierPath fill];
}

+ (void)ADSFillRectWithTriangle:(NSRect)triangle
{
#if 0
	NSBezierPath *path = [NSBezierPath bezierPath];
	NSBezierPath *rotatePath = nil;
	short randOrientation = random() % 4;
	// move to the bottom-left
	[path moveToPoint: triangle.origin];
	
	// line to the top-middle
	NSPoint point;
	//point.x = triangle.origin.x + triangle.size.width / 2.0;
	point.x = NSMidX(triangle);
	point.y = NSMaxY(triangle);
	//point.y = triangle.origin.y + triangle.size.height;
	[path lineToPoint: point];
	
	// line to the bottom-right
	point.x = triangle.origin.x + triangle.size.width;
	point.y = triangle.origin.y;
	[path lineToPoint: point];
	
	// and close the path by adding a line back to the bottom left
	[path closePath];
	
	switch (randOrientation) {
		case 0:
		{
			rotatePath = path;
		}

			break;
			
		case 1:
		{
			NSAffineTransform *rotate = [NSAffineTransform transform];
			[rotate rotateByDegrees:kQuarterCircle];
			rotatePath = [rotate transformBezierPath:path];
		}
			break;
			
		case 2:
		{
			NSAffineTransform *rotate = [NSAffineTransform transform];
			[rotate rotateByDegrees:kQuarterCircle * 2];
			rotatePath = [rotate transformBezierPath:path];

		}
			break;
			
		case 3:
		{
			NSAffineTransform *rotate = [NSAffineTransform transform];
			[rotate rotateByDegrees:kQuarterCircle * 3];
			rotatePath = [rotate transformBezierPath:path];
		}
			break;
			
		default:
			break;
	}
	[rotatePath fill];
#else
	NSBezierPath *path = [NSBezierPath bezierPath];
	short randOrientation = random() % 4;
	
	switch (randOrientation) {
		case 0:
		{
			NSPoint point;
			
			point.x = NSMinX(triangle);
			point.y = NSMinY(triangle);
			// move to the bottom-left
			[path moveToPoint: point];
			
			// line to the top-middle
			//point.x = triangle.origin.x + triangle.size.width / 2.0;
			point.x = NSMidX(triangle);
			point.y = NSMaxY(triangle);
			//point.y = triangle.origin.y + triangle.size.height;
			[path lineToPoint: point];
			
			// line to the bottom-right
			//point.x = triangle.origin.x + triangle.size.width;
			point.x = NSMaxX(triangle);
			point.y = NSMinY(triangle);
			//point.y = triangle.origin.y;
			[path lineToPoint: point];
			
			// and close the path by adding a line back to the bottom left
			[path closePath];
		}
			
			break;
			
		case 1:
		{
			NSPoint point;

			point.x = NSMinX(triangle);
			point.y = NSMinY(triangle);
			// move to the bottom-left
			[path moveToPoint: point];
			
			// line to the top-middle
			//point.x = triangle.origin.x + triangle.size.width / 2.0;
			point.x = NSMinX(triangle);
			point.y = NSMaxY(triangle);
			//point.y = triangle.origin.y + triangle.size.height;
			[path lineToPoint: point];
			
			// line to the bottom-right
			point.x = NSMaxX(triangle);
			point.y = NSMidY(triangle);
			[path lineToPoint: point];
			
			// and close the path by adding a line back to the bottom left
			[path closePath];
		}
			break;
			
		case 2:
		{
			NSPoint point;
			
			point.x = NSMinX(triangle);
			point.y = NSMaxY(triangle);
			// move to the bottom-left
			[path moveToPoint: point];
			
			// line to the top-middle
			//point.x = triangle.origin.x + triangle.size.width / 2.0;
			point.x = NSMidX(triangle);
			point.y = NSMinY(triangle);
			//point.y = triangle.origin.y + triangle.size.height;
			[path lineToPoint: point];
			
			// line to the bottom-right
			point.x = NSMaxX(triangle);
			point.y = NSMaxY(triangle);
			[path lineToPoint: point];
			
			// and close the path by adding a line back to the bottom left
			[path closePath];
			
		}
			break;
			
		case 3:
		{
			NSPoint point;
			
			point.x = NSMinX(triangle);
			point.y = NSMidY(triangle);
			// move to the bottom-left
			[path moveToPoint: point];
			
			// line to the top-middle
			//point.x = triangle.origin.x + triangle.size.width / 2.0;
			point.x = NSMaxX(triangle);
			point.y = NSMaxY(triangle);
			//point.y = triangle.origin.y + triangle.size.height;
			[path lineToPoint: point];
			
			// line to the bottom-right
			point.x = NSMaxX(triangle);
			point.y = NSMinY(triangle);
			[path lineToPoint: point];
			
			// and close the path by adding a line back to the bottom left
			[path closePath];
		}
			break;
			
		default:
			break;
	}
	[path fill];

#endif
}
@end


@implementation ADShapesView

@synthesize ADSIntensity;

+ (BOOL)performGammaFade 
{
	if([[ScreenSaverDefaults defaultsForModuleWithName:ADSDefault] boolForKey:ADSFadeScreen])
	{
		return YES;
	} else {
		return NO;
	}
}

+ (void)initialize
{
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults setObject:[NSNumber numberWithBool:NO] forKey:ADSFadeScreen];
	[defaults setObject:[NSNumber numberWithShort:ADSTransparent] forKey:ADSShapeMode];
	[defaults setObject:[NSNumber numberWithInt:100] forKey:ADSIntensityNumber];
	
	[[ScreenSaverDefaults defaultsForModuleWithName:ADSDefault] registerDefaults:defaults];
}

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
		srandom((unsigned)time(NULL));
        [self setAnimationTimeInterval:1/30.0];
		ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:ADSDefault];
		ADSMode = [defaults integerForKey:ADSShapeMode];
		ADSIntensity = [defaults integerForKey:ADSIntensityNumber];

    }
    return self;
}

- (void)viewDidMoveToWindow {
	// this NSView method is called when our screen saver view is added to its window
	// we'll use this signal to tell drawRect: to erase the background
	mDrawBackground = YES;
}


- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (BOOL)isOpaque {
	// this keeps Cocoa from unneccessarily redrawing our superview
	return YES;
}

- (void)drawRect:(NSRect)rect
{
	ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:ADSDefault];
	
	if ( mDrawBackground ) {
		//   draw background after view is installed in a window for the first time
		//[[NSColor colorWithDeviceRed: 0.0 green: 0.0
		//						blue: 0.0 alpha: 1.0] set];
		//[NSBezierPath fillRect: [self bounds]];
		if ([defaults boolForKey:ADSFadeScreen]) {
			[super drawRect:rect];
		} else {
			NSImage *desktopImage = [[NSImage alloc] init];
			{
				CGImageRef tempDeskImage = CGWindowListCreateImage(CGRectInfinite, kCGWindowListOptionOnScreenOnly, kCGNullWindowID, kCGWindowImageDefault);
				//Works under 10.6, doesn't work under 10.5
				//desktopImage = [[NSImage alloc] initWithCGImage:tempDeskImage size:NSZeroSize];
				NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:tempDeskImage];
				// Create an NSImage and add the bitmap rep to it...
				[desktopImage addRepresentation:bitmapRep];
				[bitmapRep release];
				CGImageRelease(tempDeskImage);
			}
			{
				NSRect imageRect;
				imageRect.origin = NSZeroPoint;
				imageRect.size = [desktopImage size];
				[desktopImage drawInRect:[self bounds] fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
			}
			[desktopImage release];
		}
		mDrawBackground = NO;
	}
	
	NSRect viewBounds = [self bounds];
	CGFloat startingX = SSRandomFloatBetween(
										   NSMinX( viewBounds ), NSMaxX( viewBounds ) );
	CGFloat startingY = SSRandomFloatBetween(
										   NSMinY( viewBounds ), NSMaxY( viewBounds ) );
	CGFloat width = SSRandomFloatBetween(
									   NSWidth(viewBounds)/20, NSWidth(viewBounds)/2);
	CGFloat height = SSRandomFloatBetween(
										NSHeight(viewBounds)/20, NSHeight(viewBounds)/2);
	NSRect rectToFill = NSMakeRect( startingX, startingY,
								   width, height );
	
	CGFloat red = SSRandomFloatBetween(0.0, 1.0);
	CGFloat green = SSRandomFloatBetween(0.0, 1.0);
	CGFloat blue = SSRandomFloatBetween(0.0, 1.0);
	CGFloat alpha = 1.0;// = SSRandomFloatBetween(0.0, 1.0);
	
	switch (ADSMode) {
		case ADSTransparent:
			alpha = 0.5;
			break;
			
		case ADSOpaque:
			alpha = 1;
			break;
			
		case ADSMixed:
		{
			BOOL currentOpaque = (BOOL)(random() % 2);
			if (currentOpaque) {
				alpha = 1;
			} else {
				alpha = 0.5;
			}
		}
			break;
			
		default:
			break;
	}
	[[NSColor colorWithDeviceRed: red green: green
							blue: blue alpha: alpha] set];
	short drawType = random() % 3;
	switch (drawType) {
		case 0:
			[NSBezierPath fillRect: rectToFill];
			break;
			
		case 1:
			[NSBezierPath ADSfillRectWithOval: rectToFill];
			break;
			
		case 2:
			[NSBezierPath ADSFillRectWithTriangle: rectToFill];
			break;
			
		default:
			break;
	}
}

- (void)animateOneFrame
{
    [self setNeedsDisplay:YES];
	return;
}

- (BOOL)hasConfigureSheet
{
    return YES;
}

- (NSWindow*)configureSheet
{
	if (configureSheet == nil) {
		[NSBundle loadNibNamed:@"ADShapesConfig" owner:self];
	}
	if (configureSheet) {
		[blankScreenButton setState:[[ScreenSaverDefaults defaultsForModuleWithName:ADSDefault] boolForKey:ADSFadeScreen]];
		NSInteger modeToSet = [[ScreenSaverDefaults defaultsForModuleWithName:ADSDefault] integerForKey:ADSShapeMode];
		[modeMatrix highlightCell:(modeToSet == ADSTransparent) atRow:0 column:0];
		[modeMatrix highlightCell:(modeToSet == ADSOpaque) atRow:1 column:0];
		[modeMatrix highlightCell:(modeToSet == ADSMixed) atRow:2 column:0];

	}
	return configureSheet;
}

- (IBAction)okayButton:(id)sender {
	ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:ADSDefault];
	[defaults setInteger:self.ADSIntensity forKey:ADSIntensityNumber];
	id selectedCell = [modeMatrix selectedCell];
	if (selectedCell == [modeMatrix cellAtRow:0 column:0]) {
		ADSMode = ADSTransparent;
	} else if (selectedCell == [modeMatrix cellAtRow:1 column:0]) {
		ADSMode = ADSOpaque;
	} else if (selectedCell == [modeMatrix cellAtRow:2 column:0]) {
		ADSMode = ADSMixed;	
	}
	[defaults setInteger:ADSMode forKey:ADSShapeMode];
	[defaults setBool:[blankScreenButton state] forKey:ADSFadeScreen];
	[NSApp endSheet:configureSheet];
}

- (IBAction)cancelButton:(id)sender {
	[NSApp endSheet:configureSheet];
}
@end
