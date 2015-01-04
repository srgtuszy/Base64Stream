//
//  ImageTest.m
//  Base64Stream
//
//  Created by Michał Tuszyński on 03/01/15.
//  Copyright (c) 2015 iapp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MTBase64InputStream.h"

@interface ImageTest : XCTestCase

@end

@implementation ImageTest

- (void)testImageEncoding {
    NSUInteger bufferSize = 684;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSArray *inputImages = [NSArray arrayWithContentsOfFile:[bundle pathForResource:@"InputImages" ofType:@"plist"]];
    NSURL *tempURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"test_image"]];
    for (NSDictionary *imageMetadata in inputImages) {
        NSURL *imageURL = [bundle URLForResource:imageMetadata[@"name"]
                                   withExtension:imageMetadata[@"extension"]];
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
        [imageData writeToURL:tempURL
                   atomically:YES];
        NSAssert(imageURL, @"Couldn't find image with name: %@", imageMetadata[@"name"]);
        NSString *expectedBase64 = [self nativeBase64FromImageAtURL:imageURL];
        NSInputStream *inputStream = [[MTBase64InputStream alloc] initWithURL:tempURL];
        [inputStream open];
        uint8_t *buffer = malloc(bufferSize * sizeof(uint8_t));
        NSMutableData *outputData = [NSMutableData data];
        NSLog(@"Encoding %@", imageMetadata);
        while ([inputStream hasBytesAvailable]) {
            NSInteger bytesRead = [inputStream read:buffer maxLength:513];
            [outputData appendBytes:buffer length:bytesRead];
         }
        NSLog(@"Done!");
        [inputStream close];
        free(buffer);
        NSString *outBase64 = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects(outBase64, expectedBase64, @"Invalid image base64, expected:\n%@\n\ngot:\n%@",
                expectedBase64, outBase64);
        [fileManager removeItemAtURL:tempURL error:nil];
    }
}

- (NSString *)nativeBase64FromImageAtURL:(NSURL *)url {
    NSData *imageData = [NSData dataWithContentsOfURL:url];
    NSData *base64Data = [imageData base64EncodedDataWithOptions:0];
    return [[NSString alloc] initWithData:base64Data encoding:NSUTF8StringEncoding];
}

@end