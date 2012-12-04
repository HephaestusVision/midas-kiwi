//
//  SceneSettingsController.h
//  KiwiMidas
//
//  Created by Pat Marion on 11/5/12.
//  Copyright (c) 2012 Pat Marion. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SceneSettingsController : UITableViewController

  -(IBAction) onPointSizeChanged:(id) sender;
  -(IBAction) onLineWidthChanged:(id) sender;

  @property (nonatomic, retain) IBOutlet UISlider *pointSizeSlider;
  @property (nonatomic, retain) IBOutlet UISlider *lineWidthSlider;

  @property (nonatomic, retain) IBOutlet UILabel *vertexCountLabel;
  @property (nonatomic, retain) IBOutlet UILabel *cellCountLabel;
  @property (nonatomic, retain) IBOutlet UILabel *fpsLabel;

@end
