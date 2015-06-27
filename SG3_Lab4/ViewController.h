//
//  ViewController.h
//  SG3_Lab4
//
//  Created by Jeff Lanning on 6/24/15.
//  Copyright (c) 2015 Jeff Lanning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RMCore/RMCore.h>
#import <RMCharacter/RMCharacter.h>
//
#include "RMCore/RMCore.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#import <AVFoundation/AVFoundation.h>
#import <opencv2/imgproc/imgproc_c.h>

@interface ViewController : UIViewController <RMCoreDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
{
    __weak IBOutlet UIImageView *_imageView;
    
    AVCaptureSession *_session;
    AVCaptureDevice *_captureDevice;
    
    BOOL _useBackCamera;
}

@property (nonatomic, strong) RMCoreRobotRomo3 *Romo3;
@property (nonatomic, strong) RMCharacter *Romo;

- (UIImage*)getUIImageFromIplImage:(IplImage *)iplImage;
- (void)didCaptureIplImage:(IplImage *)iplImage;
- (void)didFinishProcessingImage:(IplImage *)iplImage;

- (void)addGestureRecognizers;

@end

