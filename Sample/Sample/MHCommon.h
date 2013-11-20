//
//  MHCommon.h
//  Sample
//
//  Created by tsuyoshi on 2013/11/20.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#ifndef Sample_MHCommon_h
#define Sample_MHCommon_h

#ifdef __OBJC__
#ifdef __cplusplus
//compare(less) function for CacheMap
class MHCompareNSString {
public:
    typedef NSString *pt;
    MHCompareNSString(const MHCompareNSString&){;}
    MHCompareNSString(){;}
    bool operator()(const pt &left, const pt &right) const {
        return [left compare:(NSString *)right] == NSOrderedAscending;
    }
};

//!!!:CGRectintersectsRect return true, if left rect(or right rect) is empty(width or height is zero) at iOS7
inline bool MHRectIntersectsRect(const CGRect &left, const CGRect &right)
{return !CGRectIsEmpty(CGRectIntersection(left, right));}

#endif /* __cplusplus */

#endif /* __OBJC__ */

#endif
