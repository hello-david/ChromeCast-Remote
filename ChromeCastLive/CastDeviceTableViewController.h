//
//  CastDeviceTableViewController.h
//  ChromeCastLive
//
//  Created by David.Dai on 16/9/20.
//  Copyright © 2016年 David.Dai. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DeviceTableViewControllerDelegate <NSObject>

- (GCKDeviceScanner *)deviceScanner;
- (GCKDeviceManager *)deviceManager;
- (void)connectToDevice:(GCKDevice *)device;

@optional
- (void)disconnect;

@end

@interface CastDeviceTableViewController : UITableViewController

@property(nonatomic, weak) id<DeviceTableViewControllerDelegate> delegate;
@property(nonatomic, weak) UIViewController *viewController;

@end
