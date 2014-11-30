//
//  Constants.m
//  VKM
//
//  Created by Max on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Constants.h"

NSString * const kPrefixHttp = @"http://";
NSString * const kPrefixHttps = @"https://";
NSString * const kVKApiHost = @"api.vk.com";


// The three below are used for user auth (obtain access_token)
NSString * const kClientId = @"2854982";
NSString * const kClientSecret = @"6yVqEHfcrGQ2NJYT6kg4"; // TODO: We certainly mustn't store this in our app (?)
NSString * const kScope = @"notify,friends,photos,audio,video,docs,notes,pages,wall,groups,messages,notifications,ads,offline,nohttps"; // @"scope=messages,nohttps";


@implementation Misc
+ (BOOL)retina
{
	return ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] == YES && [[UIScreen mainScreen] scale] == 2.0f);
}
@end




// Smart date formatters
#define MINUTE 60
#define HOUR   (60 * MINUTE)
#define DAY    (24 * HOUR)
#define WEEKDAYS (5 * DAY)
#define WEEK   (7 * DAY)
#define MONTH  (30.5 * DAY)
#define YEAR   (365 * DAY)


// For latest dialogues
@implementation NSDate (HumanizedTime)

- (NSString *)formatTime
{
	static NSDateFormatter * formatter = nil;
	if (nil == formatter)
	{
		formatter = [[NSDateFormatter alloc] init];
		formatter.dateFormat = NSLocalizedString(@"h:mm a", @"Date format: 1:05 pm");
		formatter.locale = [NSLocale currentLocale];
	}
	return [formatter stringFromDate:self];
}

- (NSString *)formatShortTime
{
	NSTimeInterval diff = abs([self timeIntervalSinceNow]);

	// First check for yesterday, then all the rest
	NSCalendar * cal = nil;
	if (cal == nil)
		cal = [NSCalendar currentCalendar];

	NSDateComponents * messageDay = [cal components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit
										   fromDate:self];

	NSDateComponents * yesterday = [cal components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit
										  fromDate:[NSDate date]];
	if (yesterday.day-1 == messageDay.day && yesterday.month == messageDay.month && yesterday.year == messageDay.year)
	{
		return NSLocalizedString(@"Yesterday", @"");
	}
	else if (diff < DAY)
	{
		return [self formatTime];
	}
	else if (diff < WEEKDAYS)
	{
		static NSDateFormatter * formatter = nil;
		if (nil == formatter)
		{
			formatter = [[NSDateFormatter alloc] init];
			formatter.dateFormat = NSLocalizedString(@"EEEE", @"Date format: Mon");
			formatter.locale = [NSLocale currentLocale];
		}
		return [formatter stringFromDate:self];
	}
	else if (diff < YEAR)
	{
		static NSDateFormatter * formatter = nil;
		if (nil == formatter)
		{
			formatter = [[NSDateFormatter alloc] init];
			formatter.dateFormat = NSLocalizedString(@"MMMM d", @"Date format: July 27");
			formatter.locale = [NSLocale currentLocale];
		}
		return [formatter stringFromDate:self];
	}
	else
	{
		static NSDateFormatter * formatter = nil;
		if (nil == formatter)
		{
			formatter = [[NSDateFormatter alloc] init];
			formatter.dateFormat = NSLocalizedString(@"M/d/yy", @"Date format: 7/27/09");
			formatter.locale = [NSLocale currentLocale];
		}
		return [formatter stringFromDate:self];
	}
}

