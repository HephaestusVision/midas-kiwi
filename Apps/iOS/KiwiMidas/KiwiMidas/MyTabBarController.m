//
//  MyTabBarController.m
//  CloudAppTab
//
//  Created by Pat Marion on 10/8/12.
//  Copyright (c) 2012 Pat Marion. All rights reserved.
//

#import "MyTabBarController.h"
#import "MyGLKViewController.h"




#import "mach/mach.h" 

// implementation from: http://stackoverflow.com/questions/7989864/watching-memory-usage-in-ios

vm_size_t usedMemory()
{
  struct task_basic_info info;
  mach_msg_type_number_t size = sizeof(info);
  kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
  return (kerr == KERN_SUCCESS) ? info.resident_size : 0; // size in bytes
}

vm_size_t freeMemory()
{
  mach_port_t host_port = mach_host_self();
  mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
  vm_size_t pagesize;
  vm_statistics_data_t vm_stat;

  host_page_size(host_port, &pagesize);
  (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
  return vm_stat.free_count * pagesize;
}

void logMemoryUsage()
{
  static long prevMemUsage = 0;
  long curMemUsage = usedMemory();
  long memUsageDiff = curMemUsage - prevMemUsage;
  prevMemUsage = curMemUsage;

  double bytesToMb = 1.0/(1024.0*1024.0);

  if (abs(memUsageDiff) > 1024*1024)
  {
    NSLog(@"Memory used %.2f mb (+%.2f mb), free %.2f mb", curMemUsage*bytesToMb, memUsageDiff*bytesToMb, freeMemory()*bytesToMb);
  }
}


@interface MyTabBarController ()

  @property (strong) NSTimer* timer;

@end

@implementation MyTabBarController

@synthesize timer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


-(void) memoryUsageCallback
{
  logMemoryUsage();
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToRenderView:) name:@"switchToRenderView" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doPVRemote:) name:@"ParaView Mobile Remote Control" object:nil];

  self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
            selector:@selector(memoryUsageCallback) userInfo:nil repeats:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)switchToRenderView:(NSNotification*)notification
{
  NSDictionary* userInfo = notification.userInfo;

  const int glViewIndex = 1;

  self.selectedIndex = glViewIndex;
  MyGLKViewController* glkView = (MyGLKViewController*)self.selectedViewController;
  [glkView handleArgs:userInfo];
}

-(void)doPVRemote:(NSNotification*)notification
{
  [self performSegueWithIdentifier: @"gotoPVRemoteScreen" sender: self];
}

@end
