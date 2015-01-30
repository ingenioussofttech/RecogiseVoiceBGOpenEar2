#import "CDVVoiceRecognise.h"

@interface CDVVoiceRecognise (PrivateMethods)

// Registriert die Listener für die (sleep/resume) Events
- (void) observeLifeCycle:(CDVInvokedUrlCommand *)command;
// Aktiviert den Hintergrundmodus
- (void) enableMode;
// Deaktiviert den Hintergrundmodus
- (void) disableMode;

@end
@implementation CDVVoiceRecognise




@synthesize slt;
@synthesize openEarsEventsObserver;
@synthesize pocketsphinxController;
@synthesize fliteController;
@synthesize current_dictionary;
@synthesize path_to_dynamic_language_model;
@synthesize path_to_dynamic_grammar;



@synthesize started_listening;
@synthesize acoustic_model;
@synthesize current_language_model;



- (Slt *)slt {
	if (slt == nil) {
		slt = [[Slt alloc] init];
	}
	return slt;
}



/*
 *  AudioSessionManager methods
	Start
		args: "AcousticModelEnglish" or "AcousticModelSpanish"
		returns status OK
 */
-(void)startAudioSession:(CDVInvokedUrlCommand*)command{
    // Default to "AcousticModelEnglish", will also accept "AcousticModelSpanish" or any others that may be added.
    NSString *acoustic_model_name;
    if(command.arguments && command.arguments.count){
        acoustic_model_name = [command.arguments objectAtIndex:0];
    }
    if(acoustic_model_name == nil){
        acoustic_model_name = @"AcousticModelEnglish";
    }
	
    /*if(![OEPocketsphinxController sharedInstance].isListening) {
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition if we aren't already listening.
    }*/
    
    if(![OEPocketsphinxController sharedInstance].isListening) {
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:acoustic_model_name] languageModelIsJSGF:FALSE]; // Start speech recognition if we aren't already listening.
    }
   
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}



/*
 *  LanguageModelGenerator methods	
	generateLanguageModel
		args: languageName, languageCSV
			languageName: a reference to the language set, eg: "HomeScreenController", "SettingsPage"
				  If using different language sets for different sections, you'll need to be able to switch between them.
			languageCSV: a dictionary of words to recognise, eg: "OPEN PAGE,GOTO STEP ONE" 

		returns Error, or dict with Language & Dictionary file details.

		In your host app, you shoudl keep track of these for switching between sets later, eg:

			var languages = {
				"languageName_1": {
					"LMFile": "languageName_1.DMP",
					"dictionaryFile": "languageName_1.dic",
					"lmPath": "/path/to/Library/Caches/languageName_1.DMP",
					"dictionaryPath": "/path/to/Library/Caches/languageName_1.dic"
				},
				"languageName_2": {
					"LMFile": "languageName_2.DMP",
					"dictionaryFile": "languageName_2.dic",
					"lmPath": "/path/to/Library/Caches/languageName_2.DMP",
					"dictionaryPath": "/path/to/Library/Caches/languageName_2.dic"
				}
			};
 */
