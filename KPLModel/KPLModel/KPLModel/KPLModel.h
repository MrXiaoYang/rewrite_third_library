//
//  KPLModel.h
//  KPLModel
//
//  Created by 密码:1 on 2018/4/8.
//  Copyright © 2018年 密码:1. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<KPLModel/KPLModel.h>)
FOUNDATION_EXPORT double KPLModelVersionNumber;
FOUNDATION_EXPORT const unsigned char KPLModelVersionString[];
#import <KPLModel/NSObject+KPLModel.h>
#import <KPLModel/KPLClassInfo.h>
#else 
#import "NSObject+KPLModel.h"
#import "KPLClassInfo.h"
#endif
