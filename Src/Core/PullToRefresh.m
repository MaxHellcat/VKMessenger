//
//  EGORefreshTableHeaderView.m
//  Demo
//
//  Created by Devin Doty on 10/14/09October14.
//  Copyright 2009 enormego. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "PullToRefresh.h"
#import "Constants.h"

#define FLIP_ANIMATION_DURATION 0.18f


@interface PullToRefreshView (Private)
- (void)setState:(State)aState;
@end

@implementation PullToRefreshView

@synthesize delegate=_delegate;

- (id)initWithFrame:(CGRect)frame header:(BOOL)header
{
	_header = header;

	return [self initWithFrame:frame arrowImageName:header?@"Refresh_Down":@"Refresh_Up"
					 textColor:[UIColor colorWithRed:87.0f/255.0f green:108.0f/255.0f blue:137.0f/255.0f alpha:1.0f]];
}

- (id)initWithFrame:(CGRect)frame arrowImageName:(NSString *)arrow textColor:(UIColor *)textColor
{
    if ((self = [super initWithFrame:frame]))
	{
		[self refreshLastUpdatedDate]; //  Update the last update date
		
		_reloading = NO;

		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.backgroundColor = [UIColor colorWithRed:226.0f/255.0f green:231.0f/255.0f blue:237.0f/255.0f alpha:1.0f];

		CGRect kidframe;
		if (_header)
			kidframe = CGRectMake(80.0f, frame.size.height-30.0f, self.frame.size.width, 20.0f);
		else
			kidframe = CGRectMake(80.0f, +28.0f, self.frame.size.width, 20.0f);

		// Label "Last updated..."
		UILabel * label = [[UILabel alloc] initWithFrame:kidframe];
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		label.font = [UIFont systemFontOfSize:12.0f];
		label.textColor = textColor;
		label.shadowColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
		label.shadowOffset = CGSizeMake(0.0f, 1.0f);
		label.backgroundColor = [UIColor clearColor];
		label.textAlignment = UITextAlignmentLeft;
		[self addSubview:label];
		_lastUpdatedLabel = label;

		// Label Pull Up/Down to refresh
		if (_header)
			kidframe = CGRectMake(80.0f, frame.size.height - 48.0f, self.frame.size.width, 20.0f);
		else
			kidframe = CGRectMake(80.0f, +10.0f, self.frame.size.width, 20.0f);
		label = [[UILabel alloc] initWithFrame:kidframe];
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		label.font = [UIFont boldSystemFontOfSize:13.0f];
		label.textColor = textColor;
		label.shadowColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
		label.shadowOffset = CGSizeMake(0.0f, 1.0f);
		label.backgroundColor = [UIColor clearColor];
		label.textAlignment = UITextAlignmentLeft;
		[self addSubview:label];
		_statusLabel = label;

		// Image of arrow
		if (_header)
			kidframe = CGRectMake(25.0f, frame.size.height - 65.0f, 30.0f, 55.0f);
		else
			kidframe = CGRectMake(25.0f, 10.0f, 30.0f, 55.0f);
		CALayer * layer = [CALayer layer];
		layer.frame = kidframe;
		layer.contentsGravity = kCAGravityResizeAspect;
		layer.contents = (id)[UIImage imageNamed:arrow].CGImage;

		if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
			layer.contentsScale = [[UIScreen mainScreen] scale];

		[[self layer] addSublayer:layer];
		_arrowImage = layer;

		// Activity indicator
		if (_header)
			kidframe = CGRectMake(25.0f, frame.size.height-38.0f, 20.0f, 20.0f);
		else
			kidframe = CGRectMake(25.0f, 45.0f, 20.0f, 20.0f);
		UIActivityIndicatorView * view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		view.frame = kidframe;
		[self addSubview:view];
		_activityView = view;

		[self setState:eStateIdle];
    }

	return self;
}

#pragma mark -
#pragma mark Setters

- (void)refreshLastUpdatedDate
{
//	NSDate * date = [self.delegate dataSourceLastUpdated:self];
	_lastUpdated = [NSDate date];

	NSTimeInterval timeInterval = [_lastUpdated timeIntervalSinceNow];
    int daysDiff = abs(timeInterval/3600*24);
    if (daysDiff > 0)
	{
		[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehaviorDefault];
		NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		_lastUpdatedLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Updated", nil), [dateFormatter stringFromDate:_lastUpdated]];
	}
	else // If less than a day passed since last update, show smart date
	{
		_lastUpdatedLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Updated", nil), [_lastUpdated stringWithHumanizedTimeDifference]];
	}

	[[NSUserDefaults standardUserDefaults] setObject:_lastUpdatedLabel.text forKey:@"PullToRefreshView_LastRefresh"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setState:(State)aState
{
	switch (aState)
	{
		case eStatePulling:
			_statusLabel.text = NSLocalizedString(@"Release to refresh", nil);
			[CATransaction begin];
			[CATransaction setAnimationDuration:FLIP_ANIMATION_DURATION];
			_arrowImage.transform = CATransform3DMakeRotation((M_PI / 180.0f) * 180.0f, 0.0f, 0.0f, 1.0f);
			[CATransaction commit];
			break;

		case eStateIdle:
			if (_state == eStatePulling)
			{
				[CATransaction begin];
				[CATransaction setAnimationDuration:FLIP_ANIMATION_DURATION];
				_arrowImage.transform = CATransform3DIdentity;
				[CATransaction commit];
			}
			_statusLabel.text = _header?
				NSLocalizedString(@"Pull down to refresh", nil):
				NSLocalizedString(@"Pull up to refresh", nil);
			[_activityView stopAnimating];
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions]; 
			_arrowImage.hidden = NO;
			_arrowImage.transform = CATransform3DIdentity;
			[CATransaction commit];
			[self refreshLastUpdatedDate];
			break;

		case eStateLoading:
			_statusLabel.text = NSLocalizedString(@"Loading", nil);
			[_activityView startAnimating];
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions]; 
			_arrowImage.hidden = YES;
			[CATransaction commit];
			break;

		default:
			break;
	}

	_state = aState;
}

