//
//  ViewController.m
//  CBRemoteController
//
//  Created by Ryan Tseng on 2014/11/7.
//  Copyright (c) 2014年 RyanTseng. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize imgLampStatus;
@synthesize lblLampStatus;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [_centralManager stopScan];
    NSLog(@"Scanning stopped");
    lblLampStatus.text = @"Scanning stopped";
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    // You should test all scenarios
    if (central.state != CBCentralManagerStatePoweredOn) {
        return;
    }
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        // Scan for devices
        [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
        NSLog(@"Scanning started");
        lblLampStatus.text = @"Scanning started";
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    lblLampStatus.text = [NSString stringWithFormat:@"Discovered %@ at %@", peripheral.name, RSSI];
    
    if (_discoveredPeripheral != peripheral) {
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        _discoveredPeripheral = peripheral;
        
        // And connect
        NSLog(@"Connecting to peripheral %@", peripheral);
        lblLampStatus.text = [NSString stringWithFormat:@"Connecting to peripheral %@", peripheral];
        [_centralManager connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect");
    lblLampStatus.text = @"Failed to connect";
    [self cleanup];
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected");
    lblLampStatus.text = @"Connected";
    
    [_centralManager stopScan];
    NSLog(@"Scanning stopped");
    lblLampStatus.text = @"Scanning stopped";
    
    peripheral.delegate = self;
    [peripheral discoverServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        [self cleanup];
        return;
    }
    
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CHARACTERISTIC_UUID]] forService:service];
    }
    // Discover other characteristics
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        [self cleanup];
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_UUID]]) {
            NSLog(@"Reading value for characteristic %@", CHARACTERISTIC_UUID);
            lblLampStatus.text = [NSString stringWithFormat:@"Reading value for characteristic %@", CHARACTERISTIC_UUID];
            // to know the characteristic value initial state
            [peripheral readValueForCharacteristic:characteristic];
            
            //[peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error");
        lblLampStatus.text = @"Error";
        return;
    }
    
    //NSString *value1 = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    //NSLog(@"Value %@",value1);
    
    int value = 0;
    [characteristic.value getBytes:&value length:characteristic.value.length];
    
    // Have we got everything we need?
    if (value) {
        imgLampStatus.image = [UIImage imageNamed:@"bulb_5.png"];
    }
    else {
        imgLampStatus.image = [UIImage imageNamed:@"bulb_6.png"];
    }
    
    
//        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        
//        [_centralManager cancelPeripheralConnection:peripheral];
//    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_UUID]]) {
        return;
    }
    
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
        lblLampStatus.text = [NSString stringWithFormat:@"Notification began on %@", characteristic];

    } else {
        // Notification has stopped
        [_centralManager cancelPeripheralConnection:peripheral];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error writing characteristic value: %@", [error localizedDescription]);
        lblLampStatus.text = [NSString stringWithFormat:@"Error writing characteristic value: %@", [error localizedDescription]];
    }
    
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    _discoveredPeripheral = nil;
    
    [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
}

- (void)cleanup {
    
    // See if we are subscribed to a characteristic on the peripheral
    if (_discoveredPeripheral.services != nil) {
        for (CBService *service in _discoveredPeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_UUID]]) {
                        if (characteristic.isNotifying) {
                            [_discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            return;
                        }
                    }
                }
            }
        }
    }
    
    [_centralManager cancelPeripheralConnection:_discoveredPeripheral];
}

-(void)writeCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID data:(NSData *)data {
    // Sends data to BLE peripheral to process HID and send EHIF command to PC
    for ( CBService *service in peripheral.services ) {
        
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]]) {
            
            for ( CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]]) {
                    // EVERYTHING IS FOUND, WRITE characteristic!
                    [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                    
                    // make sure the received characteristic value and then update status image
                    [peripheral readValueForCharacteristic:characteristic];
                    
                }
            }
        }
    }
}


- (IBAction)btnOnPressed {
    NSLog(@"btnOn Pressed!");
    lblLampStatus.text = @"btnOn Pressed!";
    char dataByte = 1;
    [self writeCharacteristic:_discoveredPeripheral sUUID:SERVICE_UUID cUUID:CHARACTERISTIC_UUID data:[NSData dataWithBytes:&dataByte length:1]];

}

- (IBAction)btnOffPressed {
    NSLog(@"btnOff Pressed!");
    lblLampStatus.text = @"btnOff Pressed!";
    char dataByte = 0;
    [self writeCharacteristic:_discoveredPeripheral sUUID:SERVICE_UUID cUUID:CHARACTERISTIC_UUID data:[NSData dataWithBytes:&dataByte length:1]];
    
}


@end
