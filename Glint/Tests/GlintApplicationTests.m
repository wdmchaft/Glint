//
//  GlintApplicationTests.m
//  Glint
//
//  Created by Jakob Borg on 9/23/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "GlintApplicationTests.h"
#import "JBGPXReader.h"
#import "GlintAppDelegate.h"
#import "MainScreenViewController.h"

@implementation GlintApplicationTests

- (void)setUp {        
        // Set lap length to 100m so we get about five laps on the coming run
        [[NSUserDefaults standardUserDefaults] setFloat:100.0f forKey:@"lap_length"];
        // Set required GPS precision to 100m so the read values are Ok
        [[NSUserDefaults standardUserDefaults] setFloat:100.0f forKey:@"gps_minprec"];
}

- (void)test_a_WalkAndPause {        
        // Fetch the application delegate
        GlintAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        STAssertNotNil(appDelegate, @"Cannot find the application delegate.");

        // Read a reference file with positions
        NSString* refFile = [NSString stringWithFormat:@"%@/reference0.gpx", [[NSBundle mainBundle] bundlePath]];
        JBGPXReader *reader = [[JBGPXReader alloc] initWithFilename:refFile];
        NSArray *locations = [reader locations];
        int intres = [locations count];
        STAssertEquals(intres, 47, @"Locations count is wrong");
        
        GPSManager *gps = [appDelegate gpsManager];
        [gps clearForUnitTests];
        
        // Walk the track forwards
        CLLocation *prevLoc = nil;
        for (int i = 0; i < 20; i++) {
                CLLocation *loc = [locations objectAtIndex:i];
                [gps locationManager:nil didUpdateToLocation:loc fromLocation:prevLoc];
                prevLoc = loc;
                STAssertEquals([gps isPrecisionAcceptable], YES, @"GPSManager.isPrecision is wrong");
        }
        
        // Check total distance, elapsed time
        STAssertEqualsWithAccuracy([[gps math] elapsedTime], 224.0f, 1.0f, @"Elapsed time is wrong after first walk");
        STAssertEqualsWithAccuracy([[gps math] totalDistance], 240.0f, 1.0f, @"Total distance is wrong after first walk");
        STAssertEqualsWithAccuracy([[gps math] currentSpeed], 0.9f, 0.1f, @"Current speed is wrong after first walk");
        STAssertEqualsWithAccuracy([[gps math] averageSpeed], 1.1f, 0.1f, @"Average speed is wrong after first walk");

        // Stop processing updates
        [gps pauseUpdates];
        
        // Walk a little more
        for (int i = 20; i < 30; i++) {
                CLLocation *loc = [locations objectAtIndex:i];
                [gps locationManager:nil didUpdateToLocation:loc fromLocation:prevLoc];
                prevLoc = loc;
                STAssertEquals([gps isPrecisionAcceptable], YES, @"GPSManager.isPrecision is wrong");
        }
        
        // Check total distance, elapsed time
        STAssertEqualsWithAccuracy([[gps math] elapsedTime], 224.0f, 10.0f, @"Elapsed time is wrong after pause");
        STAssertEqualsWithAccuracy([[gps math] totalDistance], 240.0f, 1.0f, @"Total distance is wrong after pause");
        STAssertEqualsWithAccuracy([[gps math] currentSpeed], 0.9f, 0.1f, @"Current speed is wrong after pause");
        STAssertEqualsWithAccuracy([[gps math] averageSpeed], 1.1f, 0.1f, @"Average speed is wrong after pause");

        // Resume handling updates
        [gps resumeUpdates];
        
        // Check total distance, elapsed time
        STAssertEqualsWithAccuracy([[gps math] elapsedTime], 224.0f, 10.0f, @"Elapsed time is wrong after resume");
        STAssertEqualsWithAccuracy([[gps math] totalDistance], 240.0f, 1.0f, @"Total distance is wrong after resume");
        STAssertEqualsWithAccuracy([[gps math] currentSpeed], 0.9f, 0.1f, @"Current speed is wrong after resume");
        STAssertEqualsWithAccuracy([[gps math] averageSpeed], 1.1f, 0.1f, @"Average speed is wrong after resume");

        // Walk one step
        for (int i = 30; i < 31; i++) {
                CLLocation *loc = [locations objectAtIndex:i];
                [gps locationManager:nil didUpdateToLocation:loc fromLocation:prevLoc];
                prevLoc = loc;
                STAssertEquals([gps isPrecisionAcceptable], YES, @"GPSManager.isPrecision is wrong");
        }
        
        // Check total distance, elapsed time
        STAssertEqualsWithAccuracy([[gps math] elapsedTime], 224.0f, 10.0f, @"Elapsed time is wrong after resume plus one step");
        STAssertEqualsWithAccuracy([[gps math] totalDistance], 240.0f, 1.0f, @"Total distance is wrong after resume plus one step");
        STAssertEqualsWithAccuracy([[gps math] currentSpeed], 0.9f, 0.1f, @"Current speed is wrong after resume plus one step");
        STAssertEqualsWithAccuracy([[gps math] averageSpeed], 1.1f, 0.1f, @"Average speed is wrong after resume plus one step");

        // Finish the walk
        for (int i = 31; i < 47; i++) {
                CLLocation *loc = [locations objectAtIndex:i];
                [gps locationManager:nil didUpdateToLocation:loc fromLocation:prevLoc];
                prevLoc = loc;
                STAssertEquals([gps isPrecisionAcceptable], YES, @"GPSManager.isPrecision is wrong");
        }
        
        // Check total distance, elapsed time
        STAssertEqualsWithAccuracy([[gps math] elapsedTime], 485.0f, 1.0f, @"Elapsed time is wrong at completion");
        STAssertEqualsWithAccuracy([[gps math] totalDistance], 460.0f, 1.0f, @"Total distance is wrong at completion");
        STAssertEqualsWithAccuracy([[gps math] currentSpeed], 1.3f, 0.1f, @"Current speed is wrong at completion");
        STAssertEqualsWithAccuracy([[gps math] averageSpeed], 460.0f / 485.0f, 0.1f, @"Average speed is wrong at completion");
        
        // Check that we got four lap times, one for each 100m
        NSArray *laptimes = [gps queuedLapTimes];
        intres = [laptimes count];
        STAssertEquals(intres, 4, @"Number of lap times incorrect");
        for (int i = 1; i <= 4; i++) {
                LapTime *lt = [laptimes objectAtIndex:i-1];
                STAssertEquals(lt.distance, i*100.0f, @"Lap length incorrect");
                STAssertEqualsWithAccuracy(lt.elapsedTime, 110.0f, 26.0f, @"Lap time incorrect");
        }

        // Check that we don't get the laps again
        laptimes = [gps queuedLapTimes];
        intres = [laptimes count];
        STAssertEquals(intres, 0, @"Number of lap times incorrect second time");
}

