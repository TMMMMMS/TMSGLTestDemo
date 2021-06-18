//
//  AppDelegate.m
//  TMSGLTestDemo
//
//  Created by TMMMS on 2021/6/18.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // 创建Window
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    // 创建ViewController
    UIViewController *vc = [[ViewController alloc] init];

    // 给vc的view上个颜色
    vc.view.backgroundColor = [UIColor orangeColor];

    // 设置Window的rootViewController
    self.window.rootViewController = vc;

    // 最重要的最后一步让window可见
    [self.window makeKeyAndVisible];
    
    return YES;
}



@end
