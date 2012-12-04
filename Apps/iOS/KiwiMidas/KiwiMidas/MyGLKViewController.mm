//
//  MyGLKViewController.m
//  CloudAppGL
//
//  Created by Pat Marion on 9/29/12.
//  Copyright (c) 2012 Pat Marion. All rights reserved.
//

#import "MyGLKViewController.h"
#import "MyGestureHandler.h"
#import "PVRemoteViewController.h"
#import "SceneSettingsController.h"

#include "kiwiCloudApp.h"
#include "vesKiwiFPSCounter.h"


@interface loadDataHelper : NSObject {

  @public
  kiwiApp::Ptr mKiwiApp;
  UIAlertView* waitDialog;

  SEL postSelector;
  NSObject* target;

  NSTimer* waitTimer;

}
@end

@implementation loadDataHelper

- (void)showAlertDialogWithTitle:(NSString *)alertTitle message:(NSString *)alertMessage;
{

  UIAlertView *alert = [[UIAlertView alloc]
                        initWithTitle:alertTitle
                        message:alertMessage
                        delegate:nil
                        cancelButtonTitle:@"Ok"
                        otherButtonTitles: nil, nil];
  [alert show];
}


-(void) showErrorDialog
{
  NSString* errorTitle = [NSString stringWithUTF8String:mKiwiApp->loadDatasetErrorTitle().c_str()];
  NSString* errorMessage = [NSString stringWithUTF8String:mKiwiApp->loadDatasetErrorMessage().c_str()];
  [self showAlertDialogWithTitle:errorTitle message:errorMessage];
}

-(void) showWaitDialogWithMessage:(NSString*) message
{
  if (self->waitDialog != nil) {
    self->waitDialog.title = message;
    return;
  }

  self->waitDialog = [[UIAlertView alloc]
    initWithTitle:message message:nil
    delegate:nil cancelButtonTitle:nil otherButtonTitles: nil];

  [self->waitDialog show];
  
  UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  indicator.center = CGPointMake(self->waitDialog.bounds.size.width * 0.5f, self->waitDialog.bounds.size.height * 0.5f);
  [indicator startAnimating];
  [self->waitDialog addSubview:indicator];  
}

-(void) showWaitDialog
{
  [self showWaitDialogWithMessage:@"Please Wait..."];
}

-(void) dismissWaitDialog
{
  [self->waitTimer invalidate];
  if (self->waitDialog == nil) {
    return;
  }
  [self->waitDialog dismissWithClickedButtonIndex:0 animated:YES];
  self->waitDialog = nil;
}

-(void) postLoadDataset:(NSString*)filename result:(BOOL)result
{
  [self dismissWaitDialog];
  if (!result) {
    [self showErrorDialog];
    //return;
  }

  NSLog(@"have target: %@", self->target);
  [self->target performSelector:self->postSelector];
}

-(BOOL) loadDatasetWithPath:(NSString*)path
{
  NSLog(@"load dataset: %@", path);

  self->waitTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(showWaitDialog) userInfo:nil repeats:NO];

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

    //for (int i = 0; i < 5; ++i) {
    //  NSLog(@"sleep...");
    //  [NSThread sleepForTimeInterval:1.0];
    //}

    bool result = mKiwiApp->loadDataset([path UTF8String]);

    dispatch_async(dispatch_get_main_queue(), ^{
      [self postLoadDataset:path result:result];
    });
  });

  return YES;
}


-(BOOL) doPVRemoteControl:(NSDictionary*) args
{

  NSLog(@"doPVRemoteControl");
  self->waitTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(showWaitDialog) userInfo:nil repeats:NO];

  PVRemoteViewController* pvRemoteView = (PVRemoteViewController*)[args objectForKey:@"viewController"];

  NSString* hostText = [[NSUserDefaults standardUserDefaults] stringForKey:@"PVRemoteHost"];

  std::string host = [hostText UTF8String];
  int port = 40000;

  //std::string::const_iterator pos = std::find(string.begin(), string.end(), ':');
  //std::string left(str.begin(), pos);
  //std::string right(pos + 1, str.end());

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{


    bool result = self->mKiwiApp->doPVRemote(host, port);

    dispatch_async(dispatch_get_main_queue(), ^{
    
      [self postLoadDataset:nil result:result];
      if (result) {
        [pvRemoteView dismissViewControllerAnimated:YES completion:nil];
      }

    });
  });

  return YES;
}

