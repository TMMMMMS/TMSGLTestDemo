//
//  CustomViewController.m
//  TMSGLTestDemo
//
//  Created by TMMMS on 2021/6/18.
//

#import "CustomViewController.h"
#import "TMSGLKView.h"

@interface CustomViewController ()

@end

@implementation CustomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    TMSGLKView *view = [[TMSGLKView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [self.view addSubview:view];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    NSLog(@"%@-dealloc", NSStringFromClass(self.class));
}

@end