// For pull to refresh
- (NSString *) stringWithHumanizedTimeDifference
{
    NSTimeInterval timeInterval = [self timeIntervalSinceNow];
    int secondsInADay = 3600*24;
	int daysDiff = abs(timeInterval/secondsInADay);
    int hoursDiff = abs((abs(timeInterval) - (daysDiff * secondsInADay)) / 3600);
    int minutesDiff = abs((abs(timeInterval) - ((daysDiff * secondsInADay) + (hoursDiff * 60))) / 60);
	int secondsDiff = abs(timeInterval);
	
	NSString * positivity = [NSString stringWithFormat:@"%@", timeInterval < 0 ? NSLocalizedString(@"AgoKey", @""):NSLocalizedString(@"LaterKey", @"")];
	if (hoursDiff == 0)
	{
		if (minutesDiff == 0) // Les than a minute, count seconds
		{
			if (secondsDiff < 3) // If less than 3 second passed
				return [NSString stringWithFormat:@"%@", NSLocalizedString(@"Just now", @"")];
			else  // If more than 3 second passed
			{
				if (secondsDiff < 5) // секунды
					return [NSString stringWithFormat:@"%d %@ %@", secondsDiff, NSLocalizedString(@"Secundi", @""), positivity];
				else if (secondsDiff > 4 && secondsDiff < 20) // секунд
					return [NSString stringWithFormat:@"%d %@ %@", secondsDiff, NSLocalizedString(@"Secund", @""), positivity];
				else if (secondsDiff%10 == 0) // 20, 30, 50 секунд
					return [NSString stringWithFormat:@"%d %@ %@", secondsDiff, NSLocalizedString(@"Secund", @""), positivity];
				else if (secondsDiff%10 == 1) // 21, 31, 51 секунду
					return [NSString stringWithFormat:@"%d %@ %@", secondsDiff, NSLocalizedString(@"Secundu", @""), positivity];
				else if (secondsDiff%10 > 1 && secondsDiff%10 < 5) // 23, 33, 54 секунды
					return [NSString stringWithFormat:@"%d %@ %@", secondsDiff, NSLocalizedString(@"Secundi", @""), positivity];
				else // 25, 36, 59 секунд
					return [NSString stringWithFormat:@"%d %@ %@", secondsDiff, NSLocalizedString(@"Secund", @""), positivity];
			}
		}
		else // More than one minute
		{
			if (minutesDiff == 1)
				return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Minutu", @""), positivity];
			else if (minutesDiff < 5)
				return [NSString stringWithFormat:@"%d %@ %@", minutesDiff, NSLocalizedString(@"Minuti", @""), positivity];
			else if (minutesDiff > 4 && minutesDiff < 20)
				return [NSString stringWithFormat:@"%d %@ %@", minutesDiff, NSLocalizedString(@"Minut", @""), positivity];
			else if (minutesDiff%10 == 0) // 20, 30, 50 минут
				return [NSString stringWithFormat:@"%d %@ %@", minutesDiff, NSLocalizedString(@"Minut", @""), positivity];
			else if (minutesDiff%10 == 1) // 21, 31, 51 минуту
				return [NSString stringWithFormat:@"%d %@ %@", minutesDiff, NSLocalizedString(@"Minutu", @""), positivity];
			else if (minutesDiff%10 > 1 && minutesDiff%10 < 5) // 23, 33, 54 минуты
				return [NSString stringWithFormat:@"%d %@ %@", minutesDiff, NSLocalizedString(@"Minuti", @""), positivity];
			else // 25, 36, 59 минут
				return [NSString stringWithFormat:@"%d %@ %@", minutesDiff, NSLocalizedString(@"Minut", @""), positivity];
		}
	}
	else
	{
		if (hoursDiff == 1)
			return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Chas", @""), positivity];
		else if (hoursDiff < 5)
			return [NSString stringWithFormat:@"%d %@ %@", hoursDiff, NSLocalizedString(@"Chasa", @""), positivity];
		else if (hoursDiff > 4 && hoursDiff < 20)
			return [NSString stringWithFormat:@"%d %@ %@", hoursDiff, NSLocalizedString(@"Chasov", @""), positivity];
		else if (hoursDiff%10 == 0) // 20, 30, 50 часов
			return [NSString stringWithFormat:@"%d %@ %@", hoursDiff, NSLocalizedString(@"Chasov", @""), positivity];
		else if (hoursDiff%10 == 1) // 21, 31, 51 час
			return [NSString stringWithFormat:@"%d %@ %@", hoursDiff, NSLocalizedString(@"Chas", @""), positivity];
		else if (hoursDiff%10 > 1 && hoursDiff%10 < 5) // 23, 33, 54 часа
			return [NSString stringWithFormat:@"%d %@ %@", hoursDiff, NSLocalizedString(@"Chasa", @""), positivity];
		else // 25, 36, 59 часов
			return [NSString stringWithFormat:@"%d %@ %@", hoursDiff, NSLocalizedString(@"Chasov", @""), positivity];
	}
}

@end
