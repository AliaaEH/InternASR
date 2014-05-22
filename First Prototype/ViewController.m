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
    
    // Set the audio recorder
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MyAudioMemo.wav", 
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Setup audio session
    session = [AVAudioSession sharedInstance];
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
    
    //setting up timer for silence detector
    leveltimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector: @selector(silenceDetector:) userInfo:nil repeats:YES];
    hold = NO;
    paused = NO;
    streamIsOpen = NO;
    textViewer.text = @" ";
}

// ------------------------------------- SETTING UP SOCKET STREAMING ---------------------------------------//

- (void)initNetworkCommunication
{
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

//handling stream events
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
	switch (streamEvent) {
            
		case NSStreamEventOpenCompleted:
			NSLog(@"Stream opened");
			break;
            
        case NSStreamEventHasSpaceAvailable:
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
                            [self displayText:output];
                        }
                    }
                }
            }
            break;
            
		case NSStreamEventErrorOccurred:
			NSLog(@"Can not connect to the host!");
			break;
            
		case NSStreamEventEndEncountered:
            //terminate previous connection before starting a new one
            NSLog(@"closing connection wrong");
			break;
            
		default:
			NSLog(@"Unknown event");
	}
    
}


- (void)silenceDetector:(NSTimer *)timer
{
    if(recorder.recording)
    {
        if (hold == NO)
        {
            //first time to check for silence should happen 3 seconds into the recording
            NSLog(@"waiting");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:3]];
            hold = YES;
        }
        
        [recorder updateMeters];
        peakInput.text = [NSString stringWithFormat:@"%f", [recorder peakPowerForChannel:0]];
        
        if ( (paused== YES || ([recorder peakPowerForChannel:0] > -65 && [recorder peakPowerForChannel:0] < -50) ))
        {
            [self restartRecording];
        }
    }
}


// --------------------------------------- SETTING UP RECORDER'S BEHAVIOR -----------------------------------------//

-(IBAction)startRecord: (id)sender
{
    if (inputStream)
    {
        //terminate previous connection before starting a new one
        NSLog(@"CLOSING");
        [outputStream close];
        [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                forMode:NSDefaultRunLoopMode];
        [inputStream close];
        [inputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
                               forMode:NSDefaultRunLoopMode];
        
        outputStream = nil;
        inputStream = nil;
    }
    
    [self initNetworkCommunication]; //establish connection
        
    if (!recorder.recording) {
        //initiate recording session
        NSLog(@"Recording");
        [session setActive:YES error:nil];
        
        // Start recording
        [recorder record];
        [_startRecordButton setTitle:@"Pause" forState:UIControlStateNormal];
        paused = NO;

    }
    else {
        paused = YES; 
    }
}

- (void)restartRecording
{
    //stop recorder
    NSLog(@"stopping");
    [recorder stop];
    [_startRecordButton setTitle:@"Record" forState:UIControlStateNormal];
    //[session setActive:NO error:nil];
    
    //extracting recording size
    NSLog(@"Sending To Server");
    //NSData *data_body = [[NSData alloc] initWithContentsOfURL: recorder.url];
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"Syria.wav",
                               nil];
    NSURL *file_url = [NSURL fileURLWithPathComponents:pathComponents];
    
    NSData *data_body = [[NSData alloc] initWithContentsOfURL: file_url];
    
    //convert int to NSData
    int i = [data_body length];
    if (i%2 != 0) //size must be even (server expectation
    {
        i--;
    }
    NSLog(@"%d", i);
    NSData *size = [NSData dataWithBytes: &i length: sizeof(i)];
    
    //creating and sending packet
    NSMutableData *packet = [[NSMutableData alloc] init];
    [packet appendData:size];
    [packet appendData:data_body];
    [outputStream write:[packet bytes] maxLength:[packet length]];
    
    //restart the silence detector's 3 seconds hold
    hold = NO;
}

// --------------------------------------- RECEIVING AND HANDLING TEXT -----------------------------------------//
-(void)displayText:(NSString *)reply
{
    //parsing input
    NSArray *lines = [[NSArray alloc] initWithArray:[reply componentsSeparatedByString:@"\n"]];
    NSArray *parser = [[NSArray alloc] init];
    NSString *input = @"";
    
    for (int i = 0; i<([parser count] - 1); i++)
    {
        parser = [[NSArray alloc] initWithArray:[lines[i] componentsSeparatedByString:@" "]];
        input = [NSString stringWithFormat:@"%@ %@", input, parser[1]];
    }

    //displaying new text
    textViewer.text = [NSString stringWithFormat:@"%@ %@", textViewer.text, input];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

@end
