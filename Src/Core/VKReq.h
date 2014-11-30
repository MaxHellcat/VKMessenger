//
//  VKReq.h
//  net
//
//  Created by Max on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// Enrich NSString url encoding functionality
@interface NSString (URLEncoding)
-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding;
@end

// Ability to create MD5 hashes
@interface NSString (MD5)
- (NSString *)MD5;
@end

// Ability to decode misc. entities back to symbols
@interface NSString (decodingEntities)
- (NSString *)stringByDecodingXMLEntities;
@end

@interface UIImage (Resize)
- (UIImage*)scaleToSize:(CGSize)size;
@end


// Minimalistic class to talk to VK API server, asynchronously
// Automatically constructs MD5-based HTTP urls and encodes params as appropriate
@interface VKReq : NSObject <NSURLConnectionDelegate>

// Properties
@property (strong, nonatomic) NSURLConnection * connection;
@property (strong, nonatomic) id target;
@property (strong, nonatomic, readonly) NSMutableData * responseData;
@property (nonatomic) SEL didGetResponseSelector;
@property (nonatomic) SEL didFailSelector;

// Methods
+ (void)getMethod:(NSString *)method withParams:(NSString *)params target:(id)target action:(SEL)action fail:(SEL)actionFail;
- (void)getMethod:(NSString *)method withParams:(NSString *)params target:(id)target action:(SEL)action fail:(SEL)actionFail;


+ (void)execute:(NSString *)code target:(id)target action:(SEL)action fail:(SEL)actionFail;
+ (void)messageSend:(NSString *)text toUid:(NSInteger)uid target:(id)target action:(SEL)action;

// Don't like va_list thingy
+ (void)method:(NSString *)method
	  paramOne:(NSString *)paramOne valueOne:(NSString *)valueOne
		target:(id)target action:(SEL)action fail:(SEL)actionFail;

+ (void)method:(NSString *)method
	  paramOne:(NSString *)paramOne valueOne:(NSString *)valueOne
	  paramTwo:(NSString *)paramTwo valueTwo:(NSString *)valueTwo
		target:(id)target action:(SEL)action fail:(SEL)actionFail;

+ (void)method:(NSString *)method
	  paramOne:(NSString *)paramOne valueOne:(NSString *)valueOne
	  paramTwo:(NSString *)paramTwo valueTwo:(NSString *)valueTwo
	  paramThree:(NSString *)paramThree valueThree:(NSString *)valueThree
		target:(id)target action:(SEL)action fail:(SEL)actionFail;


+ (void)postPhoto:(NSString *)url withImage:(UIImage *)image target:(id)target action:(SEL)action fail:(SEL)actionFail;


+ (void)authWithLogin:(NSString *)login password:(NSString *)password target:(id)target action:(SEL)action;

- (id)initWithTarget:(id)target action:(SEL)action fail:(SEL)actionFail;
- (void)get:(NSString *)url;
- (void)post:(NSString *)url;

@end
