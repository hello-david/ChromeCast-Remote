//
//  CastDeviceTableViewController.m
//  ChromeCastLive
//
//  Created by David.Dai on 16/9/20.
//  Copyright © 2016年 David.Dai. All rights reserved.
//

#import "CastDeviceTableViewController.h"

@interface CastDeviceTableViewController ()

@end

typedef NS_ENUM(NSInteger,kLAChromeCastTableSection) {
    kLAChromeCastTableSectionCastDevice = 0,
    kLAChromeCastTableSectionVersion    = 1
};

typedef NS_ENUM(NSInteger,kLACastDeviceSection) {
    kLACastDeviceSectionVolume        = 0,
    kLACastDeviceSectionDisconnect    = 1
};

static NSString * const kVersionFooter = @"v";

@implementation CastDeviceTableViewController
{
    BOOL             _isManualVolumeChange;
    UISlider         *_volumeSlider;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    if(self = [super initWithStyle:style])
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (_delegate.deviceScanner){
        _delegate.deviceScanner.passiveScan = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(volumeDidChange)
                                                 name:kChromeCastVolumeChanged
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scanDidChange)
                                                 name:kChromeCastScanChange
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (_delegate.deviceScanner)
    {
        // Enable passive scan after the user has finished interacting.
        _delegate.deviceScanner.passiveScan = YES;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)scanDidChange
{
    [self.tableView reloadData];
}

#pragma mark ------------------------ Table view data source ------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kLAChromeCastTableSectionVersion) {
        return 1;
    }
    
    else if(section == kLAChromeCastTableSectionCastDevice)
    {
        if (_delegate.deviceManager.applicationConnectionState != GCKConnectionStateConnected)
        {
            self.title = @"Connect to";
            return _delegate.deviceScanner.devices.count;
        }
        
        else
        {
            self.title = [NSString stringWithFormat:@"%@", _delegate.deviceManager.device.friendlyName];
            return 2;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView versionCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdForVersion = @"version";
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdForVersion];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    NSString *ver = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    [cell.textLabel setText:[NSString stringWithFormat:@"%@ %@", kVersionFooter, ver]];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView deviceCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdForDeviceName = @"deviceName";
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdForDeviceName];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    GCKDevice *device = nil;
    if(_delegate.deviceScanner.devices.count)
        device = [_delegate.deviceScanner.devices objectAtIndex:indexPath.row];
    cell.textLabel.text = device.friendlyName;
    cell.detailTextLabel.text = device.statusText ? device.statusText : device.modelName;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView volumeCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdForVolumeControl = @"volumeController";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdForVolumeControl];
    
    UIView *view = [[UIView alloc]init];
    [cell addSubview:view];
    [view makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(cell);
        make.top.bottom.equalTo(cell);
    }];
    
    UIImageView *volumeNone = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"icon_volume0"]];
    [view addSubview:volumeNone];
    [volumeNone makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(view).with.offset(5);
        make.top.equalTo(view);
        make.width.height.equalTo(@30);
        make.centerY.equalTo(view);
    }];
    
    UIImageView *volumeFull = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"icon_volume2"]];
    [view addSubview:volumeFull];
    [volumeFull makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(view).with.offset(-5);
        make.top.equalTo(view);
        make.width.height.equalTo(@30);
        make.centerY.equalTo(view);
    }];
    
    _volumeSlider = [[UISlider alloc] init];
    [view addSubview:_volumeSlider];
    [_volumeSlider makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(volumeFull.left).with.offset(-10);
        make.left.equalTo(volumeNone.right).with.offset(10);
        make.height.equalTo(view);
        make.centerY.equalTo(view);
    }];
    _volumeSlider.minimumValue = 0;
    _volumeSlider.maximumValue = 1.0;
    _volumeSlider.value = _delegate.deviceManager.deviceVolume;
    _volumeSlider.continuous = NO;
    [_volumeSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdForDisconnectButton  = @"disconnectButton";
    UITableViewCell *cell = nil ;
    
    if (indexPath.section == kLAChromeCastTableSectionVersion)
    {
        // Version string.
        cell = [self tableView:tableView versionCellForRowAtIndexPath:indexPath];
    }
    
    else if(indexPath.section == kLAChromeCastTableSectionCastDevice)
    {
        if (_delegate.deviceManager.applicationConnectionState != GCKConnectionStateConnected)
        {
            cell = [self tableView:tableView deviceCellForRowAtIndexPath:indexPath];
        }
        
        else
        {
            if (indexPath.row == kLACastDeviceSectionVolume)
            {
                // Display the volume controller.
                cell = [self tableView:tableView volumeCellForRowAtIndexPath:indexPath];
            }
            
            else if (indexPath.row == kLACastDeviceSectionDisconnect)
            {
                // Display disconnect control as last cell.
                cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdForDisconnectButton];
                cell.textLabel.text = @"Disconnect";
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                UIButton *disconnectButton = [[UIButton alloc]initWithFrame:cell.frame];
                [cell addSubview:disconnectButton];
                [disconnectButton addTarget:self action:@selector(disconnectDevice) forControlEvents:UIControlEventTouchUpInside];
            }
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GCKDeviceManager *deviceManager = _delegate.deviceManager;
    GCKDeviceScanner *deviceScanner = _delegate.deviceScanner;
    if (deviceManager.applicationConnectionState != GCKConnectionStateConnected)
    {
        if (indexPath.row < deviceScanner.devices.count)
        {
            GCKDevice *device = [deviceScanner.devices objectAtIndex:indexPath.row];
            NSLog(@"Selecting device:%@", device.friendlyName);
            [_delegate connectToDevice:device];
        }
        
        [self dismiss];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Accesory button tapped");
}

- (void)disconnectDevice
{
    [_delegate disconnect];
    [self dismiss];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark ------------------------ volume ------------------------
- (void)volumeDidChange
{
    if (_volumeSlider) {
        _volumeSlider.value = _delegate.deviceManager.deviceVolume;
    }
}

- (void)sliderValueChanged:(id)sender
{
    UISlider *slider = (UISlider *) sender;
    NSLog(@"Got new slider value: %.2f", slider.value);
    [_delegate.deviceManager setVolume:slider.value];
}

@end
