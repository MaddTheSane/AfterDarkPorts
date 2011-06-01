//
//  ADShapesView.h
//  ADShapes
//
//  Created by C.W. Betts on 5/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>


@interface ADShapesView : ScreenSaverView {
@private
	NSInteger	ADSMode;
	NSInteger	ADSIntensity;
	BOOL		mDrawBackground;
	
    IBOutlet NSWindow *configureSheet;
	IBOutlet NSButton *blankScreenButton;
	IBOutlet NSMatrix *modeMatrix;
}
- (IBAction)okayButton:(id)sender;
- (IBAction)cancelButton:(id)sender;

@property (readwrite) NSInteger ADSIntensity;


@end
