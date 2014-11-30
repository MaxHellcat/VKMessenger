//
//  VKReq.m
//  net
//
//  Created by Max on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKReq.h"
#import "AppDelegate.h"
#import <CommonCrypto/CommonDigest.h> // For md5
#import "Constants.h"


@implementation VKReq

@synthesize connection=_connection;
@synthesize target=_target;
@synthesize responseData=_responseData;
@synthesize didGetResponseSelector;
@synthesize didFailSelector;


// TODO: Enhance to use method: param in body
+ (void)execute:(NSString *)code target:(id)target action:(SEL)action fail:(SEL)actionFail
{
	AppDelegate * appDel = [[UIApplication sharedApplication] delegate];

	// Don't encode url for MD5 calculation
	NSString * urlMD5 = [NSString stringWithFormat:@"/method/execute?code=%@&access_token=%@", code, [appDel udAccessToken]];
	NSString * strMD5 = [NSString stringWithFormat:@"%@%@", urlMD5, [appDel udSecret]];

	// But encode before sending req to the server
	NSString * url = [NSString stringWithFormat:@"/method/execute?code=%@&access_token=%@",
					  [code urlEncodeUsingEncoding:NSUTF8StringEncoding],
					  [appDel udAccessToken]];

	NSString * finalUrl = [NSString stringWithFormat:@"%@%@%@&sig=%@", kPrefixHttp, kVKApiHost, url, [strMD5 MD5]];

	[[[VKReq alloc] initWithTarget:target action:action fail:actionFail] get:finalUrl];
}

// TODO: Deprecated, don't use, replace with universal method: params
+ (void)getMethod:(NSString *)method withParams:(NSString *)params target:(id)target action:(SEL)action fail:(SEL)actionFail
{
	AppDelegate * appDel = [[UIApplication sharedApplication] delegate];
	NSString * finalUrl = nil;

	if (appDel.udAccessToken)
	{
		// App already authorized for this user, can do MD5 reqs (we asked for nohttps)
		NSString * url = (params)?[NSString stringWithFormat:@"/method/%@?%@&access_token=%@", method, params, [appDel udAccessToken]]:
									[NSString stringWithFormat:@"/method/%@?access_token=%@", method, [appDel udAccessToken]];

		NSString * strMD5 = [NSString stringWithFormat:@"%@%@", url, [appDel udSecret]];

//		// NSLog(@"String for MD5: %@", strMD5);

		finalUrl = [NSString stringWithFormat:@"%@%@%@&sig=%@", kPrefixHttp, kVKApiHost, url, [strMD5 MD5]];
	}
	else
	{
		// App not authorized, only HTTPS reqs allowed in a limited range
		finalUrl = [NSString stringWithFormat:@"%@%@/method/%@?%@", kPrefixHttps, kVKApiHost, method, params];
	}

	[[[VKReq alloc] initWithTarget:target action:action fail:actionFail] get:finalUrl];
}


+ (void)method:(NSString *)method
	  paramOne:(NSString *)paramOne valueOne:(NSString *)valueOne
		target:(id)target action:(SEL)action fail:(SEL)actionFail
{
	AppDelegate * appDel = [[UIApplication sharedApplication] delegate];

	// Don't encode url for MD5 calculation
	NSString * urlMD5, * strMD5, * url;
	
	urlMD5 = [NSString stringWithFormat:@"/method/%@?%@=%@&access_token=%@", method,
			  paramOne, valueOne,
			  [appDel udAccessToken]];

	strMD5 = [NSString stringWithFormat:@"%@%@", urlMD5, [appDel udSecret]];
	
	url = [NSString stringWithFormat:@"/method/%@?%@=%@&access_token=%@",
		   method,
		   paramOne, [valueOne urlEncodeUsingEncoding:NSUTF8StringEncoding],
		   [appDel udAccessToken]];

	NSString * finalUrl = [NSString stringWithFormat:@"%@%@%@&sig=%@", kPrefixHttp, kVKApiHost, url, [strMD5 MD5]];

	[[[VKReq alloc] initWithTarget:target action:action fail:actionFail] get:finalUrl];
}

+ (void)method:(NSString *)method
	  paramOne:(NSString *)paramOne valueOne:(NSString *)valueOne
	  paramTwo:(NSString *)paramTwo valueTwo:(NSString *)valueTwo
		target:(id)target action:(SEL)action fail:(SEL)actionFail
{
	[VKReq method:method
		 paramOne:paramOne valueOne:valueOne
		 paramTwo:paramTwo valueTwo:valueTwo
	   paramThree:nil valueThree:nil target:target action:action fail:actionFail];
}

