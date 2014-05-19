//
//  ViewController.h
//  First Prototype
//
//  Created by Aliaa Essameldin on 5/18/14.
//  Copyright (c) 2014 Aliaa Essameldin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#define IP_ADDRESS @"localhost";
#define PORT_NUMBER 80

@interface ViewController : UIViewController <NSStreamDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate>

{
    /* SECTION A */
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    
    /* SECTION B */
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
}

@property(weak, nonatomic) IBOutlet UIButton *connectButton;
@property(weak, nonatomic) IBOutlet UIButton *startRecordButton;
@property(weak, nonatomic) IBOutlet UIButton *stopRecordButton;
@property(weak, nonatomic) IBOutlet UIButton *playRecordButton;
@property(weak, nonatomic) IBOutlet UIButton *sendButton;


-(IBAction)connect: (id)sender;
-(IBAction)startRecord: (id)sender;
-(IBAction)stopRecord: (id)sender;
-(IBAction)playRecord: (id)sender;
-(IBAction)send: (id)sender;

@end
