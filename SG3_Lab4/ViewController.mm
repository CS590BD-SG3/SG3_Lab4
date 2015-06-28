//
//  ViewController.m
//  SG3_Lab4
//
//  Created by Jeff Lanning/Brandon Andrews Sub group 3 on 6/24/15.
//  Copyright (c) 2015 Jeff Lanning. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import <RMCore/RMCore.h>
#import "AFHTTPRequestOperationManager.h"
#import "STTwitterAPI.h"

#import <opencv2/objdetect/objdetect.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#import "opencv2/opencv.hpp"

#define BASE_URL "http://nlpservices.mybluemix.net/api/service"

using namespace std;
using namespace cv;

NSString *currentRotX;
NSString *currentRotY;
NSString *currentRotZ;

double currentMaxRotX;
double currentMaxRotY;
double currentMaxRotZ;

BOOL sawRedColor;

//NO shows RGB image and highlights found circles
//YES shows threshold image
static BOOL _debug = NO;

@interface ViewController ()

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) NSString *currentRotX;
@property (strong, nonatomic) NSString *currentRotY;
@property (strong, nonatomic) NSString *currentRotZ;
@property (strong, nonatomic) NSString *maxRotX;
@property (strong, nonatomic) NSString *maxRotY;
@property (strong, nonatomic) NSString *maxRotZ;

@property (strong, nonatomic) NSString *currentMaxRotX;
@property (strong, nonatomic) NSString *currentMaxRotY;
@property (strong, nonatomic) NSString *currentMaxRotZ;

@property (nonatomic, assign) BOOL isBeginning;
@property (nonatomic, assign) BOOL isClimbing;
@property (nonatomic, assign) BOOL isOnTop;
@property (nonatomic, assign) BOOL isDescending;
@property (nonatomic, assign) BOOL isEnding;

@property (nonatomic, assign) BOOL sawRedColor;

@property (nonatomic, strong) NSArray *tokens;

@end

@implementation ViewController

#pragma mark - View Management
- (void)viewDidLoad {
    [self logInfo:@"Entering viewDidLoad"];
    [super viewDidLoad];
    
    [self setupCamera];
    [self turnCameraOn];
    
    //swipe right to switch cameras
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(flipAction)];
    swipeGesture.numberOfTouchesRequired = 2;
    swipeGesture.cancelsTouchesInView = NO;
    swipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeGesture];
    
    //[self flipAction];
    
    [self tappedOnRed:self];
    
    // To receive messages when Robots connect & disconnect, set RMCore's delegate to self
    [RMCore setDelegate:self];
    
    // Grab a shared instance of the Romo character
    //self.Romo = [RMCharacter Romo];

    //[RMCore setDelegate:self];
    
    [self addGestureRecognizers];
    
    NSString *ipAddress = [self getIPAddress];
    [self logInfo:@"The iOS Device IP Address is..."];
    [self logInfo:ipAddress];
    
    //self.Romo.emotion = RMCharacterEmotionCurious;
    //self.Romo.expression = RMCharacterExpressionSneeze;
    
    /** COMMENT OUT LOGGING PURPOSE ONLY **/
    /*
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
     
     self.motionManager = [appDelegate sharedMotionManager];
     self.motionManager.gyroUpdateInterval = 0.3;
     self.motionManager.magnetometerUpdateInterval = 0.3;
     self.motionManager.accelerometerUpdateInterval = 0.3;
     self.motionManager.deviceMotionUpdateInterval = 0.3;
     
     self.isBeginning = true;
     self.isClimbing = false;
     self.isOnTop = false;
     self.isDescending = false;
     self.isEnding = false;
     
     [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMGyroData *gyroData, NSError *error) {
     [self outputRotationData:gyroData.rotationRate];
     }];
     
     [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
     [self processMotion:motion];
     }];
    */
}

- (void)doNothing
{
    
}


