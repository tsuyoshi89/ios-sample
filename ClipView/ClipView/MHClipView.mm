//
//  MHClipView.m
//  MHLib
//
//  Created by tsuyoshi on 2013/10/04.
//  Copyright (c) 2013年 Sola Co., Ltd. All rights reserved.
//

#import "MHClipView.h"
#import "MHImage.h"

#import <math.h>

inline CGFloat getMidX(const CGRect &rect)
{return CGRectGetMidX(rect);}
inline CGFloat getMidY(const CGRect &rect)
{return CGRectGetMidY(rect);}
inline CGFloat getMinX(const CGRect &rect)
{return CGRectGetMinX(rect);}
inline CGFloat getMinY(const CGRect &rect)
{return CGRectGetMinY(rect);}
inline CGFloat getMaxX(const CGRect &rect)
{return CGRectGetMaxX(rect);}
inline CGFloat getMaxY(const CGRect &rect)
{return CGRectGetMaxY(rect);}
inline CGFloat getWidth(const CGRect &rect)
{return rect.size.width;}
inline CGFloat getHeight(const CGRect &rect)
{return rect.size.height;}
inline CGRect stretchY(const CGRect &rect, CGFloat y)
{return CGRectMake(rect.origin.x, y, getWidth(rect), getHeight(rect) + (getMinY(rect) - y));}
inline CGPoint getMid(const CGRect &rect)
{return CGPointMake(getMidX(rect), getMidY(rect));}
inline CGPoint getMid(const CGSize &sz)
{return CGPointMake(sz.width / 2, sz.height / 2);}

inline CGRect MHRectMakeWithCenter(const CGPoint &center, const CGSize &sz) {
    return CGRectMake(center.x - sz.width / 2, center.y - sz.height / 2, sz.width, sz.height);
}

inline CGRect MHRectRound(const CGRect &r, const CGRect &bounds) {
    CGRect ret = r;
    if (getMinX(bounds) > getMinX(r)) {
        ret.origin.x += (getMinX(bounds) - getMinX(r));
    } else if (getMaxX(bounds) < getMaxX(r)) {
        ret.origin.x += (getMaxX(bounds) - getMaxX(r));
    }
    if (getMinY(bounds) > getMinY(r)) {
        ret.origin.y += (getMinY(bounds) - getMinY(r));
    } else if (getMaxY(bounds) < getMaxY(r)) {
        ret.origin.y += (getMaxY(bounds) - getMaxY(r));
    }
    return ret;
}


@implementation MHClipView {
    //CGPoint _clipCenter;
    //CGSize _clipSize;
    CGPoint _location;
    CGFloat _margin;
    BOOL _moving;
    int _touchCount;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        self.multipleTouchEnabled = YES;
   }
    return self;
}

- (id)initWithFrame:(CGRect)frame margin:(CGFloat)margin {
    self = [self initWithFrame:frame];
    if (self) {
        // Initialization code
        //_clipCenter = getMid(frame);
        //_clipSize = CGSizeMake(64.0, 64.0);
        self.backgroundColor = [UIColor clearColor];
        _margin = margin;
    }
    return self;
}

- (void)setMaskImage:(UIImage *)maskImage {
    if (maskImage == nil) {
        _shape = MHClipViewShapeCircle;
        _maskImage = nil;
        return;
    }
    UIImage *image = [UIImage createColorImage:maskImage.size color:[UIColor whiteColor]];
    image = [image createWithMask:maskImage];
    _maskImage = image;
    _shape = MHClipViewShapeMaskImage;
}

