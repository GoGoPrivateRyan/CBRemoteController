//
//  ViewController.h
//  CBRemoteController
//
//  Created by Ryan Tseng on 2014/11/7.
//  Copyright (c) 2014年 RyanTseng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "Services.h"

@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (weak, nonatomic) IBOutlet UILabel *lblLampStatus;
@property (weak, nonatomic) IBOutlet UIImageView *imgLampStatus;
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *discoveredPeripheral;

- (IBAction)btnOnPressed;
- (IBAction)btnOffPressed;

@end

