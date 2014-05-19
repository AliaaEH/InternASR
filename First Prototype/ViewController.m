//
//  ViewController.m
//  First Prototype
//
//  Created by Aliaa Essameldin on 5/18/14.
//  Copyright (c) 2014 Aliaa Essameldin. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController 

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /* Setting up for SECTION B */
    // Disable Stop/Play button when application launches
    [_stopRecordButton setEnabled:NO];
    [_playRecordButton setEnabled:NO];
    [_sendButton setEnabled:NO];
    
    // Set the audio file
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MyAudioMemo.m4a", //we want to later change that to wav
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:NULL];
    recorder.delegate = self;
    recorder.meteringEnabled = YES;
    [recorder prepareToRecord];
}

/* SECTION A: Connecting to the server */
- (IBAction)connect:(id)sender{
    [self initNetworkCommunication];
}

//This function initiates streaming
- (void)initNetworkCommunication {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"localhost", PORT_NUMBER, &readStream, &writeStream);
    //FIX THE INSANE MACRO HERE
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
}

//Defining the behavior of the stream
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
	switch (streamEvent) {
            
		case NSStreamEventOpenCompleted:
			NSLog(@"Stream opened");
			break;
            
		case NSStreamEventHasBytesAvailable:
			if (theStream == inputStream) {
                
                uint8_t buffer[1024];
                int len;
                
                while ([inputStream hasBytesAvailable]) {
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output) {
                            NSLog(@"server said: %@", output);
                        }
                    }
                }
            }
            break;
            
		case NSStreamEventErrorOccurred:
			NSLog(@"Can not connect to the host!");
			break;
            
		case NSStreamEventEndEncountered:
			break;
            
		default:
			NSLog(@"Unknown event");
	}
    
}

/* SECTION B : sound recording */
-(IBAction)startRecord: (id)sender
{
    [_sendButton setEnabled:YES];
    
    // Stop the audio player before recording
    if (player.playing) {
        [player stop];
    }
        
    if (!recorder.recording) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
            
        // Start recording
        [recorder record];
        [_startRecordButton setTitle:@"Pause" forState:UIControlStateNormal];
            
    } else {
        // Pause recording
        
        [recorder pause];
        [_startRecordButton setTitle:@"Record" forState:UIControlStateNormal];
    }
    
    [_stopRecordButton setEnabled:YES];
    [_playRecordButton setEnabled:NO];
    
    
}

-(IBAction)stopRecord: (id)sender
{
    [recorder stop];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
}

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag{
    [_startRecordButton setTitle:@"Record" forState:UIControlStateNormal];
    
    [_stopRecordButton setEnabled:NO];
    [_playRecordButton setEnabled:YES];
}

-(IBAction)playRecord: (id)sender
{
    if (!recorder.recording){
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:recorder.url error:nil];
        [player setDelegate:self];
        [player play];
    } else {
        NSLog(@"Error: Sound file not found"); 
    }

}

/* SECTION C : sending sound to server */
-(IBAction)send: (id)sender
{
	NSData *data = [[NSData alloc] initWithContentsOfURL: recorder.url];
    [outputStream write:[data bytes] maxLength:[data length]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

@end