- (void)processMotion:(CMDeviceMotion*)motion
{
    float pitch =  (180/M_PI)*motion.attitude.pitch;
    float roll = (180/M_PI)*motion.attitude.roll;
    float yaw = (180/M_PI)*motion.attitude.yaw;
    
    NSLog(@"Roll: %@, Pitch: %@, Yaw: %@", [NSString stringWithFormat:@"%f", roll],[NSString stringWithFormat:@"%f",pitch], [NSString stringWithFormat:@"%f",yaw]);
    
    // Romo is flat
    if (pitch >= 70.0 && pitch < 90.0)
    {
        // 1. Romo is starting out...
        if (self.isBeginning == true)
        {
            NSLog(@"Is Beginning...");
            [self.Romo3 driveForwardWithSpeed:0.40];
            //self.Romo.emotion = RMCharacterEmotionExcited;
            //self.Romo.expression = RMCharacterExpressionExcited;
        }
        // 3. Romo is on top...
        else if (self.isBeginning == false && self.isClimbing == true)
        {
            NSLog(@"Is On Top...");
            self.isClimbing = false;
            self.isOnTop = true;
            
            [self.Romo3 driveForwardWithSpeed:0.25];
            //[NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(doNothing) userInfo:nil repeats:NO];
            //[self performSelector:@selector(doNothing) withObject:nil afterDelay:0.5 ];
            
            //[self.motionManager stopDeviceMotionUpdates];
            
            [self.Romo3 stopDriving];
            //self.Romo.emotion = RMCharacterEmotionSleepy;
            //self.Romo.expression = RMCharacterExpressionYippee;
            
            // Call NLP Service and Tweet message!
            [self callNLPService];
            [self.Romo3 driveForwardWithSpeed:0.25];
            
            //[NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(doNothing) userInfo:nil repeats:NO];
            //[self performSelector:@selector(doNothing) withObject:nil afterDelay:5.0 ];
            
            
            /*[self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
             [self processMotion:motion];
             }];*/
        }
        // 5. Romo is at the finish line...
        else if (self.isDescending == true)
        {
            NSLog(@"Is at the Finish Line...");
            self.isDescending = false;
            self.isEnding = true;
            
            [self.Romo3 driveForwardWithSpeed:0.30];
            
            //self.Romo.emotion = RMCharacterEmotionExcited;
            //self.Romo.expression = RMCharacterExpressionWee;
            //[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(doNothing) userInfo:nil repeats:NO];
            //[self performSelector:@selector(doNothing) withObject:nil afterDelay:1.0 ];
            
            //[self.Romo3 stopAllMotion];
        }
        else
        {
            NSLog(@"Saw Red Color... @%d", sawRedColor);
            if (sawRedColor == TRUE)
            {
                [self.Romo3 stopDriving];
            }
        }
    }
    // 2. Romo is climbing...
    else if (pitch < 70.0)
    {
        if (self.isBeginning == true)
        {
            NSLog(@"Is Climbing...");
            self.isBeginning = false;
            self.isClimbing = true;
            
            [self.Romo3 driveForwardWithSpeed:0.75];
            //self.Romo.expression = RMCharacterExpressionStruggling;
        }
        
        // 4. Romo is descending...
        else if (self.isOnTop == true)
        {
            NSLog(@"Is Descending...");
            self.isOnTop = false;
            self.isDescending = true;
            
            [self.Romo3 driveForwardWithSpeed:0.15];
            //self.Romo.emotion = RMCharacterEmotionScared;
            //self.Romo.expression = RMCharacterExpressionScared;
        }
    }
    
    NSLog(@"Beginning: %@, Climbing: %@, OnTop: %@, Descending: %@, Finished: %@", [NSString stringWithFormat:@"%s", self.isBeginning ? "true" : "false"],[NSString stringWithFormat:@"%s", self.isClimbing ? "true" : "false"],[NSString stringWithFormat:@"%s", self.isOnTop ? "true" : "false"],[NSString stringWithFormat:@"%s", self.isDescending ? "true" : "false"],[NSString stringWithFormat:@"%s", self.isEnding ? "true" : "false"]);
}