-(void)generateLanguageModel:(CDVInvokedUrlCommand*)command{	
    NSString *languageName = [command.arguments objectAtIndex:0];
    NSString *languageCSV = [command.arguments objectAtIndex:1];
 
    NSArray *languageArray = [languageCSV componentsSeparatedByString:@","];
       NSString *languageSecondaryCSV = [command.arguments objectAtIndex:2];
    NSArray *languageSecondaryArray = [languageSecondaryCSV componentsSeparatedByString:@","];
    finallanguageSecondaryArray= [languageSecondaryCSV componentsSeparatedByString:@","];

    
    
   /* NSArray *firstLanguageArray = @[@"BACKWARD",
                                    @"CHANGE",
                                    @"FORWARD",
                                    @"GO",
                                    @"LEFT",
                                    @"MODEL",
                                    @"RIGHT",
                                    @"TURN"];*/
    
    OELanguageModelGenerator *languageModelGenerator = [[OELanguageModelGenerator alloc] init];
    
    // languageModelGenerator.verboseLanguageModelGenerator = TRUE; // Uncomment me for verbose language model generator debug output.
    
    NSError *error = [languageModelGenerator generateLanguageModelFromArray:languageArray withFilesNamed:@"FirstOpenEarsDynamicLanguageModel" forAcousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" in order to create a language model for Spanish recognition instead of English.
    
    
    if(error) {
        NSLog(@"Dynamic language generator reported error %@", [error description]);
    } else {
        self.pathToFirstDynamicallyGeneratedLanguageModel = [languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:@"FirstOpenEarsDynamicLanguageModel"];
        self.pathToFirstDynamicallyGeneratedDictionary = [languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:@"FirstOpenEarsDynamicLanguageModel"];
    }
    
    self.usingStartingLanguageModel = TRUE; // This is not an OpenEars thing, this is just so I can switch back and forth between the two models in this sample app.
    
    // Here is an example of dynamically creating an in-app grammar.
    
    // We want it to be able to response to the speech "CHANGE MODEL" and a few other things.  Items we want to have recognized as a whole phrase (like "CHANGE MODEL")
    // we put into the array as one string (e.g. "CHANGE MODEL" instead of "CHANGE" and "MODEL"). This increases the probability that they will be recognized as a phrase. This works even better starting with version 1.0 of OpenEars.
    
   /* NSArray *secondLanguageArray = @[@"SUNDAY",
                                     @"MONDAY",
                                     @"TUESDAY",
                                     @"WEDNESDAY",
                                     @"THURSDAY",
                                     @"FRIDAY",
                                     @"SATURDAY",
                                     @"QUIDNUNC",
                                     @"CHANGE MODEL"];*/
    
    // The last entry, quidnunc, is an example of a word which will not be found in the lookup dictionary and will be passed to the fallback method. The fallback method is slower,
    // so, for instance, creating a new language model from dictionary words will be pretty fast, but a model that has a lot of unusual names in it or invented/rare/recent-slang
    // words will be slower to generate. You can use this information to give your users good UI feedback about what the expectations for wait times should be.
    
    // I don't think it's beneficial to lazily instantiate OELanguageModelGenerator because you only need to give it a single message and then release it.
    // If you need to create a very large model or any size of model that has many unusual words that have to make use of the fallback generation method,
    // you will want to run this on a background thread so you can give the user some UI feedback that the task is in progress.
    
    // generateLanguageModelFromArray:withFilesNamed returns an NSError which will either have a value of noErr if everything went fine or a specific error if it didn't.
    error = [languageModelGenerator generateLanguageModelFromArray:languageSecondaryArray withFilesNamed:@"SecondOpenEarsDynamicLanguageModel" forAcousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" in order to create a language model for Spanish recognition instead of English.
    
    //    NSError *error = [languageModelGenerator generateLanguageModelFromTextFile:[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath], @"OpenEarsCorpus.txt"] withFilesNamed:@"SecondOpenEarsDynamicLanguageModel" forAcousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]]; // Try this out to see how generating a language model from a corpus works.
    
    
    if(error) {
        NSLog(@"Dynamic language generator reported error %@", [error description]);
    }	else {
        
        self.pathToSecondDynamicallyGeneratedLanguageModel = [languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:@"SecondOpenEarsDynamicLanguageModel"]; // We'll set our new .languagemodel file to be the one to get switched to when the words "CHANGE MODEL" are recognized.
        self.pathToSecondDynamicallyGeneratedDictionary = [languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:@"SecondOpenEarsDynamicLanguageModel"];; // We'll set our new dictionary to be the one to get switched to when the words "CHANGE MODEL" are recognized.
        
        // Next, an informative message.
        
        NSLog(@"\n\nWelcome to the OpenEars sample project. This project understands the words:\nBACKWARD,\nCHANGE,\nFORWARD,\nGO,\nLEFT,\nMODEL,\nRIGHT,\nTURN,\nand if you say \"CHANGE MODEL\" it will switch to its dynamically-generated model which understands the words:\nCHANGE,\nMODEL,\nMONDAY,\nTUESDAY,\nWEDNESDAY,\nTHURSDAY,\nFRIDAY,\nSATURDAY,\nSUNDAY,\nQUIDNUNC");
        
        // This is how to start the continuous listening loop of an available instance of OEPocketsphinxController. We won't do this if the language generation failed since it will be listening for a command to change over to the generated language.
        
        [[OEPocketsphinxController sharedInstance] setActive:TRUE error:nil]; // Call this once before setting properties of the OEPocketsphinxController instance.
        
        //   [OEPocketsphinxController sharedInstance].pathToTestFile = [[NSBundle mainBundle] pathForResource:@"change_model_short" ofType:@"wav"];  // This is how you could use a test WAV (mono/16-bit/16k) rather than live recognition
        
        if(![OEPocketsphinxController sharedInstance].isListening) {
            [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition if we aren't already listening.
        }
    }
    
    
}


#pragma mark -
#pragma mark OEEventsObserver delegate methods

// What follows are all of the delegate methods you can optionally use once you've instantiated an OEEventsObserver and set its delegate to self.
// I've provided some pretty granular information about the exact phase of the Pocketsphinx listening loop, the Audio Session, and Flite, but I'd expect
// that the ones that will really be needed by most projects are the following:
//
//- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID;
//- (void) audioSessionInterruptionDidBegin;
//- (void) audioSessionInterruptionDidEnd;
//- (void) audioRouteDidChangeToRoute:(NSString *)newRoute;
//- (void) pocketsphinxDidStartListening;
//- (void) pocketsphinxDidStopListening;
//
// It isn't necessary to have a OEPocketsphinxController or a OEFliteController instantiated in order to use these methods.  If there isn't anything instantiated that will
// send messages to an OEEventsObserver, all that will happen is that these methods will never fire.  You also do not have to create a OEEventsObserver in
// the same class or view controller in which you are doing things with a OEPocketsphinxController or OEFliteController; you can receive updates from those objects in
// any class in which you instantiate an OEEventsObserver and set its delegate to self.


// This is an optional delegate method of OEEventsObserver which delivers the text of speech that Pocketsphinx heard and analyzed, along with its accuracy score and utterance ID.
- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    
    NSLog(@"Local callback: The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID); // Log it.
    if([hypothesis isEqualToString:@"CHANGE MODEL"]) { // If the user says "CHANGE MODEL", we will switch to the alternate model (which happens to be the dynamically generated model).
        
        // Here is an example of language model switching in OpenEars. Deciding on what logical basis to switch models is your responsibility.
        // For instance, when you call a customer service line and get a response tree that takes you through different options depending on what you say to it,
        // the models are being switched as you progress through it so that only relevant choices can be understood. The construction of that logical branching and
        // how to react to it is your job, OpenEars just lets you send the signal to switch the language model when you've decided it's the right time to do so.
        
        if(self.usingStartingLanguageModel) { // If we're on the starting model, switch to the dynamically generated one.
            
            // You can only change language models with ARPA grammars in OpenEars (the ones that end in .languagemodel or .DMP).
            // Trying to switch between JSGF models (the ones that end in .gram) will return no result.
            [[OEPocketsphinxController sharedInstance] changeLanguageModelToFile:self.pathToSecondDynamicallyGeneratedLanguageModel withDictionary:self.pathToSecondDynamicallyGeneratedDictionary];
            self.usingStartingLanguageModel = FALSE;
        } else { // If we're on the dynamically generated model, switch to the start model (this is just an example of a trigger and method for switching models).
            [[OEPocketsphinxController sharedInstance] changeLanguageModelToFile:self.pathToFirstDynamicallyGeneratedLanguageModel withDictionary:self.pathToFirstDynamicallyGeneratedDictionary];
            self.usingStartingLanguageModel = TRUE;
        }
    }
    NSString* jsString = [[NSString alloc] initWithFormat:@"cordova.plugins.VoiceRecognise.events.receivedHypothesis(\"%@\");",hypothesis];
    [self.commandDelegate evalJs:jsString];
    
    //self.heardTextView.text = [NSString stringWithFormat:@"Heard: \"%@\"", hypothesis]; // Show it in the status box.
    
    // This is how to use an available instance of OEFliteController. We're going to repeat back the command that we heard with the voice we've chosen.
  //  [self.fliteController say:[NSString stringWithFormat:@"You said %@",hypothesis] withVoice:self.slt];
}
-(void)say:(CDVInvokedUrlCommand*)command{
    NSString *phrase = [command.arguments objectAtIndex:0];
    NSString *phrase_out = [[NSString alloc] initWithFormat:@"%@",phrase];
    NSLog(@"fliteControllerSay: %@",phrase_out);
  [self.fliteController say:phrase_out withVoice:self.slt];
}

#ifdef kGetNbest
- (void) pocketsphinxDidReceiveNBestHypothesisArray:(NSArray *)hypothesisArray { // Pocketsphinx has an n-best hypothesis dictionary.
    NSLog(@"Local callback:  hypothesisArray is %@",hypothesisArray);
}
#endif
// An optional delegate method of OEEventsObserver which informs that there was an interruption to the audio session (e.g. an incoming phone call).
- (void) audioSessionInterruptionDidBegin {
    NSLog(@"Local callback:  AudioSession interruption began."); // Log it.
  //  self.statusTextView.text = @"Status: AudioSession interruption began."; // Show it in the status box.
    NSError *error = nil;
    if([OEPocketsphinxController sharedInstance].isListening) {
        error = [[OEPocketsphinxController sharedInstance] stopListening]; // React to it by telling Pocketsphinx to stop listening (if it is listening) since it will need to restart its loop after an interruption.
        if(error) NSLog(@"Error while stopping listening in audioSessionInterruptionDidBegin: %@", error);
    }
}

// An optional delegate method of OEEventsObserver which informs that the interruption to the audio session ended.
- (void) audioSessionInterruptionDidEnd {
    NSLog(@"Local callback:  AudioSession interruption ended."); // Log it.
    //self.statusTextView.text = @"Status: AudioSession interruption ended."; // Show it in the status box.
    // We're restarting the previously-stopped listening loop.
    if(![OEPocketsphinxController sharedInstance].isListening){
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition if we aren't currently listening.
    }
}

// An optional delegate method of OEEventsObserver which informs that the audio input became unavailable.
- (void) audioInputDidBecomeUnavailable {
    NSLog(@"Local callback:  The audio input has become unavailable"); // Log it.
  ///  self.statusTextView.text = @"Status: The audio input has become unavailable"; // Show it in the status box.
    NSError *error = nil;
    if([OEPocketsphinxController sharedInstance].isListening){
        error = [[OEPocketsphinxController sharedInstance] stopListening]; // React to it by telling Pocketsphinx to stop listening since there is no available input (but only if we are listening).
        if(error) NSLog(@"Error while stopping listening in audioInputDidBecomeUnavailable: %@", error);
    }
}

// An optional delegate method of OEEventsObserver which informs that the unavailable audio input became available again.
- (void) audioInputDidBecomeAvailable {
    NSLog(@"Local callback: The audio input is available"); // Log it.
    //self.statusTextView.text = @"Status: The audio input is available"; // Show it in the status box.
    if(![OEPocketsphinxController sharedInstance].isListening) {
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition, but only if we aren't already listening.
    }
}
// An optional delegate method of OEEventsObserver which informs that there was a change to the audio route (e.g. headphones were plugged in or unplugged).
- (void) audioRouteDidChangeToRoute:(NSString *)newRoute {
    NSLog(@"Local callback: Audio route change. The new audio route is %@", newRoute); // Log it.
   // self.statusTextView.text = [NSString stringWithFormat:@"Status: Audio route change. The new audio route is %@",newRoute]; // Show it in the status box.
    
    NSError *error = [[OEPocketsphinxController sharedInstance] stopListening]; // React to it by telling the Pocketsphinx loop to shut down and then start listening again on the new route
    
    if(error)NSLog(@"Local callback: error while stopping listening in audioRouteDidChangeToRoute: %@",error);
    
    if(![OEPocketsphinxController sharedInstance].isListening) {
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition if we aren't already listening.
    }
}

// An optional delegate method of OEEventsObserver which informs that the Pocketsphinx recognition loop has entered its actual loop.
// This might be useful in debugging a conflict between another sound class and Pocketsphinx.
- (void) pocketsphinxRecognitionLoopDidStart {
    
    NSLog(@"Local callback: Pocketsphinx started."); // Log it.
   // self.statusTextView.text = @"Status: Pocketsphinx started."; // Show it in the status box.
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is now listening for speech.
- (void) pocketsphinxDidStartListening {
    
    NSLog(@"Local callback: Pocketsphinx is now listening."); // Log it.
   /// NSLog(@"Pocketsphinx did start listening");
   // [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.startedListening()"];
   /* self.statusTextView.text = @"Status: Pocketsphinx is now listening."; // Show it in the status box.
    
    self.startButton.hidden = TRUE; // React to it with some UI changes.
    self.stopButton.hidden = FALSE;
    self.suspendListeningButton.hidden = FALSE;
    self.resumeListeningButton.hidden = TRUE;*/


}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx detected speech and is starting to process it.
- (void) pocketsphinxDidDetectSpeech {
    NSLog(@"Local callback: Pocketsphinx has detected speech."); // Log it.
  //  [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.detectedSpeech()"];
  //  self.statusTextView.text = @"Status: Pocketsphinx has detected speech."; // Show it in the status box.
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx detected a second of silence, indicating the end of an utterance.
// This was added because developers requested being able to time the recognition speed without the speech time. The processing time is the time between
// this method being called and the hypothesis being returned.
- (void) pocketsphinxDidDetectFinishedSpeech {
    NSLog(@"Local callback: Pocketsphinx has detected a second of silence, concluding an utterance."); // Log it.
   // [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.finishedDetectingSpeech()"];
  //  self.statusTextView.text = @"Status: Pocketsphinx has detected finished speech."; // Show it in the status box.
}


// An optional delegate method of OEEventsObserver which informs that Pocketsphinx has exited its recognition loop, most
// likely in response to the OEPocketsphinxController being told to stop listening via the stopListening method.
- (void) pocketsphinxDidStopListening {
    NSLog(@"Local callback: Pocketsphinx has stopped listening."); // Log it.
    // [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.stoppedListening()"];
   // self.statusTextView.text = @"Status: Pocketsphinx has stopped listening."; // Show it in the status box.
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is still in its listening loop but it is not
// Going to react to speech until listening is resumed.  This can happen as a result of Flite speech being
// in progress on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
// or as a result of the OEPocketsphinxController being told to suspend recognition via the suspendRecognition method.
- (void) pocketsphinxDidSuspendRecognition {
    NSLog(@"Local callback: Pocketsphinx has suspended recognition."); // Log it.
   // [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.suspendedRecognition()"];
   // self.statusTextView.text = @"Status: Pocketsphinx has suspended recognition."; // Show it in the status box.
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is still in its listening loop and after recognition
// having been suspended it is now resuming.  This can happen as a result of Flite speech completing
// on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
// or as a result of the OEPocketsphinxController being told to resume recognition via the resumeRecognition method.
- (void) pocketsphinxDidResumeRecognition {
    NSLog(@"Local callback: Pocketsphinx has resumed recognition."); // Log it.
  //  [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.resumedRecognition()"];
   // self.statusTextView.text = @"Status: Pocketsphinx has resumed recognition."; // Show it in the status box.
}

// An optional delegate method which informs that Pocketsphinx switched over to a new language model at the given URL in the course of
// recognition. This does not imply that it is a valid file or that recognition will be successful using the file.
- (void) pocketsphinxDidChangeLanguageModelToFile:(NSString *)newLanguageModelPathAsString andDictionary:(NSString *)newDictionaryPathAsString {
    NSLog(@"Local callback: Pocketsphinx is now using the following language model: \n%@ and the following dictionary: %@",newLanguageModelPathAsString,newDictionaryPathAsString);
   // NSString* jsString = [[NSString alloc] initWithFormat:@"cordova.plugins.VoiceRecognise.events.changedLanguageModelToFile(\"%@\",\"%@\")",newLanguageModelPathAsString,newDictionaryPathAsString];
   // [self.commandDelegate evalJs:jsString];
}

// An optional delegate method of OEEventsObserver which informs that Flite is speaking, most likely to be useful if debugging a
// complex interaction between sound classes. You don't have to do anything yourself in order to prevent Pocketsphinx from listening to Flite talk and trying to recognize the speech.
- (void) fliteDidStartSpeaking {
    NSLog(@"Local callback: Flite has started speaking"); // Log it.
   // [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.startedSpeaking()"];
   // self.statusTextView.text = @"Status: Flite has started speaking."; // Show it in the status box.
}

// An optional delegate method of OEEventsObserver which informs that Flite is finished speaking, most likely to be useful if debugging a
// complex interaction between sound classes.
- (void) fliteDidFinishSpeaking {
    NSLog(@"Local callback: Flite has finished speaking"); // Log it.
   // [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.finishedSpeaking()"];
    //self.statusTextView.text = @"Status: Flite has finished speaking."; // Show it in the status box.
}

- (void) pocketSphinxContinuousSetupDidFailWithReason:(NSString *)reasonForFailure { // This can let you know that something went wrong with the recognition loop startup. Turn on [OELogging startOpenEarsLogging] to learn why.
    NSLog(@"Local callback: Setting up the continuous recognition loop has failed for the reason %@, please turn on [OELogging startOpenEarsLogging] to learn more.", reasonForFailure); // Log it.
    //self.statusTextView.text = @"Status: Not possible to start recognition loop."; // Show it in the status box.
}

- (void) pocketSphinxContinuousTeardownDidFailWithReason:(NSString *)reasonForFailure { // This can let you know that something went wrong with the recognition loop startup. Turn on [OELogging startOpenEarsLogging] to learn why.
    NSLog(@"Local callback: Tearing down the continuous recognition loop has failed for the reason %@, please turn on [OELogging startOpenEarsLogging] to learn more.", reasonForFailure); // Log it.
    //self.statusTextView.text = @"Status: Not possible to cleanly end recognition loop."; // Show it in the status box.
}

- (void) testRecognitionCompleted { // A test file which was submitted for direct recognition via the audio driver is done.
    NSLog(@"Local callback: A test file which was submitted for direct recognition via the audio driver is done."); // Log it.
    NSError *error = nil;
    if([OEPocketsphinxController sharedInstance].isListening) { // If we're listening, stop listening.
        error = [[OEPocketsphinxController sharedInstance] stopListening];
        if(error) NSLog(@"Error while stopping listening in testRecognitionCompleted: %@", error);
    }
    //[self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.testRecognitionCompleted()"];
    
}
/** Pocketsphinx couldn't start because it has no mic permissions (will only be returned on iOS7 or later).*/
- (void) pocketsphinxFailedNoMicPermissions {
    NSLog(@"Local callback: The user has never set mic permissions or denied permission to this app's mic, so listening will not start.");
    self.startupFailedDueToLackOfPermissions = TRUE;
}

/** The user prompt to get mic permissions, or a check of the mic permissions, has completed with a TRUE or a FALSE result  (will only be returned on iOS7 or later).*/
- (void) micPermissionCheckCompleted:(BOOL)result {
    if(result) {
        self.restartAttemptsDueToPermissionRequests++;
        if(self.restartAttemptsDueToPermissionRequests == 1 && self.startupFailedDueToLackOfPermissions) { // If we get here because there was an attempt to start which failed due to lack of permissions, and now permissions have been requested and they returned true, we restart exactly once with the new permissions.
            NSError *error = nil;
            if([OEPocketsphinxController sharedInstance].isListening){
                error = [[OEPocketsphinxController sharedInstance] stopListening]; // Stop listening if we are listening.
                if(error) NSLog(@"Error while stopping listening in micPermissionCheckCompleted: %@", error);
            }
            if(!error && ![OEPocketsphinxController sharedInstance].isListening) { // If there was no error and we aren't listening, start listening.
                [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition.
                self.startupFailedDueToLackOfPermissions = FALSE;
            }
        }
    }
}


-(void)setMatchWord:(CDVInvokedUrlCommand*)command{
    NSString *languageName = [command.arguments objectAtIndex:0];
    strMatchWord = [command.arguments objectAtIndex:1];
    NSString *tempstrMatchWord =[command.arguments objectAtIndex:1];
    tempstrMatchWord=[NSString stringWithFormat:@"%@,null",tempstrMatchWord];
     NSArray *languageArray = [tempstrMatchWord componentsSeparatedByString:@","];
    //    NSError *error = [self.language_model_generator generateLanguageModelFromArray:languageArray withFilesNamed:languageName forAcousticModelAtPath:self.acoustic_model];
    //
    NSError *error = nil;
    if([error code] != noErr) {
        NSString* errorMessage = [NSString stringWithFormat:@"setMatchWord reported error: %@", [error description]];
        NSLog(@"%@",errorMessage);
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        
    } else {

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:strMatchWord];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
   // NSArray *languageArray = [languageCSV componentsSeparatedByString:@","];
   
}

/*
 *  PocketsphinxController methods
	Start & Stop.
	In the simple case, you'd only generate one language, and auto-start listening with that.
	Then just need the argumentless stop & resume methods.
 */
-(void)resumeListening:(CDVInvokedUrlCommand*)command{
    ////old//  [self.pocket_sphinx_controller startListeningWithLanguageModelAtPath:self.path_to_dynamic_language_model dictionaryAtPath:self.path_to_dynamic_grammar acousticModelAtPath:self.acoustic_model languageModelIsJSGF:FALSE];
}

-(void)stopListening:(CDVInvokedUrlCommand*)command{
    
    NSError *error = nil;
    if([OEPocketsphinxController sharedInstance].isListening) { // Stop if we are currently listening.
        error = [[OEPocketsphinxController sharedInstance] stopListening];
        if(error)NSLog(@"Error stopping listening in stopButtonAction: %@", error);
    }
    
    
    ///old//[self.pocket_sphinx_controller stopListening];
}

-(void)suspendRecognition:(CDVInvokedUrlCommand*)command{
    //old// [self.pocket_sphinx_controller suspendRecognition];
     [[OEPocketsphinxController sharedInstance] suspendRecognition];
}

-(void)resumeRecognition:(CDVInvokedUrlCommand*)command{
      [[OEPocketsphinxController sharedInstance] resumeRecognition];
    //old//  [self.pocket_sphinx_controller resumeRecognition];
}


/*
	If using multiple langauge sets, you can start listening/switch to new model with the following two:
	In both cases, args: languagePath, dictionaryPath (as retrieved from your language generation)
*/
-(void)startListeningWithLanguageModelAtPath:(CDVInvokedUrlCommand*)command{
    self.current_language_model = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath], [command.arguments objectAtIndex:0]];
    self.current_dictionary = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath], [command.arguments objectAtIndex:1]];
    ///old//[self.pocket_sphinx_controller startListeningWithLanguageModelAtPath:self.current_language_model dictionaryAtPath:self.current_dictionary acousticModelAtPath:self.acoustic_model languageModelIsJSGF:FALSE];
}


-(void)changeLanguageModelToFile:(CDVInvokedUrlCommand*)command{
    self.current_language_model = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath], [command.arguments objectAtIndex:0]];
    self.current_dictionary = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath], [command.arguments objectAtIndex:1]];
   //old// [self.pocket_sphinx_controller changeLanguageModelToFile:self.current_language_model withDictionary:self.current_dictionary];
}


