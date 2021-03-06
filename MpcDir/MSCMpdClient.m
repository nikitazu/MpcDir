//
//  MSCMpdClient.m
//  MpcDir
//
//  Created by Никита Б. Зуев on 29.10.12.
//  Copyright (c) 2012 Никита Б. Зуев. All rights reserved.
//

#import "MSCMpdClient.h"

NSString *const MSC_MPD_FORMAT = @"%position%@@@%artist%@@@%title%@@@%album%@@@%file%";

@implementation MSCMpdClient

@synthesize preferences;

// Constructors
// =============

+ (id) mpd: (MSCPreferences*)prefs
{
    MSCMpdClient* client = [[MSCMpdClient alloc] init];
    if (client == nil) {
        return nil;
    }
    
    client.preferences = prefs;
    return client;
}

// Playlist management
// ===================

- (void) add: (NSString*)path {
    [self mpcrun: @"add", path, nil];
}

- (void) clear {
    [self mpcrun: @"clear", nil];
}

// Status detection
// ================

- (MSCStatus*) status {
    return [MSCStatus statusWithArray:
            [self mpcquery:@"status", @"--format", MSC_MPD_FORMAT, nil]];
}

- (NSString*) current {
    return [self mpcrun: @"current", @"--format", MSC_MPD_FORMAT, nil];
}

- (BOOL) test {
    NSTask* task = [[NSTask alloc] init];
    NSPipe* tout = [NSPipe pipe];
    
    NSLog(@"testing connection to %@", preferences.host);
    
    [task setLaunchPath: @"/sbin/ping"];
    [task setArguments: [NSArray arrayWithObjects:
                         @"-c", @"1", @"-t", @"5", preferences.host, nil]];
    
    [task setStandardOutput: tout];
    [task launch];
    
    [task waitUntilExit];
    
    NSLog(@"connection status is: %d", task.terminationStatus);
    
    if (task.terminationStatus == 0) {
        return YES;
    } else {
        return NO;
    }
}

// Playback control
// ================

- (void) play: (NSString*)position {
    [self mpcrun: @"play", position, nil];
}

- (void) stop {
    [self mpcrun: @"stop", nil];
}

- (void) pause {
    [self mpcrun: @"pause", nil];
}

- (void) toggle {
    [self mpcrun: @"toggle", nil];
}

- (void) next {
    [self mpcrun: @"next", nil];
}

- (void) previous {
    [self mpcrun: @"prev", nil];
}

// Listings
// ========

- (NSArray*) ls:(MSCDir*)dir {
    return [self mpcdo: ^(id path) { return [MSCDir dirWithPath:path]; }
              withArgs: @"ls", [dir path], nil];
}

- (NSArray*) listall:(MSCDir*)dir {
    return [self mpcdo: ^(id path) { return [MSCDir dirWithPath:path]; }
              withArgs: @"listall", [dir path], nil];
}

- (NSArray*) playlist {
    return [self mpcdo: ^(id data) { return [MSCSong songWithData:data]; }
              withArgs: @"playlist", @"--format", MSC_MPD_FORMAT, nil];
}

// Mode switches
// =============

- (void) random {
    [self mpcrun:@"random", nil];
}

- (void) repeat {
    [self mpcrun:@"repeat", nil];
}

- (void) single {
    [self mpcrun:@"single", nil];
}

- (void) consume {
    [self mpcrun:@"consume", nil];
}

// Helper methods
// ==============


- (NSArray*)mpcdo: (LineBlock)block withArgs: (id)arg, ...
{
    if (arg == nil) {
        return nil;
    }
    
    NSMutableArray* args = [NSMutableArray array];
    
    [args addObject:@"-h"];
    [args addObject:preferences.host];
    
    if (preferences.port) {
        [args addObject:@"-p"];
        [args addObject:preferences.port];
    }
    
    if (preferences.password) {
        [args addObject:@"-P"];
        [args addObject:preferences.password];
    }
    
    [args addObject:arg];
    
    id currentArg;
    va_list argumentList;
    va_start(argumentList, arg);
    while((currentArg = va_arg(argumentList, id))) {
        [args addObject: currentArg];
    }
    va_end(argumentList);
    
    NSTask* task = [[NSTask alloc] init];
    NSPipe* tout = [NSPipe pipe];
    
    //NSLog(@"mpcdo: %@", args);
    
    [task setLaunchPath: preferences.client];
    [task setArguments: args];
    [task setStandardOutput: tout];
    
    [task launch];
    
    NSData*   data  = [[tout fileHandleForReading] readDataToEndOfFile];
    NSString* str   = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray* result = [str componentsSeparatedByString:@"\n"];
    NSArray* finalResult = [result map: block];
//    finalResult = [finalResult sliceAt:0 ofLength:[finalResult count] - 1];
    
    [task waitUntilExit];
    
    return finalResult;
}

- (NSArray*)mpcquery:(id)arg, ...
{
    if (arg == nil) {
        return nil;
    }
    
    NSMutableArray* args = [NSMutableArray array];
    
    [args addObject:@"-h"];
    [args addObject:preferences.host];
    
    if (preferences.port) {
        [args addObject:@"-p"];
        [args addObject:preferences.port];
    }
    
    if (preferences.password) {
        [args addObject:@"-P"];
        [args addObject:preferences.password];
    }
    
    [args addObject:arg];
    
    id currentArg;
    va_list argumentList;
    va_start(argumentList, arg);
    while((currentArg = va_arg(argumentList, id))) {
        [args addObject: currentArg];
    }
    va_end(argumentList);
    
    NSTask* task = [[NSTask alloc] init];
    NSPipe* tout = [NSPipe pipe];
    
    //NSLog(@"mpcquery: %@", args);
    
    [task setLaunchPath: preferences.client];
    [task setArguments: args];
    [task setStandardOutput: tout];
    
    [task launch];
    
    NSData*   data  = [[tout fileHandleForReading] readDataToEndOfFile];
    NSString* str   = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray* result = [str componentsSeparatedByString:@"\n"];
    
    [task waitUntilExit];
    
    return result;
}

- (NSString*)mpcrun:(id)arg, ...
{
    if (arg == nil) {
        return nil;
    }
    
    NSMutableArray* args = [NSMutableArray array];
    
    [args addObject:@"-h"];
    [args addObject:preferences.host];
    
    if (preferences.port) {
        [args addObject:@"-p"];
        [args addObject:preferences.port];
    }
    
    if (preferences.password) {
        [args addObject:@"-P"];
        [args addObject:preferences.password];
    }
    
    [args addObject:arg];
    
    id currentArg;
    va_list argumentList;
    va_start(argumentList, arg);
    while((currentArg = va_arg(argumentList, id))) {
        [args addObject: currentArg];
    }
    va_end(argumentList);
    
    NSTask* task = [[NSTask alloc] init];
    NSPipe* tout = [NSPipe pipe];
    
    //NSLog(@"mpcrun: %@", args);
    
    [task setLaunchPath: preferences.client];
    [task setArguments: args];
    [task setStandardOutput: tout];
    
    [task launch];
        
    NSData*   data = [[tout fileHandleForReading] readDataToEndOfFile];
    NSString* str  = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [task waitUntilExit];
    
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
