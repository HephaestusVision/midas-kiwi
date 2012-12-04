//
//  SceneSettingsController.m
//  KiwiMidas
//
//  Created by Pat Marion on 11/5/12.
//  Copyright (c) 2012 Pat Marion. All rights reserved.
//

#import "SceneSettingsController.h"

@interface SceneSettingsController ()

@end

@implementation SceneSettingsController

@synthesize lineWidthSlider;
@synthesize pointSizeSlider;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

  int pointSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"PointSize"];
  int lineWidth = [[NSUserDefaults standardUserDefaults] integerForKey:@"LineWidth"];
  
  [self.pointSizeSlider setValue:pointSize animated:NO];
  [self.lineWidthSlider setValue:lineWidth animated:NO];
}


-(IBAction) onPointSizeChanged:(id) sender
{
  int pointSize = self.pointSizeSlider.value;
  [[NSUserDefaults standardUserDefaults] setInteger:pointSize forKey:@"PointSize"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"OnPointSizeChanged" object:nil];
}


-(IBAction) onLineWidthChanged:(id) sender
{
  int lineWidth = self.lineWidthSlider.value;
  [[NSUserDefaults standardUserDefaults] setInteger:lineWidth forKey:@"LineWidth"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"OnLineWidthChanged" object:nil];
}


@end
