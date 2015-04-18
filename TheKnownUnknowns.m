//
//  TheKnownUnknowns.m
//  TheKnownUnknowns
//
//  Created by Halle Winkler on 4/13/15.
//  Copyright (c) 2015 Politepix. All rights reserved.
//

#import "TheKnownUnknowns.h"

@implementation TheKnownUnknowns

#pragma mark - 
#pragma mark Strings
#pragma mark - 

static NSString * const kTermReset                  = @"\x1b[0m";                   // Reset
static NSString * const kTermBold                   = @"\x1b[1m";                   // Bold
static NSString * const kMagentaColor               = @"\x1b[35m";                  // Magenta
static NSString * const kAmbiguousCharactersString  = @"+=$%/&#@¥€£¢";              // Characters that, like with numbers, we maybe need to spell out, maybe need to remove in an interactive loop.
static NSString * const kDeletableCharactersString  = @"()*<>[]_{|}~«»‘’“”¡¿\"";    // Characters which we automatically remove.
static NSString * const kIntrawordCharactersString  = @"-'";                        // Characters that we leave in place if they are intraword, otherwise automatically remove.
static NSString * const kIgnoredCharactersString    = @"!?.,:;";                    // Characters which we do not automatically remove, instead automatically leaving them in place.

#pragma mark - 
#pragma mark Complete processing steps
#pragma mark -

- (void) semiInteractivelyProcessTextInFileAtPath:(NSString *)pathToFileAsString {
        
    NSString *text = [self readInTextWithWhitespaceNormalization:pathToFileAsString]; // Get text with all whitespace normalized. Next we can normalize the characters:
        
    text = [self showUsesOfCharactersInSet:[NSCharacterSet decimalDigitCharacterSet] textArray:[text componentsSeparatedByString:@" "] fixedTextArray:nil index:0 lastPerformedIndex:0 markOnly:FALSE describe:TRUE]; // Step through number cases interactively.

    text = [self showUsesOfCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:kAmbiguousCharactersString] textArray:[text componentsSeparatedByString:@" "] fixedTextArray:nil index:0 lastPerformedIndex:0 markOnly:FALSE describe:TRUE]; // Step through the known ambiguous symbol cases interactively.
    
    text = [[text stringByReplacingOccurrencesOfString:@"‘" withString:@"'"]stringByReplacingOccurrencesOfString:@"’" withString:@"'"]; // Make any smart quotes into straight quotes automatically before handling apostrophes.
    
    text = [[text componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:kDeletableCharactersString]] componentsJoinedByString:@""]; // Automatically remove symbols we know we don't want.
    
    text = [self removeAllButIntrawordOccurrencesOfCharacter:@"-" inText:text]; // Remove dashes/hyphens, unless they are found between two letters.
    
    text = [self removeAllButIntrawordOccurrencesOfCharacter:@"'" inText:text]; // Remove apostrophes, unless they are found between two letters, which we now know will only be in the form of straight quotes.
      
    text = [self showUsesOfCharactersInSet:[[self addressedCharacterSet] invertedSet] textArray:[text componentsSeparatedByString:@" "] fixedTextArray:nil index:0 lastPerformedIndex:0 markOnly:TRUE describe:TRUE]; // Mark any remaining weird symbols that we don't know about at runtime (everything outside the previous-address set), non-interactively.

    [self writeOutTextWithWhitespaceNormalization:text toDuplicateFileNextToOriginalPath:pathToFileAsString]; // Write out results and exit.
}

#pragma mark - 
#pragma mark Write in/out
#pragma mark -

