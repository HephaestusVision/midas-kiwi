/*========================================================================
  VES --- VTK OpenGL ES Rendering Toolkit

      http://www.kitware.com/ves

  Copyright 2011 Kitware, Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
 ========================================================================*/
#import "MyGestureHandler.h"

#include <vesKiwiViewerApp.h>

@interface MyGestureDelegate : NSObject <UIGestureRecognizerDelegate>{

}
@end

@implementation MyGestureDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
  return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
  BOOL rotating2D =
  [gestureRecognizer isMemberOfClass:[UIRotationGestureRecognizer class]] ||
  [otherGestureRecognizer isMemberOfClass:[UIRotationGestureRecognizer class]];

  BOOL pinching =
  [gestureRecognizer isMemberOfClass:[UIPinchGestureRecognizer class]] ||
  [otherGestureRecognizer isMemberOfClass:[UIPinchGestureRecognizer class]];

  BOOL panning =
  [gestureRecognizer numberOfTouches] == 2 &&
  ([gestureRecognizer isMemberOfClass:[UIPanGestureRecognizer class]] ||
   [otherGestureRecognizer isMemberOfClass:[UIPanGestureRecognizer class]]);

  if ((pinching && panning) ||
      (pinching && rotating2D) ||
      (panning && rotating2D))
    {
    return YES;
    }
  return NO;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  if ([touch.view isKindOfClass:[UIControl class]]
      || [touch.view isKindOfClass:[UIBarItem class]]
      || [touch.view isKindOfClass:[UIToolbar class]]) {
    return NO;
  }
  return YES;
}
@end


@interface MyGestureHandler () {

  MyGestureDelegate* mGestureDelegate;
}

@end

@implementation MyGestureHandler

@synthesize view;
@synthesize kiwiApp;

- (void)createGestureRecognizers
{
  UIPanGestureRecognizer *singleFingerPanGesture = [[UIPanGestureRecognizer alloc]
                                                    initWithTarget:self action:@selector(handleSingleFingerPanGesture:)];
  [singleFingerPanGesture setMinimumNumberOfTouches:1];
  [singleFingerPanGesture setMaximumNumberOfTouches:1];
  [self.view addGestureRecognizer:singleFingerPanGesture];

  UIPanGestureRecognizer *doubleFingerPanGesture = [[UIPanGestureRecognizer alloc]
                                                    initWithTarget:self action:@selector(handleDoubleFingerPanGesture:)];
  [doubleFingerPanGesture setMinimumNumberOfTouches:2];
  [doubleFingerPanGesture setMaximumNumberOfTouches:2];
  [self.view addGestureRecognizer:doubleFingerPanGesture];


  UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]
                                            initWithTarget:self action:@selector(handlePinchGesture:)];
  [self.view addGestureRecognizer:pinchGesture];


  UIRotationGestureRecognizer *rotate2DGesture = [[UIRotationGestureRecognizer alloc]
                                                  initWithTarget:self action:@selector(handle2DRotationGesture:)];
  [self.view addGestureRecognizer:rotate2DGesture];


  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(handleTapGesture:)];
  tapGesture.numberOfTapsRequired = 1;
  [self.view addGestureRecognizer:tapGesture];


  UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(handleDoubleTapGesture:)];
  doubleTapGesture.numberOfTapsRequired = 2;
  [self.view addGestureRecognizer:doubleTapGesture];
  [tapGesture requireGestureRecognizerToFail:doubleTapGesture];


  UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc]
                                              initWithTarget:self action:@selector(handleLongPress:)];
  [self.view addGestureRecognizer:longPress];


  //
  // allow two-finger gestures to work simultaneously
  MyGestureDelegate* gestureDelegate = [[MyGestureDelegate alloc] init];
  [rotate2DGesture setDelegate:gestureDelegate];
  [pinchGesture setDelegate:gestureDelegate];
  [doubleFingerPanGesture setDelegate:gestureDelegate];

  [singleFingerPanGesture setDelegate:gestureDelegate];
  [tapGesture setDelegate:gestureDelegate];
  [doubleTapGesture setDelegate:gestureDelegate];

  self->mGestureDelegate = gestureDelegate;

  [tapGesture setDelegate:gestureDelegate];
  [doubleTapGesture setDelegate:gestureDelegate];
}

- (IBAction)handleSingleFingerPanGesture:(UIPanGestureRecognizer *)sender
{
  if (sender.state == UIGestureRecognizerStateEnded ||
      sender.state == UIGestureRecognizerStateCancelled)
    {
    self.kiwiApp->handleSingleTouchUp();
    return;
    }

  //
  // get current translation and (then zero it out so it won't accumulate)
  CGPoint currentTranslation = [sender translationInView:self.view];
  CGPoint currentLocation = [sender locationInView:self.view];
  [sender setTranslation:CGPointZero inView:self.view];

  if (sender.state == UIGestureRecognizerStateBegan)
    {
    self.kiwiApp->handleSingleTouchDown(currentLocation.x, currentLocation.y);
    return;
    }

  self.kiwiApp->handleSingleTouchPanGesture(currentTranslation.x, currentTranslation.y);
}

- (IBAction)handleDoubleFingerPanGesture:(UIPanGestureRecognizer *)sender
{
  if (sender.state == UIGestureRecognizerStateEnded ||
      sender.state == UIGestureRecognizerStateCancelled)
    {
    return;
    }

  //
  // get current translation and (then zero it out so it won't accumulate)
  CGPoint currentLocation = [sender locationInView:self.view];
  CGPoint currentTranslation = [sender translationInView:self.view];
  [sender setTranslation:CGPointZero inView:self.view];

  //
  // compute the previous location (have to flip y)
  CGPoint previousLocation;
  previousLocation.x = currentLocation.x - currentTranslation.x;
  previousLocation.y = currentLocation.y + currentTranslation.y;

  self.kiwiApp->handleTwoTouchPanGesture(previousLocation.x, previousLocation.y, currentLocation.x, currentLocation.y);
}

- (IBAction)handlePinchGesture:(UIPinchGestureRecognizer *)sender
{
  if (sender.state == UIGestureRecognizerStateEnded ||
      sender.state == UIGestureRecognizerStateCancelled)
    {
    return;
    }

  self.kiwiApp->handleTwoTouchPinchGesture(sender.scale);

  //
  // reset scale so it won't accumulate
  sender.scale = 1.0;
}

- (IBAction)handle2DRotationGesture:(UIRotationGestureRecognizer *)sender
{
  if (sender.state == UIGestureRecognizerStateEnded ||
      sender.state == UIGestureRecognizerStateCancelled)
    {
    return;
    }

  self.kiwiApp->handleTwoTouchRotationGesture(sender.rotation);

  //
  // reset rotation so it won't accumulate
  [sender setRotation:0.0];
}

- (IBAction)handleDoubleTapGesture:(UITapGestureRecognizer *)sender
{
  CGPoint currentLocation = [sender locationInView:self.view];
  self.kiwiApp->handleDoubleTap(currentLocation.x, currentLocation.y);
}

- (IBAction)handleTapGesture:(UITapGestureRecognizer *)sender
{
  CGPoint currentLocation = [sender locationInView:self.view];
  self.kiwiApp->handleSingleTouchTap(currentLocation.x, currentLocation.y);
}

- (IBAction)handleLongPress:(UITapGestureRecognizer *)sender
{
  CGPoint currentLocation = [sender locationInView:self.view];
  self.kiwiApp->handleLongPress(currentLocation.x, currentLocation.y);
}


@end
