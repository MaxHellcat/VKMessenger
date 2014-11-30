//
//  Constants.h
//  VKM
//
//  Created by Max on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

// TODO: Should this be not safe-guarded?

extern NSString * const kPrefixHttp;
extern NSString * const kPrefixHttps;
extern NSString * const kVKApiHost;

extern NSString * const kClientId;
extern NSString * const kClientSecret;
extern NSString * const kScope;

// All possible attachment types for message
typedef enum { eAttachmentMissing=-1, eAttachmentTypePhoto=0, eAttachmentTypeAudio, eAttachmentTypeVideo, eAttachmentTypeGeo } AttachmentType;

@interface Misc : NSObject
+ (BOOL)retina;
@end


@interface NSDate (HumanizedTime)

// Formats the date with 'h:mm a' or the localized equivalent.
- (NSString*)formatTime;

/**
 * Formats the date according to how old it is.
 *
 * For dates less than a day old, the format is 'h:mm a', for less than a week old the
 * format is 'EEEE', and for anything older the format is 'M/d/yy'.
 */
- (NSString *)formatShortTime;

// Pull to refresh specific
- (NSString *) stringWithHumanizedTimeDifference;

@end