- (NSString *) normalizeWhitespaceInText:(NSString *)text {
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]; 
    NSArray *componentArray = [text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [[componentArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self <> ''"]]componentsJoinedByString:@" "];
}

- (NSString *) readInTextWithWhitespaceNormalization:(NSString *)fileName {
    NSError *error = nil;
#ifdef TESTCONTENT    
    NSString *text = @"\n\n\n\n\nTEATRO GALANTE\n\n\n\n\nEDUARDO ZAMACOIS\n\nTEATRO GALA'NTE\n\nNochebuena.--El pas-ado vuelve.\nFrío.\n\n[imagen no dispon-ible: colofón]\n\nMADRID\nAntonio Garrido, Editor.--Goya, 86\n1910\n\n@Es propie[dad.\n\nQueda hecho el depósito\nque marca la ley.\n\nIMPRENTA ARTÍSTICA ESPAÑOLA. SAN ROQUE, 7.--MADRID\n\n[imagen no disponible]\n\n\n\n";
#else    
    NSString *text = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:&error]; 
#endif    
    if (error) {
        NSLog(@"Error opening file and converting it to a UTF8 NSString: %@", [error localizedDescription]);
        exit(0);
    } else {
        return [self normalizeWhitespaceInText:text];   
    }
}

- (void) writeOutTextWithWhitespaceNormalization:(NSString *)text toDuplicateFileNextToOriginalPath:(NSString *)originalFilepathAsString {
#ifdef TESTCONTENT    
    NSLog(@"Final result:\n%@", text);
#else    
    
    NSError *error = nil;
    BOOL writeoutSuccess = [[self normalizeWhitespaceInText:text] writeToFile:[originalFilepathAsString stringByAppendingString:@".fixed"] atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if(!writeoutSuccess) {
        NSLog(@"Error writing out final text file: %@", [error localizedDescription]);
        exit(0);
    }
#endif
}

#pragma mark - 
#pragma mark Interactive loops
#pragma mark -

- (void) getInputForUnknownWithCharacterSet:(NSCharacterSet *)characterSet textArray:(NSArray *)textArray fixedTextArray:(NSMutableArray *)fixedTextArray index:(NSInteger *)index lastPerformedIndex:(NSInteger*)lastPerformedIndex {
    
    NSFileHandle *input = [NSFileHandle fileHandleWithStandardInput]; // Getting the user input for the interactive cases
    NSData *inputData = [input availableData];
    NSString *inputString = [[NSString alloc] initWithData: inputData encoding:NSUTF8StringEncoding];

    if([inputString isEqualToString:@"\n"] || [inputString isEqualToString:@"\r"]) { // If it consists _only_ of a newline, handle and return.
        NSLog(@"input was just the enter key, leaving item as it is.");
        *lastPerformedIndex = *index; // We don't store a change until we're past the point that the user is allowed to go back and edit it.
        [fixedTextArray addObject:[textArray objectAtIndex:*index]];
        *index = *index + 1; // These are passed by reference because this is a subroutine of a greater recursive routine that is responsible for keeping track of its own indices.
        return;
    }
    
    // Otherwise:
    
    inputString = [inputString stringByTrimmingCharactersInSet: [NSCharacterSet newlineCharacterSet]]; // Check everything else without newline characters.

    if([inputString isEqualToString:@"\\"]) { // If they backslash, that means they want to go back and edit the previous entry.
        NSLog(@"input was backslash, repeating.");
        *index = *lastPerformedIndex; // So we set the current index to the last performed index -- basically rolling back to the previous step.
        NSRange range = {*index, [fixedTextArray count] - *index};
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
        [fixedTextArray removeObjectsAtIndexes:indexSet]; // We are removing this and the previous entries in the fixed array before moving onward (which will actually be backwards).
    } else if([inputString isEqualToString:@"`"]) { // If they backtick, that means they want to just mark the entry for later perusal.
        NSLog(@"input was %@, marking and continuing.", inputString);
        *lastPerformedIndex = *index;
        [fixedTextArray addObject:[NSString stringWithFormat:@"[[[%@]]]",[textArray objectAtIndex:*index]]];
        *index = *index + 1; // So we can continue after surrounding the entry with square brackets.
    } else {
        NSLog(@"input was %@, continuing.", inputString); // Otherwise they have entered some content and the shown content should be replaced with it,
        *lastPerformedIndex = *index;
        [fixedTextArray addObject:inputString];
        *index = *index + 1; // And we can increment forward.
    }
}

- (NSString *) wordIfExists:(NSInteger)offset inTextArray:(NSArray *)textArray usingIndex:(NSInteger)index { // To show words in context, we need to know they exist.
    
    if(index + offset < [textArray count]) {
        return [textArray objectAtIndex:index + offset];
    }
    return @""; // Return some string if there isn't a real string here so we can form the context sentence.
}


- (NSString *) showUsesOfCharactersInSet:(NSCharacterSet *)characterSet textArray:(NSArray *)textArray fixedTextArray:(NSMutableArray *)fixedTextArray index:(NSInteger)index lastPerformedIndex:(NSInteger)lastPerformedIndex markOnly:(BOOL)markOnly describe:(BOOL)describe {
    
    if([textArray count] == 0) { // This is bad (is it possible?), complain and stop.
        NSLog(@"Text has no content, stopping.");
        exit(0);
    }
    
    if(fixedTextArray == nil) {
        fixedTextArray = [NSMutableArray new]; // First recursion, create the mutable array.
    }
        
    NSString *word = [textArray objectAtIndex:index];
    
    if(describe) {
        if(markOnly) {
            NSLog(@"Marking any incidences of unknown symbols.");   
        } else {
            NSLog(@"Fixing numbers or symbols. For each sentence, type a replacement for the highlighted number and enter, or type a single backslash and enter to repeat the previous edit or marking, or type a single backtick to mark the word for later perusal by enclosing it in [[[]]] to make it easy for you to find later, or just type return or enter in order to leave it alone and progress to the next item.");
        }
    }
    
    NSRange r = [word rangeOfCharacterFromSet:characterSet];
    if (r.location != NSNotFound) {
        if(markOnly) {
            [fixedTextArray addObject:[NSString stringWithFormat:@"[[[%@]]]", word]];
            index++;
        } else {
            NSLog(@"\"%@ %@ %@ %@%@%@%@ %@ %@ %@\"", 
                  [self wordIfExists:-3 inTextArray:textArray usingIndex:index],
                  [self wordIfExists:-2 inTextArray:textArray usingIndex:index],
                  [self wordIfExists:-1 inTextArray:textArray usingIndex:index],
                  kTermBold,
                  kMagentaColor,
                  word,
                  kTermReset,
                  [self wordIfExists:+1 inTextArray:textArray usingIndex:index],
                  [self wordIfExists:+2 inTextArray:textArray usingIndex:index],
                  [self wordIfExists:+3 inTextArray:textArray usingIndex:index]              
                  );
            
            [self getInputForUnknownWithCharacterSet:characterSet textArray:textArray fixedTextArray:fixedTextArray index:&index lastPerformedIndex:&lastPerformedIndex];            
        }
    } else {
        [fixedTextArray addObject:word];
        index++;
    }
    
    if(index < [textArray count]) {
        return [self showUsesOfCharactersInSet:characterSet textArray:textArray fixedTextArray:fixedTextArray index:index lastPerformedIndex:lastPerformedIndex markOnly:markOnly describe:FALSE];
    }

    return [fixedTextArray componentsJoinedByString:@" "];
}

#pragma mark - 
#pragma mark Intraword character processing
#pragma mark -

- (NSString *) removeAllButIntrawordOccurrencesOfCharacter:(NSString *)character inText:(NSString *)text {
    
    NSArray *textArray = [text componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:character]]; // Separate segments around this character
    
    NSMutableArray *mutableTextArray = [NSMutableArray new]; // Store processed segments
    
    for(NSString *segment in textArray) {
        
        NSString *nextSegment = nil;
        
        if(([textArray indexOfObject:segment] + 1) < [textArray count]) { // If there is a next segment, store it, otherwise fake next segment.
            nextSegment = [textArray objectAtIndex:[textArray indexOfObject:segment] + 1];
        } else {
            nextSegment = @"";
        }
        
        if( // If there's a character at the end of this segment and a character at the start of the next segment and they're both letters we found an intraword character.
           [segment length] > 0 
           && 
           [nextSegment length] > 0
           &&
           ![segment isEqualTo:[textArray lastObject]] 
           && 
           [[segment substringFromIndex:[segment length] - 1] rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location != NSNotFound 
           && 
           [[nextSegment substringFromIndex:0] rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location != NSNotFound
           ) {
            [mutableTextArray addObject:[NSString stringWithFormat:@"%@%@",segment,character]]; // This is an intraword character, so add it to the end of the segment so it remains when we reassemble.
        } else {
            [mutableTextArray addObject:segment]; // If there isn't a word with a letter in front and in back, it isn't intraword, just add it back with the special character still absent.
        }
    }
    
    return [mutableTextArray componentsJoinedByString:@""]; // Rejoin everything without the special character (other than the ones we added when they were intraword).
}

#pragma mark - 
#pragma mark Complete NSCharacterSet
#pragma mark -

- (NSCharacterSet *)addressedCharacterSet { // Returns the entire addressed character set in this program
    NSMutableCharacterSet *addressedCharactersCharacterSet = [NSMutableCharacterSet alphanumericCharacterSet];
    [addressedCharactersCharacterSet addCharactersInString:[NSString stringWithFormat:@"%@%@%@%@", kAmbiguousCharactersString, kDeletableCharactersString, kIntrawordCharactersString,kIgnoredCharactersString]];
    return (NSCharacterSet *)addressedCharactersCharacterSet;
}

@end
