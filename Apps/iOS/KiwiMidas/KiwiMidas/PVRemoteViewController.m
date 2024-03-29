//
//  PVRemoteViewController.m
//  KiwiMidas
//
//  Created by Pat Marion on 12/5/12.
//  Copyright (c) 2012 Pat Marion. All rights reserved.
//

#import "PVRemoteViewController.h"

@interface PVRemoteViewController ()

@end

@implementation PVRemoteViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.hostText.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"PVRemoteHost"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showAlertDialogWithTitle:(NSString *)alertTitle message:(NSString *)alertMessage;
{

  UIAlertView *alert = [[UIAlertView alloc]
                        initWithTitle:alertTitle
                        message:alertMessage
                        delegate:self
                        cancelButtonTitle:@"Ok"
                        otherButtonTitles: nil, nil];
  [alert show];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (textField == self.hostText) {
    [textField resignFirstResponder];
  }
  return YES;
}

-(void)showError
{
    NSString* title = @"Connection Failed";
    NSString* message = @"Failed to connect to the ParaView host.";
    [self showAlertDialogWithTitle:title message:message];
}

-(IBAction)onHelpTouched:(id)sender
{
  NSString* docPage = @"http://vtk.org/Wiki/VES/ParaView_Mobile_Remote_Control";
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:docPage]];
}


-(IBAction)onCancelTouched:(id)sender
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction) onConnectTouched: (id) sender {

  NSString* host = self.hostText.text;

  if (!host.length) {
    [self showAlertDialogWithTitle:@"Missing host" message:@"Please enter the host name."];
    return;
  }

  [[NSUserDefaults standardUserDefaults] setObject:host forKey:@"PVRemoteHost"];
  [[NSUserDefaults standardUserDefaults] synchronize];

  NSDictionary* args = [NSDictionary dictionaryWithObjectsAndKeys:@"ParaView Mobile Remote Control", @"dataset", self, @"viewController", nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"switchToRenderView" object:nil userInfo:args];
}

@end
