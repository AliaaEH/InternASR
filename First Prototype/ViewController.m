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
                               @"MyAudioMemo.wav", //we want to later change that to wav
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                          [NSNumber numberWithFloat:16000.0], AVSampleRateKey,
                                          [NSNumber numberWithInt: kAudioFormatLinearPCM], AVFormatIDKey,
                                          [NSNumber numberWithInt:16], AVEncoderBitDepthHintKey,
                                          [NSNumber numberWithInt:16], AVEncoderBitRateKey,
                                          [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
                                          [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                          [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                                          [NSNumber numberWithInt: AVAudioQualityHigh], AVEncoderAudioQualityKey,
                                          nil];
 
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
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"localhost", 12345, &readStream, &writeStream);
    //FIX THE INSANE MACRO HERE
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
    
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [inputStream open];
    [outputStream open];
}

//Defining the behavior of the stream
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
	switch (streamEvent) {
            
		case NSStreamEventOpenCompleted:
			NSLog(@"Stream opened");
			break;
            
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"Sending Audio");
            break;
            
		case NSStreamEventHasBytesAvailable:
			if (theStream == inputStream) {
                
                uint8_t buffer[1024];
                int len;
                
                while ([inputStream hasBytesAvailable]) {
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSUTF8StringEncoding];
                        
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
        [_playRecordButton setEnabled:YES];
        
        AudioQueueLevelMeterState meters[1];
        UInt32 dlen = sizeof(meters);
        OSStatus Status AudioQueueGetProperty(inAQ,kAudioQueueProperty_CurrentLevelMeterDB,meters,&dlen);
        if(meters[0].mPeakPower < _threshold)
        { // NSLog(@"Silence detected");
        }
        
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
    
    NSData *data_body = [[NSData alloc] initWithContentsOfURL: recorder.url];
    //convert int to NSData
    int i = [data_body length];
    if (i%2 != 0)
    {
        i--;
    }
    NSLog(@"%d", i);
    
    //if you get the audio data as a buffer of bytes and the size as int ... the two code snippets above should do the necessary work for you ;)
    
    NSData *size = [NSData dataWithBytes: &i length: sizeof(i)];
    
    NSMutableData *packet = [[NSMutableData alloc] init];
    [packet appendData:size];
    [packet appendData:data_body];
    
    
    [outputStream write:[packet bytes] maxLength:[packet length]];
    //[outputStream write:[data_body bytes] maxLength:[data_body length]];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

@end