/*
 *  FliteController methods
	Say a phrase.
		args: phrase (srting), sends it to the Tex-to-Speech module
 */



/*
- (void) pocketsphinxDidStartListening {
    self.started_listening = [[NSNumber alloc] initWithInteger:1];
    
    NSLog(@"Pocketsphinx did start listening");
    [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.startedListening()"];
}

- (void) pocketsphinxDidStopListening {
    self.started_listening = [[NSNumber alloc] initWithInteger:0];
    NSLog(@"Pocketsphinx did stop listening");
    [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.stoppedListening()"];
}

- (void) pocketsphinxDidSuspendRecognition {
    NSLog(@"Pockesphinx did suspend recognition");
    [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.suspendedRecognition()"];
}

- (void) pocketsphinxDidResumeRecognition {
    NSLog(@"Pockesphinx did resume recognition");
    [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.resumedRecognition()"];
}

- (void) pocketsphinxDidDetectSpeech {
   
        NSLog(@"Pockesphinx did detect speech");
    [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.detectedSpeech()"];
}
- (void) pocketsphinxDidDetectFinishedSpeech {
  //  [self stopAudio];
 
    NSLog(@"Pocketsphinx did detect finished speech");
    [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.finishedDetectingSpeech()"];
}

- (void) pocketsphinxDidStartCalibration {
	NSLog(@"Pocketsphinx calibration has started.");
    [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.startedCalibration()"];

}

- (void) pocketsphinxDidCompleteCalibration {
	NSLog(@"Pocketsphinx calibration is complete.");
    [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.finishedCalibration()"];

}


- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    NSLog(@"Pocketsphinx received a hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID);
    NSString* jsString = [[NSString alloc] initWithFormat:@"cordova.plugins.VoiceRecognise.events.receivedHypothesis(\"%@\",%@,%@);",hypothesis,recognitionScore,utteranceID];
    [self.commandDelegate evalJs:jsString];
}

- (void) pocketsphinxDidChangeLanguageModelToFile:(NSString *)newLanguageModelPathAsString andDictionary:(NSString *)newDictionaryPathAsString{
    NSLog(@"Pocketsphinx is now using the following language model: \n%@ and the following dictionary: %@",newLanguageModelPathAsString,newDictionaryPathAsString);
    NSString* jsString = [[NSString alloc] initWithFormat:@"cordova.plugins.VoiceRecognise.events.changedLanguageModelToFile(\"%@\",\"%@\")",newLanguageModelPathAsString,newDictionaryPathAsString];
    [self.commandDelegate evalJs:jsString];
}

- (void) pocketSphinxContinuousSetupDidFail {
 	NSLog(@"Setting up the continuous recognition loop has failed for some reason, please turn on VoiceRecogniseLogging to learn more.");
    [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.continuousSetupDidFaill()"];
}

- (void) testRecognitionCompleted {
	NSLog(@"A test file that was submitted for recognition is now complete.");
    [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.testRecognitionCompleted()"];
}



 //  Flite Delegate Methods
 
- (void) fliteDidStartSpeaking {
	NSLog(@"Flite has started speaking");
    [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.startedSpeaking()"];
}

- (void) fliteDidFinishSpeaking {
	NSLog(@"Flite has finished speaking");
    [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.finishedSpeaking()"];
}



//  Audio Delegate Methods

- (void) audioSessionInterruptionDidBegin{
    NSLog(@"audio session interruption did begin");
    [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.audioSessionInterruptionDidBegin()"];
    
}
- (void) audioSessionInterruptionDidEnd{
    NSLog(@"audio session interruption did end");
    [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.audioSessionInterruptionDidEnd()"];
    
}
- (void) audioInputDidBecomeUnavailable{
    NSLog(@"audio did become unavailable");
    [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.audioInputDidBecomeUnavailable{()"];
}
- (void) audioInputDidBecomeAvailable{
    NSLog(@"audio input did become available");
    [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.audioInputDidBecomeAvailable()"];
}
- (void) audioRouteDidChangeToRoute:(NSString *)newRoute{
    NSLog(@"audio route did change to route: %@", newRoute);
    [self.commandDelegate evalJs:@"cordova.plugins.VoiceRecognise.events.audioRouteDidChangeToRoute()"];
}

*/

