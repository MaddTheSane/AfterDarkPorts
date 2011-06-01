/*
 *	Bouncing Ball.c
 *	
 *	Example After Dark graphics module implementation.
 *	
 *	¥	Uses features of After Darkª, slider and button controls control speed, size and color.
 *	¥	Uses classic quickdraw to draw things in black & white.
 *	¥	Uses color quickdraw in minimal way to draw a color bouncing ball.
 *	¥	Shows how to use sampled, one-shot, sound.
 *	
 *	THINK C version
 *
 *	by Patrick C. Beard and Bruce Burkhalter.
 *	
 *	©1989, 90, 91 Berkeley Systems, Inc.
 */

/*

If Think C 4.x is present include the first set of files.  Otherwise
include files for Think C 5.x and MPW 3.x.  In Think C 4.x THINK_C = 1.
In Think C 5.x THINK_C = 5.

*/
#if 0
#if THINK_C == 1
#include <QuickDraw.h>
#include <MemoryMgr.h>
#include <OSUtil.h>
#include <Color.h>
#else
#include <QuickDraw.h>
#include <Memory.h>
#include <Resources.h>
#include <OSUtils.h>
#include <ToolUtils.h>
#include <FixMath.h>
#include <Picker.h>
#endif
#else
#include <Carbon/Carbon.h>
#endif


#include "GraphicsModule_Types.h"
#include "Sounds.h"

#define COLOR_BUTTON_MESSAGE	8		/* message that brings up color picker dialog */
#define BALLCOLOR_RGBV			128		/* resource id of 'RGBv' resource to color ball with. */
#define TENNIS_SOUND			128		/* resource id of tennis ball 'snd ' */
#define BOUNCE_COUNT			10		/* number of bounces before changing direction. */

/* record to hold bouncing ball's variables. */

typedef struct BBStorage {
	Rect		ballRect;		/* the rectangle defining the ball. */
	short		ballDiameter;	/* the current diameter of the ball. */
	Fixed		ballAngle;		/* the current angle ball is traveling. */
	Fixed		ballSin;		/* the current sin of angle of ball. */
	Fixed		ballCos;		/* the current cos of angle of ball. */
	short		xdir;			/* current sign of x-component of velocity */
	short		ydir;			/* current sign of y-component of velocity */
	RGBColor	ballColor;		/* the color to draw the ball in. */
	RGBColor	whiteRGB;		/* the color white expressed in RGB colors. */
	RgnHandle	ballRgn;		/* newer way of dealing with the ball */
	RgnHandle	oldRgn;			/* the previous location of the ball. */
	RgnHandle	diffRgn;		/* the difference in positions */
	long		bounceCount;	/* counter to determine when to choose a new bounce. */
	Boolean		soundAvailable;	/* flag that indicates existence of sound. */
	SoundInfo	**soundInfo;	/* storage for sound. */
	Handle		bounceSound;	/* the sound(s) to make when the ball bounces. */
} BBStorage, *BBStoragePtr, **BBStorageHandle;

/* for exception handling, a macro. */

#define FailNIL(p)	if(!(p)) { CleanUp((BBStorage**)h); *storage = nil; return -1; }

static short bbrandom(short lower, short upper);
static void CleanUp(BBStorage** storage);
static Fixed RandomAngle(short lower, short upper);
static void WatchCursor();


/* routines */

/*
 *	DoInitialize is the first function called from After Darkª.
 *	The module allocates and initializes its storage.  This storage is maintained
 *	in the parameter "storage" and the function returns "noErr" if there are no problems.
 */

