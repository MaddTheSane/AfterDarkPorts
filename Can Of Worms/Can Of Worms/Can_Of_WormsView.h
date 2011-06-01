//
//  Can_Of_WormsView.h
//  Can Of Worms
//
//  Created by C.W. Betts on 5/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>


@interface Can_Of_WormsView : ScreenSaverView {
@private
    NSArray *wormSounds;
	NSImage *desktopImage;
}

- (BOOL)playRandomSound;

@end