@end




@interface MyGLKViewController () {


  kiwiApp::Ptr mKiwiApp;
  vesKiwiFPSCounter mFPSCounter;
  
  MyGestureHandler* mGestureHandler;
  
  __weak UIPopoverController *myPopover;

}

@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

@end

@implementation MyGLKViewController

@synthesize settingsButton;
@synthesize toolbar;
@synthesize leftLabel;
@synthesize rightLabel;

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

  if (!self.context) {
      NSLog(@"Failed to create ES context");
  }

  GLKView *view = (GLKView *)self.view;
  view.context = self.context;
  view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
  [self onMultisamplingChanged];

  [self createDefaultApp];
  [self initializeGestureHandler];

  [self populateToolbar];

  [self onLineWidthChanged];
  [self onPointSizeChanged];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMultisamplingChanged)
                                        name:@"EnableMultisamplingChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPointSizeChanged)
                                        name:@"OnPointSizeChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLineWidthChanged)
                                        name:@"OnLineWidthChanged" object:nil];
}

-(void) clearToolbar
{
  NSMutableArray *items = [NSMutableArray new];
  [self.toolbar setItems:[items copy] animated:NO];
}

- (void) populateToolbar
{
  std::vector<std::string> actions = self->mKiwiApp->actions();

  NSMutableArray *items = [NSMutableArray arrayWithCapacity:actions.size()];

  for (size_t i = 0; i < actions.size(); ++i) {

    printf("adding action: %s\n", actions[i].c_str());
    UIBarButtonItem * actionButton = [[UIBarButtonItem alloc]
      initWithTitle:[NSString stringWithUTF8String:actions[i].c_str()]
      style:UIBarButtonItemStyleBordered
      target:self
      action:@selector(onAction:)];

    [items addObject:actionButton];
  }


  [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                            target:nil action:nil]];
  [items addObject:settingsButton];
  [self.toolbar setItems:[items copy] animated:NO];
}

-(void) onAction:(UIBarButtonItem*)button
{
  std::string action = [button.title UTF8String];
  if (self->mKiwiApp) {
    self->mKiwiApp->onAction(action);
  }
}

-(void) onMultisamplingChanged
{
  GLKView *view = (GLKView *)self.view;
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"EnableMultisampling"]) {
    view.drawableMultisample = GLKViewDrawableMultisample4X;
  }
  else {
    view.drawableMultisample = GLKViewDrawableMultisampleNone;
  }
}

-(void) onPointSizeChanged
{
  int pointSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"PointSize"];
  self->mKiwiApp->setPointSize(pointSize);
}

-(void) onLineWidthChanged
{
  int lineWidth = [[NSUserDefaults standardUserDefaults] integerForKey:@"LineWidth"];
  self->mKiwiApp->setLineWidth(lineWidth);
}

-(void) updateSceneStatistics
{
  int vertexCount = mKiwiApp->numberOfModelVertices();
  int cellCount = mKiwiApp->numberOfModelFacets() + mKiwiApp->numberOfModelLines();
  int fps = static_cast<int>(floor(mFPSCounter.averageFPS() + 0.5));

  SceneSettingsController* sceneSettings = (SceneSettingsController*)(myPopover.contentViewController);
  sceneSettings.vertexCountLabel.text = [[NSNumber numberWithInt:vertexCount] stringValue];
  sceneSettings.cellCountLabel.text = [[NSNumber numberWithInt:cellCount] stringValue];
  sceneSettings.fpsLabel.text = [[NSNumber numberWithInt:fps] stringValue];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  myPopover = [(UIStoryboardPopoverSegue *)segue popoverController];
  myPopover.delegate = self;

  [self updateSceneStatistics];
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
  return YES;
}


- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {

  if (myPopover) {
    [myPopover dismissPopoverAnimated:YES];
    return NO;
  }
  else {
    return YES;
  }
}

-(void) deleteApp
{
  self->mGestureHandler.kiwiApp.reset();
  self->mKiwiApp.reset();
}

