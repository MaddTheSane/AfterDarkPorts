//
//  ZotView.h
//  Zot
//
//  Created by C.W. Betts on 5/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>


@interface ZotView : ScreenSaverView {
@private
    NSSound *thunderSound;
	IBOutlet NSWindow *configureSheet;
	CGFloat kinkyness;
	CGFloat forkiness;
	CGFloat zotDelay;
	BOOL soundAvailable;
	BOOL zotColor;
}

@property (readwrite) CGFloat kinkyness;
@property (readwrite) CGFloat forkiness;
@property (readwrite) CGFloat zotDelay;

@property (readwrite,getter = isSoundAvailable) BOOL soundAvailable;
@property (readwrite,getter = isZotColor) BOOL zotColor;



- (IBAction)okayPrefs:(id)sender;
- (IBAction)cancelPrefs:(id)sender;

@end
