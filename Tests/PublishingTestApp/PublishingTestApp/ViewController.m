//
//  ViewController.m
//  PublishingTestApp
//
//  Created by Pavel Yankelevich on 16/09/2015.
//  Copyright (c) 2015 Pavel Yankelevich. All rights reserved.
//

#import "ViewController.h"
#import "SVProgressHUD.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [SVProgressHUD show];
}

@end