OSErr
DoInitialize(Handle *storage, RgnHandle blankRgn, GMParamBlockPtr params)
{
	OSErr result;
	short i;
	Handle h;
	BBStoragePtr ballStorage;
	RGBColor **savedColor, whiteRGB, blackRGB;
	PixPatHandle pp;
	short ballDiameter;
	RgnHandle ballRgn;
	Rect ballRect;
	Rect monitorRect;
	Fixed ballAngle;
	StringPtr errorMessage = (StringPtr)"\pBouncing Ball:  Sorry, there is not enough memory.";
	
	/* since the sound code is in AD we must make sure the version of AD we are */
	/* running under has it.  AD 2.0u and later have the sound code but we just */
	/* need to check the "extensions" bit in SystemConfig.						*/
	
	if (!(ExtensionsAvailable & params->systemConfig))
	{
		BlockMove("\pBouncing Ball:  Sorry, you need After Dark 2.0u or later.", params->errorMessage, 255);
		return ModuleError;
	}

	/* in case we have an error, this message will be displayed. */
	BlockMove(errorMessage, params->errorMessage, 1 + errorMessage[0]);
	
	/* allocate handle to my storage */
	h = NewHandleClear(sizeof(BBStorage));
	FailNIL(h);
	
	/* store a reference to our storage where After Darkª can keep it. */
	*storage = h;	
	
	/* lock down our storage so we can refer to it by pointer. */
	MoveHHi(h);
	HLock(h);	
	ballStorage = (BBStoragePtr)*h;

	/* set up a random initial position of ball. */
	ballStorage->xdir = ballStorage->ydir = 1;	/* sign of velocities is positive */
	ballStorage->ballDiameter = ballDiameter = params->controlValues[1] + 2;	/* 2nd slider value is diameter */
	
	/* place the ball at a random location on the first monitor. */
	monitorRect = params->monitors->monitorList[0].bounds;
	ballRect.left = bbrandom(monitorRect.left, monitorRect.right - ballDiameter);
	ballRect.right = ballRect.left + ballDiameter;
	ballRect.top = bbrandom(monitorRect.top, monitorRect.bottom - ballDiameter);
	ballRect.bottom = ballRect.top + ballDiameter;
	
	/* allocate a region that describes position of the ball. */
	ballStorage->ballRect = ballRect;
	ballStorage->ballRgn = ballRgn = NewRgn();
	FailNIL(ballRgn);
	OpenRgn();
	FrameOval(&ballRect);
	CloseRgn(ballRgn);

	/* initialize counter that keeps track of number of bounces that have occurred. */
	ballStorage->bounceCount = BOUNCE_COUNT;
		
	/* choose a random direction for the ball to travel. */
	ballAngle = RandomAngle(10, 80);
	ballStorage->ballSin = Frac2Fix(FracSin(ballAngle));
	ballStorage->ballCos = Frac2Fix(FracCos(ballAngle));
	
	/* get all scratch regions that we'll ever need */
	ballStorage->oldRgn = NewRgn();
	FailNIL(ballStorage->oldRgn);
	ballStorage->diffRgn = NewRgn();
	FailNIL(ballStorage->diffRgn);
	
	/* if color quickdraw exists, get color information */
	if(params->colorQDAvail) {
		whiteRGB.red = whiteRGB.green = whiteRGB.blue = 0xffff;
		blackRGB.red = blackRGB.green = blackRGB.blue = 0;
		ballStorage->whiteRGB = whiteRGB;
		/* get the color of the ball from our resource fork */
		savedColor = (RGBColor**)GetResource('RGBv', BALLCOLOR_RGBV);
		if(savedColor != nil) {
			ballStorage->ballColor = **savedColor;
			ReleaseResource((Handle)savedColor);
		} else {
			/* default to white if we can't get our resource. */
			ballStorage->ballColor = whiteRGB;
		}
		/* now, make sure this color doesn't map to black.  if it is, use white. */
		if(Color2Index(&ballStorage->ballColor) == Color2Index(&blackRGB))
			ballStorage->ballColor = whiteRGB;
	}
	
	/* NEW:  SOUND SUPPORT */
	
	/* see if a sound channel is even part of the parameter block. */
	ballStorage->soundAvailable = (params->systemConfig & SoundAvailable) != 0;
	
	if(ballStorage->soundAvailable) {
		/* load the resources for our bouncing sounds. */
		ballStorage->bounceSound = GetResource('snd ', TENNIS_SOUND);
		FailNIL(ballStorage->bounceSound);
		
		/* get ready to use sound. */
		/* to use the sound functions in AD 2.0u we must pass in "params" */
		ballStorage->soundInfo = OpenSound(params);
	}

	/* unlock storage handle. */	
	HUnlock(h);

	return noErr;
}

