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

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MTBase64InputStreamState) {
    MTBase64InputStreamStateClosed = 0,
    MTBase64InputStreamStateOpen
};

@interface MTBase64InputStream : NSInputStream

/**
 Creates a closed input stream with from a url which points to a file present
 on the local file system
 @param url a file url which points to an existing file
 @return NSInputStream instance
 */
- (instancetype)initWithURL:(NSURL *)url;

/**
 Creates a closed input stream with from a path which points to a file present
 on the local file system
 @param path absolute path to an existing file
 @return NSInputStream instance
 */
- (instancetype)initWithFileAtPath:(NSString *)path;

@property (assign, nonatomic, readonly) MTBase64InputStreamState state;

@end
