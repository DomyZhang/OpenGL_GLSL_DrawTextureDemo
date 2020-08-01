//
//  ViewController.m
//  GL_Demo_GLSL
//
//  Created by Domy on 2020/7/30.
//  Copyright © 2020 Domy. All rights reserved.
//

#import "ViewController.h"
#import "MyGLSLView.h"

@interface ViewController ()

@property (nonatomic, strong) MyGLSLView *myView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.myView = (MyGLSLView *)self.view;

}


@end