+ (void)method:(NSString *)method
	  paramOne:(NSString *)paramOne valueOne:(NSString *)valueOne
	  paramTwo:(NSString *)paramTwo valueTwo:(NSString *)valueTwo
	paramThree:(NSString *)paramThree valueThree:(NSString *)valueThree
		target:(id)target action:(SEL)action fail:(SEL)actionFail
{
	AppDelegate * appDel = [[UIApplication sharedApplication] delegate];

	// Don't encode url for MD5 calculation
	NSString * urlMD5, * strMD5, * url;
	if (paramThree)
	{
		urlMD5 = [NSString stringWithFormat:@"/method/%@?%@=%@&%@=%@&%@=%@&access_token=%@", method,
				  paramOne, valueOne,
				  paramTwo, valueTwo,
				  paramThree, valueThree,
				  [appDel udAccessToken]];

		strMD5 = [NSString stringWithFormat:@"%@%@", urlMD5, [appDel udSecret]];

		// But encode for sending req to the server
		url = [NSString stringWithFormat:@"/method/%@?%@=%@&%@=%@&%@=%@&access_token=%@",
			   method,
			   paramOne, [valueOne urlEncodeUsingEncoding:NSUTF8StringEncoding],
			   paramTwo, [valueTwo urlEncodeUsingEncoding:NSUTF8StringEncoding],
			   paramThree, [valueThree urlEncodeUsingEncoding:NSUTF8StringEncoding],
			   [appDel udAccessToken]];
	}
	else
	{
		urlMD5 = [NSString stringWithFormat:@"/method/%@?%@=%@&%@=%@&access_token=%@", method,
				  paramOne, valueOne,
				  paramTwo, valueTwo,
				  [appDel udAccessToken]];

		strMD5 = [NSString stringWithFormat:@"%@%@", urlMD5, [appDel udSecret]];

		url = [NSString stringWithFormat:@"/method/%@?%@=%@&%@=%@&access_token=%@",
						  method,
						  paramOne, [valueOne urlEncodeUsingEncoding:NSUTF8StringEncoding],
						  paramTwo, [valueTwo urlEncodeUsingEncoding:NSUTF8StringEncoding],
						  [appDel udAccessToken]];
	}

	NSString * finalUrl = [NSString stringWithFormat:@"%@%@%@&sig=%@", kPrefixHttp, kVKApiHost, url, [strMD5 MD5]];

	[[[VKReq alloc] initWithTarget:target action:action fail:actionFail] get:finalUrl];
}


// TODO IMPORTANT: Often NSURLSession fails this https query, cos of self-signed cert (accept/deny), we DO NEED to handle that!
+ (void)authWithLogin:(NSString *)login password:(NSString *)password target:(id)target action:(SEL)action
{
	NSString * url = [NSString stringWithFormat:@"https://api.vk.com/oauth/token?grant_type=password&client_id=%@&client_secret=%@&username=%@&password=%@&scope=%@",
					  kClientId,
					  kClientSecret,
					  [login urlEncodeUsingEncoding:NSUTF8StringEncoding],
					  [password urlEncodeUsingEncoding:NSUTF8StringEncoding],
					  kScope];

	[[[VKReq alloc] initWithTarget:target action:action fail:nil] get:url];
}


// TODO:
// + (void)postMethod:(NSString *)method withParams:(NSString *)params target:(id)target action:(SEL)action

- (id)initWithTarget:(id)target action:(SEL)action fail:(SEL)actionFail
{
	self = [super init];
	if (self)
	{
		self.target = target;
		self.didGetResponseSelector = action;
		self.didFailSelector = actionFail;
		_responseData = [NSMutableData data]; // ivar cos property readonly
	}

	return self;
}

