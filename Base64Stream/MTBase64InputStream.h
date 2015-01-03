//
//  MTBase64InputStream.h
//  Base64Stream
//
//  Created by Michał Tuszyński on 16/12/14.
//  Copyright (c) 2014 iapp. All rights reserved.
//

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
