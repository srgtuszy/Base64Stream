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

#import "MTBase64InputStream.h"

static const NSUInteger kDefaultBufferLength = 684;
static const NSUInteger kDefaultLength = 513;
static const NSInteger kPaddingTable[3] = {0, 2, 1};
static const char *kBase64Table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

@interface MTBase64InputStream()

@property (assign, nonatomic) MTBase64InputStreamState state;
@property (strong, nonatomic) NSString *filePath;
@property (strong, nonatomic) NSFileHandle *fileHandle;
@property (assign, nonatomic) NSUInteger inputBytes;
@property (assign, nonatomic) NSUInteger index;
@property (assign, nonatomic) NSInteger padding;
@property (unsafe_unretained, nonatomic) unsigned char *temporaryBuffer;

@end

@implementation MTBase64InputStream

#pragma mark - Init & teardown

- (instancetype)initWithFileAtPath:(NSString *)path {
    self = [super initWithFileAtPath:path];
    if (self) {
        _state = MTBase64InputStreamStateClosed;
        _filePath = path;
    }

    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
//NSInputStream doesn't implement that initializer, it's been defined
//in a category, therefore, we call NSObject's initializer here and ignore
//xcode warning
- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        NSAssert([url isFileURL], @"Expecting a file url here");
        _state = MTBase64InputStreamStateClosed;
        _filePath = [url path];
    }
    return self;
}

#pragma clang diagnostic pop

- (void)dealloc {
    //Just in case client forgot to close the stream after using
    if (_state == MTBase64InputStreamStateOpen) [self close];
}

#pragma mark - NSInputStream

- (void)open {
    NSAssert(self.state == MTBase64InputStreamStateClosed, @"Cannot open already opened stream");
    NSAssert(self.filePath, @"No file path specified");
    if (self.state == MTBase64InputStreamStateOpen) return;
    NSError *error;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath
                                                                                error:&error];
    if (error) {
        NSString *reason = [NSString stringWithFormat:@"Cannot read attributes of provided file: %@", error];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
    }
    self.index = 0;
    self.temporaryBuffer = malloc(3 * sizeof(unsigned char));
    self.inputBytes = [attributes[NSFileSize] unsignedIntegerValue];
    self.fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.filePath];
    self.padding = kPaddingTable[self.inputBytes % 3];
    self.state = MTBase64InputStreamStateOpen;
}

- (void)close {
    NSAssert(self.state == MTBase64InputStreamStateOpen, @"Cannot close already closed stream");
    if (self.state == MTBase64InputStreamStateClosed) return;
    [self.fileHandle closeFile];
    if (self.temporaryBuffer) free(self.temporaryBuffer);
    self.inputBytes = 0;
    self.state = MTBase64InputStreamStateClosed;
}

- (BOOL)hasBytesAvailable {
    return (self.state == MTBase64InputStreamStateOpen && (self.index < self.inputBytes + self.padding));
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    NSAssert(self.state == MTBase64InputStreamStateOpen, @"Cannot read from a closed stream");
    NSAssert(sizeof(buffer) / sizeof(uint8_t) % 4 == 0, @"Buffer size not dividable by 4");
    NSAssert(len % 3 == 0, @"Max length must be divisable by 3");
    if (self.state == MTBase64InputStreamStateClosed) return -1;
    [self.fileHandle seekToFileOffset:self.index];
    NSData *data = [self.fileHandle readDataOfLength:len];
    NSUInteger bytesRead = data.length;
    NSInteger bytesToRead = 0;
    NSUInteger bufferIndex = 0;
    NSUInteger stop = self.index + bytesRead;
    NSUInteger dataIndex = 0;
    while (self.index < stop) {
        bytesToRead = MIN(3, stop - self.index); //Either 3 or remaining bytes
        [data getBytes:self.temporaryBuffer range:NSMakeRange(dataIndex, bytesToRead)];
        dataIndex += bytesToRead;
        unsigned char byte1 = self.temporaryBuffer[0], byte2 = self.temporaryBuffer[1], byte3 = self.temporaryBuffer[2];
        if (bytesToRead == 3) {
            buffer[bufferIndex]       = (uint8_t) kBase64Table[(byte1 >> 2) & 0x3F];
            buffer[bufferIndex + 1]   = (uint8_t) kBase64Table[((byte1 << 4) & 0x30) | ((byte2 >> 4) & 0x0F)];
            buffer[bufferIndex + 2]   = (uint8_t) kBase64Table[((byte2 << 2 & 0x3C)) | ((byte3 >> 6) & 0x03)];
            buffer[bufferIndex + 3]   = (uint8_t) kBase64Table[byte3 & 0x3F];
            bufferIndex += 4;
        } else {
            switch (bytesToRead) {
                case 2:
                    buffer[bufferIndex]       = (uint8_t) kBase64Table[(byte1 >> 2) & 0x3F];
                    buffer[bufferIndex + 1]   = (uint8_t) kBase64Table[((byte1 << 4) & 0x30) | ((byte2 >> 4) & 0x0F)];
                    buffer[bufferIndex + 2]   = (uint8_t) kBase64Table[(byte2 << 2) & 0x3C];
                    bufferIndex += 3;
                    break;
                case 1:
                    byte2 = 0;
                    buffer[bufferIndex]       = (uint8_t) kBase64Table[(byte1 >> 2) & 0x3F];
                    buffer[bufferIndex + 1]   = (uint8_t) kBase64Table[((byte1 << 4) & 0x30) | ((byte2 >> 4) & 0x0F)];
                    bufferIndex += 2;
                    break;
            }
        }
        self.index += bytesToRead;
        if (self.index >= self.inputBytes) {
            for (NSInteger j = 0; j < self.padding; j++) {
                buffer[bufferIndex] = '=';
                bufferIndex++;
            }
            self.index += self.padding;
        }
    }
    return bufferIndex;
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len {
    *len = kDefaultLength;
    *buffer = malloc(kDefaultBufferLength * sizeof(uint8_t));
    return YES;
}

@end