/* we arrive here if anything has failed. */

static void CleanUp(BBStorage** storage)
{
	if(storage) {
		BBStorage *ballStorage;
		
		HLock((Handle)storage);
		ballStorage = *storage;
		if(ballStorage->ballRgn)
			DisposeRgn(ballStorage->ballRgn);
		if(ballStorage->oldRgn)
			DisposeRgn(ballStorage->oldRgn);
		if(ballStorage->diffRgn)
			DisposeRgn(ballStorage->diffRgn);
		if(ballStorage->soundAvailable) {
			if(ballStorage->bounceSound)
				ReleaseResource(ballStorage->bounceSound);
		}
		DisposHandle((Handle)storage);
	}
}

/*
 *	DoBlank is called next.
 *	It performs tasks that are done only once, such as making the screen
 *	go black.
 */

OSErr
DoBlank(Handle storage, RgnHandle blankRgn, GMParamBlockPtr params)
{
	FillRgn(blankRgn, &params->qdGlobalsCopy->qdBlack);
	return noErr;
}

/*
 *	DoDrawFrame does almost all of the work.  It draws the ball as a QuickDraw oval of
 *	equal width and height.  It moves the ball according to the "speed" slider and checks
 *	that it is still on one of the monitors in the monitor list.  It draws the ball
 *	with a diameter equal to that set by the "size" slider.
 */

/* some macros to simplify synchronizing to the vertical retrace. */
#define SynchFlag(m) (params->monitors->monitorList[m].synchFlag)
#define SynchVBL(m) synchFlag = &SynchFlag(m); *synchFlag = false; while(!*synchFlag);

