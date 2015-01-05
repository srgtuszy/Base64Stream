// Copyright 2015 Michał Tuszyński
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MTBase64InputStream.h"

@interface StringTest : XCTestCase

@property (strong, nonatomic) NSArray *testData;

@end

@implementation StringTest

#pragma mark - XCTest

- (void)setUp {
    [super setUp];
    NSString *testDataPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"InputStrings"
                                                                              ofType:@"plist"];
    self.testData = [NSArray arrayWithContentsOfFile:testDataPath];
}

#pragma mark - Tests

- (void)testEncodingStringsFromUrl {
    NSUInteger bufferSize = 513;
    NSInteger index = 0;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"test_file"]];
    for (NSDictionary *testCase in self.testData) {
        [testCase[@"input"] writeToFile:[url path]
                             atomically:YES
                               encoding:NSUTF8StringEncoding
                                  error:nil];
        NSMutableData *outputData = [NSMutableData data];
        uint8_t *buffer = malloc(bufferSize * sizeof(uint8_t));
        NSInputStream *inputStream = [[MTBase64InputStream alloc] initWithURL:url];
        [inputStream open];
        while ([inputStream hasBytesAvailable]) {
            NSInteger bytesRead = [inputStream read:buffer maxLength:bufferSize];
            [outputData appendBytes:buffer length:(NSUInteger) bytesRead];
        }
        [inputStream close];
        free(buffer);
        NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects(output, testCase[@"output"], @"Test case mismatch at %ld, got: %@", (long)index, output);
        index++;
        [fileManager removeItemAtURL:url error:nil];
    }

}

@end