- (void)outputRotationData:(CMRotationRate)rotation
{
    self.currentRotX = [NSString stringWithFormat:@" %.2fr/s",rotation.x];
    if(fabs(rotation.x) > fabs(currentMaxRotX))
    {
        currentMaxRotX = rotation.x;
    }
    self.currentRotY = [NSString stringWithFormat:@" %.2fr/s",rotation.y];
    if(fabs(rotation.y) > fabs(currentMaxRotY))
    {
        currentMaxRotY = rotation.y;
    }
    self.currentRotZ = [NSString stringWithFormat:@" %.2fr/s",rotation.z];
    if(fabs(rotation.z) > fabs(currentMaxRotZ))
    {
        currentMaxRotZ = rotation.z;
    }
    
    self.maxRotX = [NSString stringWithFormat:@" %.2f",currentMaxRotX];
    self.maxRotY = [NSString stringWithFormat:@" %.2f",currentMaxRotY];
    self.maxRotZ = [NSString stringWithFormat:@" %.2f",currentMaxRotZ];
    
    /*
     [self logInfo:[NSString stringWithFormat:@"%@%@", @"Current X Rot: ",self.currentRotX]];
     [self logInfo:[NSString stringWithFormat:@"%@%@", @"Current Y Rot: ",self.currentRotY]];
     [self logInfo:[NSString stringWithFormat:@"%@%@", @"Current Z Rot: ",self.currentRotZ]];
     
     [self logInfo:[NSString stringWithFormat:@"%@%@", @"Max X Rot: ",self.maxRotX]];
     [self logInfo:[NSString stringWithFormat:@"%@%@", @"Max Y Rot: ",self.maxRotY]];
     [self logInfo:[NSString stringWithFormat:@"%@%@", @"Max Z Rot: ",self.maxRotZ]];
     */
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
/*
 * This is our new function that calls into the Twitter API to tweet the NLP Commands.
 */
- (void) tweetCommands {
    NSMutableString * result = [[NSMutableString alloc] init];
    for (NSObject * obj in _tokens)
    {
        [result appendString:[obj description]];
        [result appendString:@" "];
    }
    NSLog(@"The concatenated string is %@", result);
    
    NSString *apiKey = @"K5irO3T6OnBimYiLwKI1aDPv0";
    NSString *apiSecret = @"sswoK3Dgjpr17AAUaWlQyfLdFpA0ENEs11wDoCQ2ahghcAaZvu";
    NSString *oauthToken = @"3248175864-yiPSna2GQo0b3WHUSHPWeFl0kHjmb4zBPy648A4";
    NSString *oathSecret = @"ZAVqYA8UTavzk0gg9I1ksthmq404LZtsoXvpbFuLBHJwr";
    
    STTwitterAPI *twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:apiKey consumerSecret:apiSecret oauthToken:oauthToken oauthTokenSecret:oathSecret];
    
    [twitter verifyCredentialsWithSuccessBlock:^(NSString *bearerToken) {
        
        NSLog(@"Access granted with %@", bearerToken);
        
        [twitter postStatusUpdate:result
                inReplyToStatusID:nil
                         latitude:nil
                        longitude:nil
                          placeID:nil
               displayCoordinates:nil
                         trimUser:nil
                     successBlock:^(NSDictionary *status) {
                         NSLog(@"Success: %@", status);
                     } errorBlock:^(NSError *error) {
                         NSLog(@"Error: %@", error);
                     }];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"-- error %@", error);
    }];
}

#pragma GCC diagnostic pop

- (void)callNLPService {
    
    //Formats date and converts to a string
    NSDateFormatter *formatter;
    NSString        *dateString;
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"hh:mm a"]; //hour,minute, am/pm format
    
    dateString = [formatter stringFromDate:[NSDate date]];
    
    //Concatenates outputMSG string and the current time
    NSString *outputMSG = @"I made it to the top at ";
    NSString *outputDate = [outputMSG stringByAppendingString:dateString];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *sentence = [outputDate stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSString *url = [NSString stringWithFormat:@"%s/chunks/%@", BASE_URL, sentence];
    
    NSLog(@"%@", url);
    
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        
        _tokens = [responseObject objectForKey:@"tokens"];
        
        [self tweetCommands];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    // Add Romo's face to self.view whenever the view will appear
    //[self.Romo addToSuperview:self.view];
}