OSErr
DoDrawFrame(storage, blankRgn, params)
Handle storage;
RgnHandle blankRgn;
GMParamBlockPtr params;
{
	register BBStoragePtr ballStorage;	/* to hold dereferenced storage handle */
	register Boolean *synchFlag;		/* pointer to speed up access to synch */
	RgnHandle ballRgn;					/* current (new) location of the ball */
	RgnHandle oldRgn, diffRgn;			/* regions for updating position */
	Rect ballRect;						/* current bounding rect of ball */
	Rect intersection;					/* for finding which monitor ball is on */
	Fixed speed;						/* speed of the ball. */
	short xVelocity, yVelocity;			/* calculated x, y components of velocity */
	short ballDiameter;					/* diameter of the ball set by slider. */
	Rect monitorRect;					/* rectange of monitor we were in. */
	Rect monitorIntersection;			/* how much the ball touches the monitor. */
	short howManyTouching;				/* count of monitors ball is touching. */
	short i, oldMonitor, newMonitor;	/* which monitors we find ourself on */
	Boolean bouncing = false;			/* if we're actually bouncing off a wall. */
	
	/* lock our storage down so we can dereference it for faster access */
	HLock(storage);
	ballStorage = (BBStoragePtr)*storage;

	/* get last position of the ball */
	ballRgn = ballStorage->ballRgn;
	oldRgn = ballStorage->oldRgn;
	diffRgn = ballStorage->diffRgn;
	CopyRgn(ballRgn, oldRgn);			/* save last position of the ball */
	
	/* calculate what the current x & y components of velocity should be. */
	speed = Long2Fix(params->controlValues[0]);	/* first slider is speed. */
	xVelocity = Fix2Long(FixMul(speed, ballStorage->ballCos));
	yVelocity = Fix2Long(FixMul(speed, ballStorage->ballSin));

	/* move the ball */
	OffsetRgn(ballRgn, ballStorage->xdir * xVelocity, ballStorage->ydir * yVelocity);
		
	/* set up the diameter of the ball */
	ballDiameter = params->controlValues[1] + 2;	/* second slider is the diameter of the ball in pixels */
	//ballRect = (**ballRgn).rgnBBox;
	GetRegionBounds(ballRgn, &ballRect);
	/* has the diameter changed?  if it has, recompute its region. */
	if(ballDiameter != ballStorage->ballDiameter) {
		ballStorage->ballDiameter = ballDiameter;
		ballRect.bottom = ballRect.top + ballDiameter;
		ballRect.right = ballRect.left + ballDiameter;
		OpenRgn();
		FrameOval(&ballRect);
		CloseRgn(ballRgn);
	}

	/* look for the monitor that ball WAS on. */
	oldMonitor = 0, newMonitor = -1;
	howManyTouching = 0;
	monitorIntersection = ballRect;
	for(i = 0; i < params->monitors->monitorCount; i++) {
		if(SectRect(&ballStorage->ballRect, &(params->monitors->monitorList[i].bounds), &intersection)) {
			oldMonitor = i;
			monitorRect = params->monitors->monitorList[i].bounds;
		}
		if(SectRect(&ballRect, &(params->monitors->monitorList[i].bounds), &intersection)) {
			newMonitor = i;
			monitorIntersection = intersection;
			howManyTouching++;
		}
	}

	/* now that we've moved the ball, see if it is still visible. */
	/* if not, the ball should bounce off the wall and change direction. */
		
	if(newMonitor == -1 || (howManyTouching < 2 && !EqualRect(&ballRect, &monitorIntersection)) ) {
		short deltaX = 0, deltaY = 0;
		/* we are going to bounce the ball. */
		newMonitor = oldMonitor;				/* right back to the old monitor. */
		bouncing = true;
		/* see what directions we have to change. */
		if(ballRect.right > monitorRect.right) {
			ballStorage->xdir = -1;				/* we're off to the right */
			deltaX = monitorRect.right - ballRect.right;
		}
		if(ballRect.left < monitorRect.left) {
			ballStorage->xdir = 1;				/* we're off to the left */
			deltaX = monitorRect.left - ballRect.left;
		}
		if(ballRect.bottom > monitorRect.bottom) {
			ballStorage->ydir = -1;				/* we're off below. */
			deltaY = monitorRect.bottom - ballRect.bottom;
		}
		if(ballRect.top < monitorRect.top) {
			ballStorage->ydir = 1;				/* we're off above. */
			deltaY = monitorRect.top - ballRect.top;
		}
		/* make the ball appear to hit the wall right at its boundary. */
		OffsetRect(&ballRect, deltaX, deltaY);
		OffsetRgn(ballRgn, deltaX, deltaY);
	}

	/* record the new position. */
	ballStorage->ballRect = ballRect;
	
	/* are we bouncing? */
	if(bouncing) {
		if(ballStorage->bounceCount-- == 0) {
			/* time to choose a new angle to move along. */
			/* choose an angle between 10¡ and 80¡. */
			Fixed ballAngle = RandomAngle(10, 80);
			ballStorage->bounceCount = BOUNCE_COUNT;
			ballStorage->ballSin = Frac2Fix(FracSin(ballAngle));
			ballStorage->ballCos = Frac2Fix(FracCos(ballAngle));
		}
		/* play the sound. */
		if(ballStorage->soundAvailable)
			PlaySound(ballStorage->soundInfo, params->sndChannel, ballStorage->bounceSound);
	}
	
	/*
	 *	Compute the difference between where we're moving and where we are.
	 *	This reduces flicker.  The best approach would use an offscreen bitmap.
	 */

	DiffRgn(oldRgn, ballRgn, diffRgn);

	/* if color is available, set up the color to draw in. */
	if(params->colorQDAvail) {
		SynchVBL(newMonitor);								/* wait until monitor does retrace. */
		RGBBackColor(&ballStorage->whiteRGB);
		FillRgn(diffRgn, &params->qdGlobalsCopy->qdBlack);	/* erase old */

		/* if this monitor is in greater than 1 bit/pixel, use the color. */
		if(params->monitors->monitorList[newMonitor].curDepth != 1)
			RGBBackColor(&ballStorage->ballColor);
		FillRgn(ballRgn, &params->qdGlobalsCopy->qdWhite);	/* draw new */
	}
	else{
		/* draw the bouncing ball in its new location after erasing it in old location. */
		SynchVBL(newMonitor);								/* wait until monitor does retrace. */
		FillRgn(diffRgn, &params->qdGlobalsCopy->qdBlack);	/* erase old */
		FillRgn(ballRgn, &params->qdGlobalsCopy->qdWhite);	/* draw new */
	}
	
	HUnlock(storage);

	return noErr;
}