- (void)get:(NSString *)url
{
	NSMutableURLRequest * req =[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
										 cachePolicy:NSURLRequestUseProtocolCachePolicy
									 timeoutInterval:60.0];

	// NSLog(@"Sending GET to URL: %@", url);

//	NSMutableDictionary * headers = [[NSMutableDictionary alloc] init];
//	[headers setObject:@"gzip, deflate" forKey:@"Accept-Encoding"];
	// other headers
	//	[req setAllHTTPHeaderFields:headers];
	// continue request

	// Enable gzip compression, the connection will automatically unzip compressed response
//	[req setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"]; // Enable gzip compression
	[req setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"]; // This is only for server responses

	// NSURLConnection is keep alive, as soon as server supports it
	// Also smart enough to reuse HTTP 1.1 connection despite new object allocation
	self.connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
}

- (void)postImage:(NSString *)url withData:(NSData *)data
{
	NSMutableURLRequest * req =[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
										 cachePolicy:NSURLRequestUseProtocolCachePolicy
									 timeoutInterval:60.0]; // During this time NSURLConnection makes sure connection is keep-alive

	[req setHTTPMethod:@"POST"];
	[req addValue:@"8bit" forHTTPHeaderField:@"Content-Transfer-Encoding"];

	CFUUIDRef uuid = CFUUIDCreate(nil);
    NSString * uuidString = (__bridge NSString *)CFUUIDCreateString(nil, uuid);
    CFRelease(uuid);

    NSString * stringBoundary = [NSString stringWithFormat:@"0xKhTmLbOuNdArY-%@", uuidString];

    NSString * endItemBoundary = [NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary];
	
	NSString * contentType = [NSString stringWithFormat:@"multipart/form-data;  boundary=%@", stringBoundary];
	[req setValue:contentType forHTTPHeaderField:@"Content-Type"];

	NSMutableData * body = [NSMutableData data];

	[body appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];


    [body appendData:data];
    [body appendData:[[NSString stringWithFormat:@"%@", endItemBoundary] dataUsingEncoding:NSUTF8StringEncoding]];

	[req setHTTPBody:body];

	self.connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
}

+ (void)postPhoto:(NSString *)url withImage:(UIImage *)image target:(id)target action:(SEL)action fail:(SEL)actionFail
{
	NSData * data = UIImageJPEGRepresentation(image, 1.0f);
//	NSData * data = UIImageJPEGRepresentation(image, 0.0f);

	// NSLog(@"Posting image data of size %i bytes", data.length);

	[[[VKReq alloc] initWithTarget:target action:action fail:actionFail] postImage:url withData:data];

}


#pragma mark NSURLConnection delegate methods

// When the server has provided sufficient data to create an NSURLResponse object, the delegate
// receives a connection:didReceiveResponse: message.
// The delegate method can examine the provided NSURLResponse and determine the expected
// content length of the data, MIME type, suggested filename and other metadata provided by the server.
// Important: You should be prepared for your delegate to receive the
// connection:didReceiveResponse: message multiple times for a single connection.
// This message can be sent due to server redirects, or in rare cases multi-part MIME documents.
// Each time the delegate receives the connection:didReceiveResponse: message, it should
// reset any progress indication and discard all previously received data.
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	// This method is called when the server has determined that it
    // has enough information to create the NSURLResponse.
    // It can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
//	// NSLog(@"didReceiveResponse called");

	// receivedData is an instance variable declared elsewhere.
    _responseData.length = 0;
}

// The delegate is periodically sent connection:didReceiveData: messages as the data is received.
// The delegate implementation is responsible for storing the newly received data. 
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
//	// NSLog(@"didReceiveData");

	// Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
	[_responseData appendData:data];
}

// If an error is encountered during the download, the delegate receives a connection:didFailWithError: message.
// After the delegate receives a message connection:didFailWithError:, it receives no further
// delegate messages for the specified connection.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	// NSLog(@"didFailWithError, error: %@", [error localizedDescription]);

	// release the connection, and the data object
	//	[connection release];
	// receivedData is declared as a method instance elsewhere
	//	[receivedData release];
	[_responseData setData:nil];

	// No leak here, provided we implement action on delegate. We always do.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[self.target performSelector:self.didFailSelector withObject:self];
#pragma clang diagnostic pop
}

// Finally, if the connection succeeds in downloading the request, the delegate receives
// the connectionDidFinishLoading: message. The delegate will receive no further messages
// for the connection and the NSURLConnection object can be released.
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString * s = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];

//	if (s.length>255)
//		// NSLog(@"connectionDidFinishLoading, len %i", s.length);
//	else
		// NSLog(@"connectionDidFinishLoading, len %i, data: %@", s.length, s);

//	[_delegate didGetResponse:self]; // Call delegate method, old approach

	// No leak here, provided we implement action on delegate. We always do.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[self.target performSelector:self.didGetResponseSelector withObject:self];
#pragma clang diagnostic pop
}

@end


#pragma mark NSString category

