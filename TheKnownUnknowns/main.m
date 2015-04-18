//
//  main.m
//  TheKnownUnknowns
//
//  Created by Halle Winkler on 4/10/15.
//  Copyright (c) 2015 Politepix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TheKnownUnknowns.h"

TheKnownUnknowns * theKnownUnknowns;

int main(int argc, const char * argv[]) {

    @autoreleasepool {
        
        theKnownUnknowns = [[TheKnownUnknowns alloc] init];
        
        NSString *filePathAsString = [NSString stringWithFormat:@"%s",argv[1]];

#ifdef TESTCONTENT
        NSLog(@"Using test content.");
#else        
        
        NSFileManager *fileManager = [[NSFileManager alloc]init];
        
        if(argc < 2 || argc > 2 || ![fileManager fileExistsAtPath:filePathAsString]) {
            NSLog(@"Sorry, TheKnownUnknowns must be run with exacly one argument which is the file location of a UTF8 text file which exists. Example: \"~/Applications/TheKnownUnknowns ~/Desktop/MyTextFile.txt\"");
            return -1;   
        }
        
 #endif       
    
        [theKnownUnknowns semiInteractivelyProcessTextInFileAtPath:filePathAsString];
        
    }
    
    return 0;
}