/*
 *	DoClose() is called when the user wakes up the screen saver.  The memory is deallocated
 *	and the function returns noErr to tell After Dark all is well.
 */

OSErr
DoClose(storage, blankRgn, params)
Handle storage;
RgnHandle blankRgn;
GMParamBlockPtr params;
{
	BBStorage **ballStorage = (BBStorage**)storage;

	if(ballStorage) 
		CloseSound((**ballStorage).soundInfo, params->sndChannel);

	/* deallocate our storage */
	CleanUp(ballStorage);

	return noErr;
}

/*	
 *	DoSetUp" is called if the user clicks on a button in the Control Panel.  In this case
 *	The only button is to change the color of the ball.  The function calls the "Color
 *	Picker" dialog and then sets the color of the ball to the one chosen.  The color is
 *	then saved in the resource fork of the module.
 */

OSErr
DoSetUp(blankRgn, message, params)
RgnHandle blankRgn;
short message;
GMParamBlockPtr params;
{
	Point where;
	Boolean newColorChosen;
	RGBColor **savedColor;
	RGBColor beforeColor, afterColor;

	/* here we ask the user to specify the RGB componets of color for the ball. */
	/* use this to set up things that aren't covered easily by params & sliders */
	
	switch(message) {
	case COLOR_BUTTON_MESSAGE:
		WatchCursor();													/* make cursor a watch. */
		where.h = where.v = 0;											/* picker will be centered */
		savedColor = (RGBColor**)GetResource('RGBv', BALLCOLOR_RGBV);	/* get the old color */
		if(!savedColor)
			return ResError();
		beforeColor = **savedColor;
		newColorChosen = GetColor(where, "\pBouncing ball color?", &beforeColor, &afterColor);
		if(newColorChosen) {
			/* save the new color to our resource */
			**savedColor = afterColor;
			ChangedResource((Handle)savedColor);
			WriteResource((Handle)savedColor);
		}
		ReleaseResource((Handle)savedColor);
		break;
	default:
		SysBeep(1);
		break;
	}
	return noErr;
}

/* utility functions. */

static short
bbrandom(short lower, short upper)
{
	short middle = (lower+upper)/2;
	short randValue = middle + (Random() % (upper - middle));
	if(randValue < lower)
		return lower;
	if(randValue > upper)
		return upper;
	return randValue;
}

/*
 *	Fixed RandomAngle(short lower, short upper);
 *	lower and upper are expressed in degrees, an angle in Fixed point radians between
 *	lower and upper is returned.
 */

#define PI_OVER_4	0xC910L						/* PI/4 expressed in fixed point. */

static Fixed
RandomAngle(short lower, short upper)
{
	return FixDiv(FixMul(Long2Fix(bbrandom(lower, upper)),PI_OVER_4), Long2Fix(45));
}

static void
WatchCursor()
{
	CursHandle theCursor = GetCursor(watchCursor);
	if(theCursor) {
		SetCursor(*theCursor);
		ReleaseResource((Handle)theCursor);
	}
}
