//
//  Bouncing_BallView.h
//  Bouncing Ball
//
//  Created by C.W. Betts on 5/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>


@interface Bouncing_BallView : ScreenSaverView {
@private
	NSRect		ballRect;		/* the rectangle defining the ball. */
	NSInteger	ballDiameter;	/* the current diameter of the ball. */
	CGFloat		ballSin;		/* the current sin of angle of ball. */
	CGFloat		ballCos;		/* the current cos of angle of ball. */
	CGFloat		xdir;			/* current sign of x-component of velocity */
	CGFloat		ydir;			/* current sign of y-component of velocity */
	CGFloat		ballSpeed;		/* speed of ball */
	NSColor		*ballColor;		/* the color to draw the ball in. */
	short		bounceCount;	/* counter to determine when to choose a new bounce. */
	BOOL		soundAvailable;	/* flag that indicates existence of sound. */
	NSSound		*bounceSound;	/* the sound(s) to make when the ball bounces. */
	IBOutlet NSWindow *configureSheet;
	IBOutlet NSColorWell *ballColorWell;
	IBOutlet NSTextView *credits;
}
@property (readwrite) CGFloat ballSpeed;
@property (readwrite) NSInteger ballDiameter;
@property (readwrite,getter = isSoundAvailable) BOOL soundAvailable;
- (IBAction)cancelButton:(id)sender;
- (IBAction)okayButton:(id)sender;


@end