/*
 *  Cleanup
 */
-(void) dealloc {
    ///old//VoiceRecognise_events_observer.delegate = nil;
}






/**
 * @js-interface
 *
 * Registriert die Listener für die (sleep/resume) Events.
 */
- (void) observeLifeCycle:(CDVInvokedUrlCommand *)command
{
    // Methode pluginInitialize wird aufgerufen, falls Instanz erstellt wurde
}

/**
 * @js-interface
 *
 * Aktiviert den Hintergrundmodus.
 */
- (void) enable:(CDVInvokedUrlCommand *)command
{
    [self enableMode];
}

/**
 * @js-interface
 *
 * Deaktiviert den Hintergrundmodus.
 */
- (void) disable:(CDVInvokedUrlCommand *)command
{
    [self disableMode];
}

/**
 * Aktiviert den Hintergrundmodus.
 */
- (void) enableMode
{
    _enabled = true;
}

/**
 * Deaktiviert den Hintergrundmodus.
 */
- (void) disableMode
{
    _enabled = false;
}

/**
 * Registriert die Listener für die (sleep/resume) Events und startet bzw. stoppt die Geo-Lokalisierung.
 */
- (void) pluginInitialize
{
    
    self.fliteController = [[OEFliteController alloc] init];
    self.openEarsEventsObserver = [[OEEventsObserver alloc] init];
    self.openEarsEventsObserver.delegate = self;
    self.slt = [[Slt alloc] init];
    
    self.restartAttemptsDueToPermissionRequests = 0;
    self.startupFailedDueToLackOfPermissions = FALSE;
    
    // [OELogging startOpenEarsLogging]; // Uncomment me for OELogging, which is verbose logging about internal OpenEars operations such as audio settings. If you have issues, show this logging in the forums.
    //[OEPocketsphinxController sharedInstance].verbosePocketSphinx = TRUE; // Uncomment this for much more verbose speech recognition engine output. If you have issues, show this logging in the forums.
    
    [self.openEarsEventsObserver setDelegate:self]; // Make this class the delegate of OpenEarsObserver so we can get all of the messages about what OpenEars is doing.
    
    [[OEPocketsphinxController sharedInstance] setActive:TRUE error:nil]; // Call this before setting any OEPocketsphinxController characteristics
    
    // This is the language model we're going to start up with. The only reason I'm making it a class property is that I reuse it a bunch of times in this example,
    // but you can pass the string contents directly to OEPocketsphinxController:startListeningWithLanguageModelAtPath:dictionaryAtPath:languageModelIsJSGF:
    
    NSArray *firstLanguageArray = @[@"BACKWARD",
                                    @"CHANGE",
                                    @"FORWARD",
                                    @"GO",
                                    @"LEFT",
                                    @"MODEL",
                                    @"RIGHT",
                                    @"TURN"];
    
    OELanguageModelGenerator *languageModelGenerator = [[OELanguageModelGenerator alloc] init];
    
    // languageModelGenerator.verboseLanguageModelGenerator = TRUE; // Uncomment me for verbose language model generator debug output.
    
    NSError *error = [languageModelGenerator generateLanguageModelFromArray:firstLanguageArray withFilesNamed:@"FirstOpenEarsDynamicLanguageModel" forAcousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" in order to create a language model for Spanish recognition instead of English.
    
    
    if(error) {
        NSLog(@"Dynamic language generator reported error %@", [error description]);
    } else {
        self.pathToFirstDynamicallyGeneratedLanguageModel = [languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:@"FirstOpenEarsDynamicLanguageModel"];
        self.pathToFirstDynamicallyGeneratedDictionary = [languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:@"FirstOpenEarsDynamicLanguageModel"];
    }
    
    self.usingStartingLanguageModel = TRUE; // This is not an OpenEars thing, this is just so I can switch back and forth between the two models in this sample app.
    
    // Here is an example of dynamically creating an in-app grammar.
    
    // We want it to be able to response to the speech "CHANGE MODEL" and a few other things.  Items we want to have recognized as a whole phrase (like "CHANGE MODEL")
    // we put into the array as one string (e.g. "CHANGE MODEL" instead of "CHANGE" and "MODEL"). This increases the probability that they will be recognized as a phrase. This works even better starting with version 1.0 of OpenEars.
    
    NSArray *secondLanguageArray = @[@"SUNDAY",
                                     @"MONDAY",
                                     @"TUESDAY",
                                     @"WEDNESDAY",
                                     @"THURSDAY",
                                     @"FRIDAY",
                                     @"SATURDAY",
                                     @"QUIDNUNC",
                                     @"CHANGE MODEL"];
    
    // The last entry, quidnunc, is an example of a word which will not be found in the lookup dictionary and will be passed to the fallback method. The fallback method is slower,
    // so, for instance, creating a new language model from dictionary words will be pretty fast, but a model that has a lot of unusual names in it or invented/rare/recent-slang
    // words will be slower to generate. You can use this information to give your users good UI feedback about what the expectations for wait times should be.
    
    // I don't think it's beneficial to lazily instantiate OELanguageModelGenerator because you only need to give it a single message and then release it.
    // If you need to create a very large model or any size of model that has many unusual words that have to make use of the fallback generation method,
    // you will want to run this on a background thread so you can give the user some UI feedback that the task is in progress.
    
    // generateLanguageModelFromArray:withFilesNamed returns an NSError which will either have a value of noErr if everything went fine or a specific error if it didn't.
    error = [languageModelGenerator generateLanguageModelFromArray:secondLanguageArray withFilesNamed:@"SecondOpenEarsDynamicLanguageModel" forAcousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" in order to create a language model for Spanish recognition instead of English.
    
    //    NSError *error = [languageModelGenerator generateLanguageModelFromTextFile:[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath], @"OpenEarsCorpus.txt"] withFilesNamed:@"SecondOpenEarsDynamicLanguageModel" forAcousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]]; // Try this out to see how generating a language model from a corpus works.
    
    
    if(error) {
        NSLog(@"Dynamic language generator reported error %@", [error description]);
    }	else {
        
        self.pathToSecondDynamicallyGeneratedLanguageModel = [languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:@"SecondOpenEarsDynamicLanguageModel"]; // We'll set our new .languagemodel file to be the one to get switched to when the words "CHANGE MODEL" are recognized.
        self.pathToSecondDynamicallyGeneratedDictionary = [languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:@"SecondOpenEarsDynamicLanguageModel"];; // We'll set our new dictionary to be the one to get switched to when the words "CHANGE MODEL" are recognized.
        
        // Next, an informative message.
        
        NSLog(@"\n\nWelcome to the OpenEars sample project. This project understands the words:\nBACKWARD,\nCHANGE,\nFORWARD,\nGO,\nLEFT,\nMODEL,\nRIGHT,\nTURN,\nand if you say \"CHANGE MODEL\" it will switch to its dynamically-generated model which understands the words:\nCHANGE,\nMODEL,\nMONDAY,\nTUESDAY,\nWEDNESDAY,\nTHURSDAY,\nFRIDAY,\nSATURDAY,\nSUNDAY,\nQUIDNUNC");
        
        // This is how to start the continuous listening loop of an available instance of OEPocketsphinxController. We won't do this if the language generation failed since it will be listening for a command to change over to the generated language.
        
        [[OEPocketsphinxController sharedInstance] setActive:TRUE error:nil]; // Call this once before setting properties of the OEPocketsphinxController instance.
        
        //   [OEPocketsphinxController sharedInstance].pathToTestFile = [[NSBundle mainBundle] pathForResource:@"change_model_short" ofType:@"wav"];  // This is how you could use a test WAV (mono/16-bit/16k) rather than live recognition
        
        if(![OEPocketsphinxController sharedInstance].isListening) {
            [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition if we aren't already listening.
        }
    }
    
    
    
    
    inBG=FALSE;
    [self enableMode];
    bgTask = [[BackgroundTask alloc] init];
    if (&UIApplicationDidEnterBackgroundNotification && &UIApplicationWillEnterForegroundNotification) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activateMode) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deactivateMode) name:UIApplicationWillEnterForegroundNotification object:nil];
    } else {
        [self activateMode];
    }
    
    
    
}

