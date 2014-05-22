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
    IBOutlet UITextView *textViewer;
    BOOL streamIsOpen;
    
    /* SECTION B */
    AVAudioSession *session; 
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
    NSTimer *leveltimer;
    BOOL hold;
    BOOL paused; 
    IBOutlet UILabel *peakInput;
    
}

@property(weak, nonatomic) IBOutlet UIButton *startRecordButton;

-(IBAction)startRecord: (id)sender;


@end
