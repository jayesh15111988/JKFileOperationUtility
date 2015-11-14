//
//  NSString+DecodeString.m
//  Pods
//
//  Created by Jayesh Kawli Backup on 11/11/15.
//
//

#import "NSString+DecodeString.h"

@implementation NSString (DecodeString)

- (NSString*)decodeString {
    return (__bridge NSString *) CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                         (__bridge CFStringRef) self,
                                                                                         CFSTR(""),
                                                                                         kCFStringEncodingUTF8);
}

@end