- (void)test_b_Race {
        // Fetch the application delegate
        GlintAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        STAssertNotNil(appDelegate, @"Cannot find the application delegate.");
        
        GPSManager *gps = [appDelegate gpsManager];
        [gps clearForUnitTests];

        // Read a reference file with positions
        NSString* refFile = [NSString stringWithFormat:@"%@/reference1.gpx", [[NSBundle mainBundle] bundlePath]];
        JBGPXReader *reader = [[JBGPXReader alloc] initWithFilename:refFile];
        NSArray *locations = [[reader locations] retain];
        [reader release];
        int intres = [locations count];
        STAssertEquals(intres, 155, @"Locations count is wrong");

        // Register the reference as what we race against
        [[gps math] setRaceLocations:locations]; 

        // Read a reference file with positions
        refFile = [NSString stringWithFormat:@"%@/reference2.gpx", [[NSBundle mainBundle] bundlePath]];
        reader = [[JBGPXReader alloc] initWithFilename:refFile];
        locations = [[reader locations] retain];
        [reader release];
        intres = [locations count];
        STAssertEquals(intres, 157, @"Locations count is wrong");
        
        // Walk the track forwards
        CLLocation *prevLoc = nil;
        for (int i = 0; i < 90; i++) {
                CLLocation *loc = [locations objectAtIndex:i];
                [gps locationManager:nil didUpdateToLocation:loc fromLocation:prevLoc];
                prevLoc = loc;
        }
        
        STAssertEqualsWithAccuracy([[gps math] distDifferenceInRace], 28.0f, 1.0f, @"Distance difference wrong");
        STAssertEqualsWithAccuracy([[gps math] timeDifferenceInRace], -16.0f, 1.0f, @"Time difference wrong");
        
        // Walk a little more
        for (int i = 90; i < 120; i++) {
                CLLocation *loc = [locations objectAtIndex:i];
                [gps locationManager:nil didUpdateToLocation:loc fromLocation:prevLoc];
                prevLoc = loc;
        }
        
        STAssertEqualsWithAccuracy([[gps math] distDifferenceInRace], -13.0f, 1.0f, @"Distance difference wrong");
        STAssertEqualsWithAccuracy([[gps math] timeDifferenceInRace], 4.0f, 1.0f, @"Time difference wrong");
        
        // Finish the walk
        for (int i = 120; i < 157; i++) {
                CLLocation *loc = [locations objectAtIndex:i];
                [gps locationManager:nil didUpdateToLocation:loc fromLocation:prevLoc];
                prevLoc = loc;
        }

        STAssertEqualsWithAccuracy([[gps math] distDifferenceInRace], 10.0f, 1.0f, @"Distance difference wrong");
        STAssertEqualsWithAccuracy([[gps math] timeDifferenceInRace], -6.0f, 1.0f, @"Time difference wrong");
}

- (void)test_x1_StartStopRecording {
        // Fetch the application delegate
        GlintAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        STAssertNotNil(appDelegate, @"Cannot find the application delegate.");
        
        STAssertFalse([[appDelegate gpsManager] isRecording], @"GPSManager.isRecording is wrong at start");
        [[appDelegate mainScreenViewController] startStopRecording:nil];
        STAssertTrue([[appDelegate gpsManager] isRecording], @"GPSManager.isRecording is wrong after start");
        [[appDelegate mainScreenViewController] startStopRecording:nil];
        STAssertFalse([[appDelegate gpsManager] isRecording], @"GPSManager.isRecording is wrong after stop");
}

@end
