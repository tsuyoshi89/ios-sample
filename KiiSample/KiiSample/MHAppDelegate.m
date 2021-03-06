//
//  MHAppDelegate.m
//  KiiSample
//
//  Created by tsuyoshi on 2013/11/27.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import "MHKiiHelper.h"

#import "MHAppDelegate.h"
#import "MHViewController.h"
#import "KiiManager.h"

@implementation MHAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
#define YOUR_FACEBOOK_APP_ID @"255846174568822"
#if 0
#define YOUR_KII_APP_ID @"b1de7c54"
#define YOUR_KII_APP_KEY @"aad3dfa037b9189f1cb4569ec154e865"
#else//emon schat2
#define YOUR_KII_APP_ID @"38ef21a6"
#define YOUR_KII_APP_KEY @"9b2377bf742b390e6f88003f403b7386"
#endif

    NSLog(@"sub:%@", [KiiError errorWithCode:@"test" andMessage:@"message-test"]);
    
    [MHKiiHelper beginWithID:YOUR_KII_APP_ID
                      andKey:YOUR_KII_APP_KEY
                     andSite:kiiSiteJP
               andFacebookID:YOUR_FACEBOOK_APP_ID];
    
    [MHKiiHelper sharedInstance].delegate = [KiiManager sharedInstance];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UINavigationController *vc = [[UINavigationController alloc] init];
    self.window.rootViewController = vc;
    [vc pushViewController:[[MHViewController alloc]init] animated:NO];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    return [KiiSocialConnect handleOpenURL:url];
}
@end