#pragma mark - RMCoreDelegate Methods
- (void)robotDidConnect:(RMCoreRobot *)robot
{
    // Currently the only kind of robot is Romo3, so this is just future-proofing
    if ([robot isKindOfClass:[RMCoreRobotRomo3 class]]) {
        self.Romo3 = (RMCoreRobotRomo3 *)robot;
        
        // Change Romo's LED to be solid at 80% power
        [self.Romo3.LEDs setSolidWithBrightness:0.8];
        
        // When we plug Romo in, he get's excited!
        //self.Romo.expression = RMCharacterExpressionExcited;
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //self.Romo.emotion = RMCharacterExpressionCurious;
    //self.Romo.expression = RMCharacterExpressionTalking;
    
    /*
     [self.Romo3 tiltToAngle:90
     completion:^(BOOL success) {
     if (success) {
     NSLog(@"Successfully tilted");
     } else {
     NSLog(@"Couldn't tilt to the desired angle");
     }
     }];
    */
    
    self.motionManager = [appDelegate sharedMotionManager];
    self.motionManager.gyroUpdateInterval = 0.2;
    self.motionManager.magnetometerUpdateInterval = 0.2;
    self.motionManager.accelerometerUpdateInterval = 0.2;
    self.motionManager.deviceMotionUpdateInterval = 0.2;
    
    self.isBeginning = true;
    self.isClimbing = false;
    self.isOnTop = false;
    self.isDescending = false;
    self.isEnding = false;
    
    [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMGyroData *gyroData, NSError *error) {
        [self outputRotationData:gyroData.rotationRate];
    }];
    
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
        [self processMotion:motion];
    }];
    
    //self.view = [ColorCircleViewController new];
    
}

- (void)robotDidDisconnect:(RMCoreRobot *)robot
{
    if (robot == self.Romo3) {
        self.Romo3 = nil;
        
        // When we plug Romo in, he get's excited!
        self.Romo.expression = RMCharacterExpressionSad;
    }
}

#pragma mark - Gesture recognizers

- (void)addGestureRecognizers
{
    // Let's start by adding some gesture recognizers with which to interact with Romo
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedLeft:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeft];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedRight:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];
    
    /*
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedUp:)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipeUp];
    */
     
    UITapGestureRecognizer *tapReceived = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedScreen:)];
    [self.view addGestureRecognizer:tapReceived];
}


- (void)swipedLeft:(UIGestureRecognizer *)sender
{
    // When the user swipes left, Romo will turn in a circle to his left
    [self.Romo3 driveWithRadius:-1.0 speed:1.0];
}

- (void)swipedRight:(UIGestureRecognizer *)sender
{
    // When the user swipes right, Romo will turn in a circle to his right
    [self.Romo3 driveWithRadius:1.0 speed:1.0];
}

// Swipe up to change Romo's emotion to some random emotion
/*- (void)swipedUp:(UIGestureRecognizer *)sender
{
    int numberOfEmotions = 7;
    
    // Choose a random emotion from 1 to numberOfEmotions
    // That's different from the current emotion
    RMCharacterEmotion randomEmotion = 1 + (arc4random() % numberOfEmotions);
    
    self.Romo.emotion = randomEmotion;
}
*/

// Simply tap the screen to stop Romo
- (void)tappedScreen:(UIGestureRecognizer *)sender
{
    [self.Romo3 stopDriving];
}

#pragma mark - Networking/Sockets

- (NSString *)getIPAddress {
    
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                }
                
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

#pragma mark - Logging Utilities

- (void)logError:(NSString *)msg
{
    NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setObject:[UIColor redColor] forKey:NSForegroundColorAttributeName];
    
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
    NSString *str = [as string];
    NSLog(@"%@", str);
}

- (void)logInfo:(NSString *)msg
{
    NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setObject:[UIColor purpleColor] forKey:NSForegroundColorAttributeName];
    
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
    
    NSString *str = [as string];
    NSLog(@"%@", str);
}

- (void)logMessage:(NSString *)msg
{
    NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setObject:[UIColor blackColor] forKey:NSForegroundColorAttributeName];
    
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
    
    NSString *str = [as string];
    NSLog(@"%@", str);
}