#pragma mark -
#pragma mark ScrollView Methods

- (void)parentViewDidScroll:(UIScrollView *)scrollView
{
//	NSLog(@"parentViewDidScroll, offset %f, view height %f", scrollView.contentOffset.y, scrollView.contentSize.height);
//	NSLog(@"parentViewDidScroll, scrollView.contentInset.top %f", scrollView.contentInset.top);

	if (_state == eStateLoading)
	{
		if (_header)
		{
			CGFloat offset = MAX(scrollView.contentOffset.y * -1.0f, 0.0f);
			offset = MIN(offset, 60.0f);
			scrollView.contentInset = UIEdgeInsetsMake(offset, 0.0f, 0.0f, 0.0f);
		}
		else
		{
//			const float delta = (scrollView.contentSize.height-scrollView.frame.size.height);

//			CGFloat offset = MAX((scrollView.contentOffset.y) * -1.0f, delta); // TODO: Not sure this is right
//			offset = MIN(offset, delta+60.0f);
//			[scrollView setContentInset:UIEdgeInsetsMake(delta, 0.0f, delta+60.0f, 0.0f)];
		}
	}
	else if (scrollView.isDragging)
	{
		BOOL _loading = _reloading;
		
//		NSLog(@"See offset %f", scrollView.contentOffset.y);

		if (_header)
		{
			if (_state == eStatePulling && scrollView.contentOffset.y > -65.0f && scrollView.contentOffset.y < 0.0f && !_loading)
			{
				[self setState:eStateIdle];
			}
			else if (_state == eStateIdle)
			{
				if (scrollView.contentOffset.y < -65.0f && !_loading)
				{
					[self setState:eStatePulling];
				}
				else if (scrollView.contentOffset.y < -15.0f && scrollView.contentOffset.y > -25.0f && !_loading) // Short interval to refresh last updated date
				{
					_lastUpdatedLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Updated", nil), [_lastUpdated stringWithHumanizedTimeDifference]];
				}
			}
			if (scrollView.contentInset.top != 0)
			{
				scrollView.contentInset = UIEdgeInsetsZero;
			}
		}
		else
		{
			const float delta = (scrollView.contentSize.height-scrollView.frame.size.height);

			if (_state == eStatePulling && scrollView.contentOffset.y < delta+65.0f && scrollView.contentOffset.y > delta && !_loading)
			{
				[self setState:eStateIdle];
			}
			else if (_state == eStateIdle && scrollView.contentOffset.y > delta+65.0f && !_loading)
			{
				[self setState:eStatePulling];
			}

			if (scrollView.contentInset.top != delta) // TODO: Not sure this is right
			{
				scrollView.contentInset = UIEdgeInsetsZero;
			}
		}

	}
}

- (void)parentViewDidEndDragging:(UIScrollView *)scrollView
{
	BOOL _loading = _reloading;

	// Upper threshold to trigger refresh
	if (_header)
	{
		if (scrollView.contentOffset.y <= -65.0f && !_loading)
		{
			[_delegate pullToRefreshDidTriggerRefresh:self];
			_reloading = YES;
			
			[self setState:eStateLoading];
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:0.2f];
			scrollView.contentInset = UIEdgeInsetsMake(60.0f, 0.0f, 0.0f, 0.0f);
			[UIView commitAnimations];
		}
	}
	else
	{
		const float delta = (scrollView.contentSize.height-scrollView.frame.size.height);

		if (scrollView.contentOffset.y >= delta+65.0f && !_loading)
		{
			[_delegate pullToRefreshDidTriggerRefresh:self];
			_reloading = YES;

//			[self setState:eStateLoading];
//			[UIView beginAnimations:nil context:NULL];
//			[UIView setAnimationDuration:0.2f];
//			scrollView.contentInset = UIEdgeInsetsMake(delta, 0.0f, delta+60.0f, 0.0f); // TODO: Not sure this is right
//			[UIView commitAnimations];
		}
	}
	
}

- (void)dataSourceDidFinishLoading:(UIScrollView *)scrollView
{	
	_reloading = NO;

	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3f];

	if (_header)
	{
		[scrollView setContentInset:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
	}
	else
	{
//		const float delta = (scrollView.contentSize.height-scrollView.frame.size.height);
//		[scrollView setContentInset:UIEdgeInsetsMake(delta, 0.0f, delta+60.0f, 0.0f)];
	}
	[UIView commitAnimations];

	[self setState:eStateIdle];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc
{
	_delegate = nil;
	_activityView = nil;
	_statusLabel = nil;
	_arrowImage = nil;
	_lastUpdatedLabel = nil;
}

@end
