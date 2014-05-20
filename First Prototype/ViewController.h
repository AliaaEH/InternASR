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
#define PORT_NUMBER 12345

@interface ViewController : UIViewController <NSStreamDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate>

{
    /* SECTION A */
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    IBOutlet UILabel *inputText;
    BOOL streamIsOpen;
    
    /* SECTION B */
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
    
}

@property(weak, nonatomic) IBOutlet UIButton *startRecordButton;
@property(weak, nonatomic) IBOutlet UIButton *playRecordButton;

-(IBAction)startRecord: (id)sender;
-(IBAction)playRecord: (id)sender;


@end