- (void)viewDidUnload
{
    _imageView = nil;
    [super viewDidUnload];
}

- (IBAction)tappedOnRed:(id)sender {
    _min = 160;
    _max = 179;
    
    NSLog(@"%.2f - %.2f", _min, _max);
}

- (IBAction)tappedOnBlue:(id)sender {
    _min = 75;
    _max = 130;
    
    NSLog(@"%.2f - %.2f", _min, _max);
}

- (IBAction)tappedOnGreen:(id)sender {
    _min = 38;
    _max = 75;
    
    NSLog(@"%.2f - %.2f", _min, _max);
}


#pragma mark - Capture


- (void)flipAction
{
    _useBackCamera = !_useBackCamera;
    
    [self turnCameraOff];
    [self setupCamera];
    [self turnCameraOn];
}


- (void)setupCamera
{
    _captureDevice = nil;
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices)
    {
        if (device.position == AVCaptureDevicePositionFront && !_useBackCamera)
        {
            _captureDevice = device;
            break;
        }
        if (device.position == AVCaptureDevicePositionBack && _useBackCamera)
        {
            _captureDevice = device;
            break;
        }
    }
    
    if (!_captureDevice)
        _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}


- (void)turnCameraOn
{
    NSError *error;
    
    _session = [[AVCaptureSession alloc] init];
    [_session beginConfiguration];
    [_session setSessionPreset:AVCaptureSessionPresetMedium];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
    
    if (input == nil)
        NSLog(@"%@", error);
    
    [_session addInput:input];
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setSampleBufferDelegate:self queue:dispatch_queue_create("myQueue", NULL)];
    output.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    output.alwaysDiscardsLateVideoFrames = YES;
    
    [_session addOutput:output];
    
    [_session commitConfiguration];
    [_session startRunning];
}


- (void)turnCameraOff
{
    [_session stopRunning];
    _session = nil;
}


- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    IplImage *iplimage = nullptr;
    if (baseAddress)
    {
        iplimage = cvCreateImageHeader(cvSize(width, height), IPL_DEPTH_8U, 4);
        iplimage->imageData = (char*)baseAddress;
    }
    
    IplImage *workingCopy = cvCreateImage(cvSize(height, width), IPL_DEPTH_8U, 4);
    
    if (_captureDevice.position == AVCaptureDevicePositionFront)
    {
        cvTranspose(iplimage, workingCopy);
    }
    else
    {
        cvTranspose(iplimage, workingCopy);
        cvFlip(workingCopy, nil, 1);
    }
    
    cvReleaseImageHeader(&iplimage);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    [self didCaptureIplImage:workingCopy];
}


#pragma mark - Image processing


static void ReleaseDataCallback(void *info, const void *data, size_t size)
{
#pragma unused(data)
#pragma unused(size)
    IplImage *iplImage = (IplImage*)info;
    cvReleaseImage(&iplImage);
}