-(void) setApp:(kiwiApp::Ptr) app
{
  self->mGestureHandler.kiwiApp = app;
  self->mKiwiApp = app;
}

-(void) doPVWebDemo
{
  std::string host = "paraviewweb.kitware.com";
  std::string sessionId = "91364400c0b431fa35d7dbf0bbd84d27-844";

  self->mKiwiApp->doPVWebTest(host, sessionId);
}

-(void) doPointCloudStreamingDemo
{
  std::string host = "trisol.local";
  int port = 11111;

  [self deleteApp];

  vesKiwiPointCloudApp::Ptr streamingApp = vesKiwiPointCloudApp::Ptr(new vesKiwiPointCloudApp);
  streamingApp->setHost(host);
  streamingApp->setPort(port);

  [self setApp:streamingApp];
  [self setupGL];
}

-(void) createDefaultApp
{
  [self deleteApp];
  kiwiCloudApp::Ptr app = kiwiCloudApp::Ptr(new kiwiCloudApp);
  [self setApp:app];
  [self setupGL];
}

-(void) postLoadDataset
{
  NSLog(@"MyGLKViewController::postLoadDataset");

  [self populateToolbar];
  self.paused = NO;
  //self.view.hidden = NO;

  self->mKiwiApp->resetView();  
}

-(void) handleArgs:(NSDictionary*) args
{

  NSString* dataset = [args objectForKey:@"dataset"];  
  if (!dataset) {
    return;
  }
  
  [self clearToolbar];

  if ([dataset isEqualToString:@"ParaView Web"]) {
    [self doPVWebDemo];
    return;
  }
  else if ([dataset isEqualToString:@"Point Cloud Streaming Demo"]) {
    [self doPointCloudStreamingDemo];
    return;
  }


  [self createDefaultApp];


  NSLog(@"pause rendering");
  self.paused = YES;
  
  loadDataHelper* helper = [loadDataHelper new];
  helper->mKiwiApp = self->mKiwiApp;
  helper->target = self;
  helper->postSelector = @selector(postLoadDataset);


  if ([dataset isEqualToString:@"ParaView Mobile Remote Control"]) {
    [helper doPVRemoteControl:args];
  }
  else {
    [helper loadDatasetWithPath:dataset];
  }


}

-(void) initializeGestureHandler
{
  self->mGestureHandler = [[MyGestureHandler alloc] init];
  self->mGestureHandler.view = self.view;
  self->mGestureHandler.kiwiApp = self->mKiwiApp;
  [self->mGestureHandler createGestureRecognizers];
}


- (void)dealloc
{    
  [self tearDownGL];
  
  if ([EAGLContext currentContext] == self.context) {
      [EAGLContext setCurrentContext:nil];
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];

  if ([self isViewLoaded] && ([[self view] window] == nil)) {
    self.view = nil;
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
  }

  // Dispose of any resources that can be recreated.
}

- (void)setupGL
{
  [EAGLContext setCurrentContext:self.context];  
  self->mKiwiApp->initGL();
  self->mKiwiApp->resizeView(self.view.bounds.size.width, self.view.bounds.size.height);
  self->mKiwiApp->setDefaultBackgroundColor();
}

- (void)tearDownGL
{
  [EAGLContext setCurrentContext:self.context];

  // free GL resources
  // ...
}


- (void)viewWillLayoutSubviews
{
  self->mKiwiApp->resizeView(self.view.bounds.size.width, self.view.bounds.size.height);
}

#pragma mark - GLKView and GLKViewController delegate methods


- (void)update
{
  //double elapsedTime = self.timeSinceLastUpdate;

  if (self->mKiwiApp) {
    std::string leftText = self->mKiwiApp->leftText();
    std::string rightText = self->mKiwiApp->rightText();
    self.leftLabel.text = [NSString stringWithUTF8String:leftText.c_str()];
    self.rightLabel.text = [NSString stringWithUTF8String:rightText.c_str()];
  }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{

  if (!self->mKiwiApp) {
    NSLog(@"draw called with nil app");
  }
  if (self.paused) {
    NSLog(@"draw called while paused");
  }


  if (self->mKiwiApp && !self.paused) {
    self->mKiwiApp->render();
    mFPSCounter.update();
  }

}

@end