- (void)drawRect:(CGRect)rect {
    //CGRect clipRect = SLRectMakeCenter(_clipCenter, _clipSize);
    //clipRect = SLRectRound(clipRect, self.bounds);
    CGRect clipRect = CGRectInset(self.bounds, _margin, _margin);
    if (self.shape == MHClipViewShapeCircle) {
        UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:clipRect];
        [[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0] setFill];
        [[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0] setStroke];
        [circle setLineWidth:4.0f];
        CGFloat dashPattern[2] = {4.0f, 8.0f};
        [circle setLineDash:dashPattern  count:2 phase:0];
        [circle fillWithBlendMode:kCGBlendModeLighten alpha:0.5];
        [circle strokeWithBlendMode:kCGBlendModeExclusion alpha:1.0];
    } else if (self.shape == MHClipViewShapeMaskImage) {
        [self.maskImage drawInRect:clipRect blendMode:kCGBlendModeLighten alpha:0.5];
    }
}

- (UIBezierPath *)getClipPath {
    CGSize scales = CGSizeMake(self.frame.size.width / self.bounds.size.width, self.frame.size.height / self.bounds.size.height);
    CGFloat marginX = _margin * scales.width;;
    CGFloat marginY = _margin * scales.height;
    CGRect clipRect = CGRectInset(self.frame, marginX, marginY);
    if (self.shape == MHClipViewShapeCircle) {
        return [UIBezierPath bezierPathWithOvalInRect:clipRect];
    } else {
        return [UIBezierPath bezierPathWithRect:clipRect];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    _location = [touch locationInView:self];
    _touchCount += touches.count;
    _moving = (_touchCount == 1);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if ([touches count] == 2) {
        NSArray *twoFingers = [touches allObjects];
        UITouch *touch1 = [twoFingers objectAtIndex:0];
        UITouch *touch2 = [twoFingers objectAtIndex:1];
        CGPoint previous1 = [touch1 previousLocationInView:self];
        CGPoint previous2 = [touch2 previousLocationInView:self];
        CGPoint now1 = [touch1 locationInView:self];
        CGPoint now2 = [touch2 locationInView:self];
        
        CGFloat previousDistance = [self distanceWithPointA:previous1 pointB:previous2];
        CGFloat distance = [self distanceWithPointA:now1 pointB:now2];
#if 1
        CGFloat diff = (distance - previousDistance);
        CGRect frame = CGRectInset(self.frame, -diff / 2, -diff / 2);
        if (frame.size.width < 100) {
            frame.size.height = frame.size.width = 100;
        }
        CGFloat maxRadius = MIN(self.superview.bounds.size.width + _margin * 2, self.superview.bounds.size.height + _margin * 2);
        if (frame.size.width > maxRadius) {
            frame.size.width = frame.size.height = maxRadius;
        }
        frame = MHRectMakeWithCenter(self.center, frame.size);
        frame = MHRectRound(frame, CGRectInset(self.superview.bounds, -_margin, -_margin));
        [self setFrame:frame];
        [self setNeedsDisplay];
#else
        
        CGFloat maxScale = (self.superview.bounds.size.width / (self.bounds.size.width - _margin * 2));
        maxScale = SOLA_MAX(maxScale, (self.superview.bounds.size.height / (self.bounds.size.height - _margin * 2));
        CGFloat scale = 1.0;
        CGFloat width = self.bounds.size.width;
        scale *= (width + (distance - previousDistance)) / width;
        CGAffineTransform newTransform = CGAffineTransformScale(self.transform, scale, scale);
        self.transform = newTransform;
        
        
#endif
    }
    
    if (_moving) {
        UITouch *touch = [touches anyObject];
        CGPoint location = [touch locationInView:self];
        CGPoint center = CGPointMake(self.center.x + (location.x - _location.x), self.center.y + (location.y - _location.y));
        
        CGRect frame = MHRectMakeWithCenter(center, self.frame.size);
        frame = MHRectRound(frame, CGRectInset(self.superview.bounds, -_margin, -_margin));
        self.center = getMid(frame);
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    _touchCount -= touches.count;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    _touchCount -= touches.count;
}

- (CGFloat)distanceWithPointA:(CGPoint)pointA pointB:(CGPoint)pointB {
    CGFloat dx = fabs( pointB.x - pointA.x );
    CGFloat dy = fabs( pointB.y - pointA.y );
    return sqrt(dx * dx + dy * dy);
}



@end