/**
 * Startet das Aktualisieren des Standpunktes.
 */
- (void) activateMode
{
    inBG= TRUE;
    //  [self performSelector:@selector(callinbackground) withObject:nil afterDelay:.1];
    NSLog(@"active mode");
    
    //
    
    //    [self suspendRecognition];
    //
    //    [self stopListening];
    //
   ///old// [OpenEarsLogging startOpenEarsLogging];
    
    //    [self generateLanguageModel];
    //   // [self startAudioSession];
    //   [self resumeRecognition];
    //    [self resumeListening];
    
    [bgTask startBackgroundTasks:7 target:self selector:@selector(backgroundCallback:)];
}

-(void) backgroundCallback:(id)info
{
    
    // NSLog(@"call in background :: %@",self.path_to_dynamic_language_model);
    NSLog(@"########");
    NSLog(@"###### BG TASK RUNNING %@",strMatchWord);
    
    
    //    [self generateLanguageModel];
    //
    //
    //    [self startAudioSession];
    //    [self resumeRecognition];
    //    [self resumeListening];
    //[self.flite_controller say:strMatchWord withVoice:self.slt];
}

/**
 * Beendet das Aktualisieren des Standpunktes.
 */
- (void) deactivateMode
{
    inBG=FALSE;
    //    [bgtimer invalidate];
    //  [RecogniseBg stopBackgroundTask];
    [bgTask stopBackgroundTask];
    NSLog(@"deactive mode");
    
}
-(void)PlayBackgroundFile:(CDVInvokedUrlCommand*)command{
    NSLog(@"Play Background file hhhhhhh");
    
    
    
    //    NSString *soundFilePath =
    //
    //    [[NSBundle mainBundle] pathForResource: @"sound"
    //
    //                                    ofType: @"wav"];
    //
    //
    //
    //    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
    //
    //
    //
    
    NSString *tempDir = NSTemporaryDirectory ();
    
    NSString *soundFilePath =
    
    [tempDir stringByAppendingString: @"sound.caf"];
    
    
    
    NSURL *newURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
    
    //    AVAudioPlayer *newPlayer =
    //
    //    [[AVAudioPlayer alloc] initWithContentsOfURL: newURL
    //
    //                                           error: nil];
    //
    //    [newPlayer prepareToPlay];
    //
    //    [newPlayer setDelegate: self];
    //
    //    [newPlayer play];
    
    NSError *error;
    avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:newURL error:&error];
    
    if (!error)
    {
        [avPlayer prepareToPlay];
        [avPlayer play];
        
        NSLog(@"File is playing");
    }
    NSString *languageName = [command.arguments objectAtIndex:0];
    strMatchWord = [command.arguments objectAtIndex:1];
    
    // NSError *error = nil;
    
    
    if([error code] != noErr) {
        NSString* errorMessage = [NSString stringWithFormat:@"PlayBackgroundFile reported error: %@", [error description]];
        NSLog(@"%@",errorMessage);
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        
    } else {
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Play"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

-(void)StopBackgroundFile:(CDVInvokedUrlCommand*)command{
    NSLog(@"stop Background file hhhhhhh");
    
    
    [avPlayer stop];
    NSString *languageName = [command.arguments objectAtIndex:0];
    strMatchWord = [command.arguments objectAtIndex:1];
    
    NSError *error = nil;
    
    
    if([error code] != noErr) {
        NSString* errorMessage = [NSString stringWithFormat:@"PlayBackgroundFile reported error: %@", [error description]];
        NSLog(@"%@",errorMessage);
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        
    } else {
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Play"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

-(void)startRecord:(CDVInvokedUrlCommand*)command{
    [self RecordSpeech];
    
    NSError *error = nil;
    if([error code] != noErr) {
        NSString* errorMessage = [NSString stringWithFormat:@"start recording reported error: %@", [error description]];
        NSLog(@"%@",errorMessage);
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        
    } else {
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:strMatchWord];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}
-(void)stopRecord:(CDVInvokedUrlCommand*)command{
    [self stopAudio];
    
    
    NSError *error = nil;
    if([error code] != noErr) {
        NSString* errorMessage = [NSString stringWithFormat:@"stop recording reported error: %@", [error description]];
        NSLog(@"%@",errorMessage);
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        
    } else {
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:strMatchWord];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}
-(void)playRecord:(CDVInvokedUrlCommand*)command{
    [self playAudio];
    
    
    NSError *error = nil;
    if([error code] != noErr) {
        NSString* errorMessage = [NSString stringWithFormat:@"play recording reported error: %@", [error description]];
        NSLog(@"%@",errorMessage);
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        
    } else {
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:strMatchWord];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}
-(void) RecordSpeech
{
    
    
    NSLog(@"start record");
}
-(void) stopAudio
{
   
}
-(void) playAudio
{
  
        
   
}

@end