// TODO: Potential leak here, use Analyzer
@implementation NSString (URLEncoding)
-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding
{
	// TODO: Yes it leaks here, sort please
	//	From http://madebymany.com/blog/url-encoding-an-nsstring-on-ios
	return (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
																		(__bridge CFStringRef)self,
																		NULL,
																		(CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
																		CFStringConvertNSStringEncodingToEncoding(encoding));
}
@end


@implementation NSString (MD5)

// TODO: Does this leak?
- (NSString *)MD5
{
	// Create pointer to the string as UTF8
	const char * ptr = [self UTF8String];

	// Create byte array of unsigned chars
	unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];

	// Create 16 byte MD5 hash value, store in buffer
	CC_MD5(ptr, strlen(ptr), md5Buffer);

	// Convert MD5 value in the buffer to NSString of hex values
	NSMutableString * output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
	for (short i=0; i<CC_MD5_DIGEST_LENGTH; ++i) 
		[output appendFormat:@"%02x", md5Buffer[i]];

	return output;
}
@end


// http://stackoverflow.com/questions/1105169/html-character-decoding-in-objective-c-cocoa-touch
// TODO: Rewrite this or replace with decent solution
@implementation NSString (decodingEntities)

- (NSString *)stringByDecodingXMLEntities
{
    NSUInteger myLength = [self length];
    NSUInteger ampIndex = [self rangeOfString:@"&" options:NSLiteralSearch].location;

    // Short-circuit if there are no ampersands.
    if (ampIndex == NSNotFound) {
        return self;
    }
    // Make result string with some extra capacity.
    NSMutableString *result = [NSMutableString stringWithCapacity:(myLength * 1.25)];
	
    // First iteration doesn't need to scan to & since we did that already, but for code simplicity's sake we'll do it again with the scanner.
    NSScanner *scanner = [NSScanner scannerWithString:self];
	
    [scanner setCharactersToBeSkipped:nil];
	
    NSCharacterSet *boundaryCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" \t\n\r;"];
	
    do {
        // Scan up to the next entity or the end of the string.
        NSString *nonEntityString;
        if ([scanner scanUpToString:@"&" intoString:&nonEntityString]) {
            [result appendString:nonEntityString];
        }
        if ([scanner isAtEnd]) {
            goto finish;
        }
        // Scan either a HTML or numeric character entity reference.
        if ([scanner scanString:@"&amp;" intoString:NULL])
            [result appendString:@"&"];
        else if ([scanner scanString:@"&apos;" intoString:NULL])
            [result appendString:@"'"];
        else if ([scanner scanString:@"&quot;" intoString:NULL])
            [result appendString:@"\""];
        else if ([scanner scanString:@"&lt;" intoString:NULL])
            [result appendString:@"<"];
        else if ([scanner scanString:@"&gt;" intoString:NULL])
            [result appendString:@">"];
        else if ([scanner scanString:@"&#" intoString:NULL]) {
            BOOL gotNumber;
            unsigned charCode;
            NSString *xForHex = @"";
			
            // Is it hex or decimal?
            if ([scanner scanString:@"x" intoString:&xForHex]) {
                gotNumber = [scanner scanHexInt:&charCode];
            }
            else {
                gotNumber = [scanner scanInt:(int*)&charCode];
            }
			
            if (gotNumber) {
                [result appendFormat:@"%C", charCode];
				
				[scanner scanString:@";" intoString:NULL];
            }
            else
			{
                NSString *unknownEntity = @"";
				[scanner scanUpToCharactersFromSet:boundaryCharacterSet intoString:&unknownEntity];
				[result appendFormat:@"&#%@%@", xForHex, unknownEntity];
				
                //[scanner scanUpToString:@";" intoString:&unknownEntity];
                //[result appendFormat:@"&#%@%@;", xForHex, unknownEntity];
//                // NSLog(@"Expected numeric character entity but got &#%@%@;", xForHex, unknownEntity);
            }
        }
        else
		{
			NSString * amp;
			[scanner scanString:@"&" intoString:&amp];      //an isolated & symbol
			[result appendString:amp];
			
			/*
			 NSString *unknownEntity = @"";
			 [scanner scanUpToString:@";" intoString:&unknownEntity];
			 NSString *semicolon = @"";
			 [scanner scanString:@";" intoString:&semicolon];
			 [result appendFormat:@"%@%@", unknownEntity, semicolon];
			 // NSLog(@"Unsupported XML character entity %@%@", unknownEntity, semicolon);
			 */
        }
    }
    while (![scanner isAtEnd]);

finish:
    return result;
}

@end
