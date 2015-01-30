

#import <Cordova/CDV.h>



#import <OpenEars/OEEventsObserver.h> // We need to import this here in order to use the delegate.
#import <OpenEars/OEPocketsphinxController.h>
#import <OpenEars/OEFliteController.h>
#import <OpenEars/OELanguageModelGenerator.h>
#import <OpenEars/OELogging.h>
#import <OpenEars/OEAcousticModel.h>
#import <Slt/Slt.h>

#import <AVFoundation/AVFoundation.h>


#import "BackgroundTask.h"

@interface CDVVoiceRecognise : CDVPlugin<OEEventsObserverDelegate> {
	
    
	NSNumber *started_listening; // 1, 0 (yes, no)
    NSString *acoustic_model;
	NSString *current_language_model;
	NSString *current_dictionary;
	NSString *path_to_dynamic_language_model;
	NSString *path_to_dynamic_grammar;
    NSString *strMatchWord;
    NSArray *finallanguageSecondaryArray;
    BackgroundTask * bgTask;
    
      AVAudioPlayer * avPlayer;

    BOOL _enabled;
    BOOL inBG;
    NSTimer* bgtimer;
    
    __block AVAudioPlayer *player;
  
    AVAudioRecorder *soundRecorder;
    NSInteger timerInterval;
    NSURL *soundFileURL;
}


// These three are the important OpenEars objects that this class demonstrates the use of.
@property (nonatomic, strong) Slt *slt;

@property (nonatomic, strong) OEEventsObserver *openEarsEventsObserver;
@property (nonatomic, strong) OEPocketsphinxController *pocketsphinxController;
@property (nonatomic, strong) OEFliteController *fliteController;


@property (nonatomic, assign) BOOL usingStartingLanguageModel;
@property (nonatomic, assign) int restartAttemptsDueToPermissionRequests;
@property (nonatomic, assign) BOOL startupFailedDueToLackOfPermissions;

// Things which help us show off the dynamic language features.
@property (nonatomic, copy) NSString *pathToFirstDynamicallyGeneratedLanguageModel;
@property (nonatomic, copy) NSString *pathToFirstDynamicallyGeneratedDictionary;
@property (nonatomic, copy) NSString *pathToSecondDynamicallyGeneratedLanguageModel;
@property (nonatomic, copy) NSString *pathToSecondDynamicallyGeneratedDictionary;

// Our NSTimer that will help us read and display the input and output levels without locking the UI
@property (nonatomic, strong) 	NSTimer *uiUpdateTimer;



// Example for reading out the input audio levels without locking the UI using an NSTimer

- (void) startDisplayingLevels;
- (void) stopDisplayingLevels;


/***old ***/





@property (nonatomic, strong) NSNumber *started_listening;
@property (nonatomic, strong) NSString *acoustic_model;
@property (nonatomic, strong) NSString *current_language_model;
@property (nonatomic, strong) NSString *current_dictionary;
@property (nonatomic, strong) NSString *path_to_dynamic_language_model;
@property (nonatomic, strong) NSString *path_to_dynamic_grammar;


- (void)startAudioSession:(CDVInvokedUrlCommand*)command;

// Language Model Generator
- (void)generateLanguageModel:(CDVInvokedUrlCommand*)command;


// Set MAtch Word
- (void)setMatchWord:(CDVInvokedUrlCommand*)command;

// PocketSphinx Controller
- (void)stopListening:(CDVInvokedUrlCommand*)command;
- (void)resumeListening:(CDVInvokedUrlCommand*)command;
- (void)suspendRecognition:(CDVInvokedUrlCommand*)command;
- (void)resumeRecognition:(CDVInvokedUrlCommand*)command;
- (void)startListeningWithLanguageModelAtPath:(CDVInvokedUrlCommand*)command;
- (void)changeLanguageModelToFile:(CDVInvokedUrlCommand*)command;

// Flite
- (void)say:(CDVInvokedUrlCommand*)command;


// Aktiviert den Hintergrundmodus
- (void) enable:(CDVInvokedUrlCommand *)command;
// Deaktiviert den Hintergrundmodus
- (void) disable:(CDVInvokedUrlCommand *)command;
-(void) callinbackground;

-(void)PlayBackgroundFile:(CDVInvokedUrlCommand*)command;
-(void)startRecord:(CDVInvokedUrlCommand*)command;
-(void)stopRecord:(CDVInvokedUrlCommand*)command;
-(void)playRecord:(CDVInvokedUrlCommand*)command;
@end