- (CGImageRef)getCGImageFromIplImage:(IplImage*)iplImage
{
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = iplImage->widthStep;
    
    size_t bitsPerPixel;
    CGColorSpaceRef space;
    
    if (iplImage->nChannels == 1)
    {
        bitsPerPixel = 8;
        space = CGColorSpaceCreateDeviceGray();
    }
    else if (iplImage->nChannels == 3)
    {
        bitsPerPixel = 24;
        space = CGColorSpaceCreateDeviceRGB();
    }
    else if (iplImage->nChannels == 4)
    {
        bitsPerPixel = 32;
        space = CGColorSpaceCreateDeviceRGB();
    }
    else
    {
        abort();
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNone;
    CGDataProviderRef provider = CGDataProviderCreateWithData(iplImage,
                                                              iplImage->imageData,
                                                              0,
                                                              ReleaseDataCallback);
    const CGFloat *decode = NULL;
    bool shouldInterpolate = true;
    CGColorRenderingIntent intent = kCGRenderingIntentDefault;
    
    CGImageRef cgImageRef = CGImageCreate(iplImage->width,
                                          iplImage->height,
                                          bitsPerComponent,
                                          bitsPerPixel,
                                          bytesPerRow,
                                          space,
                                          bitmapInfo,
                                          provider,
                                          decode,
                                          shouldInterpolate,
                                          intent);
    CGColorSpaceRelease(space);
    CGDataProviderRelease(provider);
    return cgImageRef;
}


- (UIImage*)getUIImageFromIplImage:(IplImage*)iplImage
{
    CGImageRef cgImage = [self getCGImageFromIplImage:iplImage];
    UIImage *uiImage = [[UIImage alloc] initWithCGImage:cgImage
                                                  scale:1.0
                                            orientation:UIImageOrientationUp];
    
    CGImageRelease(cgImage);
    return uiImage;
}


#pragma mark - Captured Ipl Image

/* DEFAULT CAPTURE IMAGE FROM SUPER CLASS
- (void)didCaptureIplImage:(IplImage *)iplImage
{
    IplImage *rgbImage = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplImage, rgbImage, CV_BGR2RGB);
    cvReleaseImage(&iplImage);
    
    [self didFinishProcessingImage:rgbImage];
}
*/

- (void)didCaptureIplImage:(IplImage *)iplImage
{
    //ipl image is in BGR format, it needs to be converted to RGB for display in UIImageView
    IplImage *imgRGB = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplImage, imgRGB, CV_BGR2RGB);
    Mat matRGB = Mat(imgRGB);
    
    //ipl imaeg is also converted to HSV; hue is used to find certain color
    IplImage *imgHSV = cvCreateImage(cvGetSize(iplImage), 8, 3);
    cvCvtColor(iplImage, imgHSV, CV_BGR2HSV);
    
    IplImage *imgThreshed = cvCreateImage(cvGetSize(iplImage), 8, 1);
    
    //it is important to release all images EXCEPT the one that is going to be passed to
    //the didFinishProcessingImage: method and displayed in the UIImageView
    cvReleaseImage(&iplImage);
    
    //filter all pixels in defined range, everything in range will be white, everything else
    //is going to be black
    cvInRangeS(imgHSV, cvScalar(_min, 100, 100), cvScalar(_max, 255, 255), imgThreshed);
    
    cvReleaseImage(&imgHSV);
    
    Mat matThreshed = Mat(imgThreshed);
    
    //smooths edges
    cv::GaussianBlur(matThreshed,
                     matThreshed,
                     cv::Size(9, 9),
                     2,
                     2);
    
    //debug shows threshold image, otherwise the circles are detected in the
    //threshold image and shown in the RGB image
    if (_debug)
    {
        cvReleaseImage(&imgRGB);
        [self didFinishProcessingImage:imgThreshed];
    }
    else
    {
        vector<Vec3f> circles;
        //get circles
        HoughCircles(matThreshed,
                     circles,
                     CV_HOUGH_GRADIENT,
                     2,
                     matThreshed.rows / 4,
                     150,
                     75,
                     10,
                     150);
        
        for (size_t i = 0; i < circles.size(); i++)
        {
            cout << "Circle position x = " << (int)circles[i][0] << ", y = " << (int)circles[i][1] << ", radius = " << (int)circles[i][2] << "\n";
            
            cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
            
            int radius = cvRound(circles[i][2]);
            
            circle(matRGB, center, 3, Scalar(0, 255, 0), -1, 8, 0);
            circle(matRGB, center, radius, Scalar(0, 0, 255), 3, 8, 0);
        }
        
        if (circles.size() >= 1)
        {
            sawRedColor = TRUE;
        }
        
        //threshed image is not needed any more and needs to be released
        cvReleaseImage(&imgThreshed);
        
        //imgRGB will be released once it is not needed, the didFinishProcessingImage:
        //method will take care of that
        [self didFinishProcessingImage:imgRGB];
    }
}

#pragma mark - didFinishProcessingImage


- (void)didFinishProcessingImage:(IplImage *)iplImage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *uiImage = [self getUIImageFromIplImage:iplImage];
        _imageView.image = uiImage;
    });
}


#pragma mark -

@end
