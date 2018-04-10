//
//  NSObject+KPLModel.m
//  KPLModel
//
//  Created by 密码:1 on 2018/4/8.
//  Copyright © 2018年 密码:1. All rights reserved.
//

#import "NSObject+KPLModel.h"
#import "KPLClassInfo.h"
#import <objc/message.h>

#define force_inline __inline__ __attribute__((always_inline))

/// Foundation Class Type
typedef NS_ENUM(NSUInteger, KPLEncodingNSType) {
    KPLEncodingTypeNSUnkonwn = 0,
    KPLEncodingTypeNSString,
    KPLEncodingTypeNSMutableString,
    KPLEncodingTypeNSValue,
    KPLEncodingTypeNSNumber,
    KPLEncodingTypeNSDecimalNumber,
    KPLEncodingTypeNSData,
    KPLEncodingTypeNSMutableData,
    KPLEncodingTypeNSDate,
    KPLEncodingTypeNSURL,
    KPLEncodingTypeNSArray,
    KPLEncodingTypeNSMutableArray,
    KPLEncodingTypeNSDictionary,
    KPLEncodingTypeNSMutableDictionary,
    KPLEncodingTypeNSSet,
    KPLEncodingTypeNSMutableSet,
};


/// Get the Foundation class type from property info.
static force_inline KPLEncodingNSType KPLClassGetNSType(Class cls) {
    if (!cls) return KPLEncodingTypeNSUnkonwn;
    
    if ([cls isSubclassOfClass:[NSMutableString class]]) return KPLEncodingTypeNSMutableString;
    if ([cls isSubclassOfClass:[NSString class]]) return KPLEncodingTypeNSString;
    if ([cls isSubclassOfClass:[NSDecimalNumber class]]) return KPLEncodingTypeNSDecimalNumber;
    if ([cls isSubclassOfClass:[NSNumber class]]) return KPLEncodingTypeNSNumber;
    if ([cls isSubclassOfClass:[NSValue class]]) return KPLEncodingTypeNSValue;
    if ([cls isSubclassOfClass:[NSMutableData class]]) return KPLEncodingTypeNSMutableData;
    if ([cls isSubclassOfClass:[NSData class]]) return KPLEncodingTypeNSData;
    if ([cls isSubclassOfClass:[NSDate class]]) return KPLEncodingTypeNSDate;
    if ([cls isSubclassOfClass:[NSURL class]]) return KPLEncodingTypeNSURL;
    if ([cls isSubclassOfClass:[NSMutableArray class]]) return KPLEncodingTypeNSMutableArray;
    if ([cls isSubclassOfClass:[NSArray class]]) return KPLEncodingTypeNSArray;
    if ([cls isSubclassOfClass:[NSMutableDictionary class]]) return KPLEncodingTypeNSMutableDictionary;
    if ([cls isSubclassOfClass:[NSDictionary class]]) return KPLEncodingTypeNSDictionary;
    if ([cls isSubclassOfClass:[NSMutableSet class]]) return KPLEncodingTypeNSMutableSet;
    if ([cls isSubclassOfClass:[NSSet class]]) return KPLEncodingTypeNSSet;
    
    return KPLEncodingTypeNSUnkonwn;
}

/// Whether the type is c number.
static force_inline BOOL KPLEncodingTypeIsCNumber(KPLEncodingType type) {
    switch (type & KPLEncodingTypeMask) {
        case KPLEncodingTypeBool:
        case KPLEncodingTypeInt8:
        case KPLEncodingTypeUInt8:
        case KPLEncodingTypeInt16:
        case KPLEncodingTypeUInt16:
        case KPLEncodingTypeInt32:
        case KPLEncodingTypeUInt32:
        case KPLEncodingTypeInt64:
        case KPLEncodingTypeUInt64:
        case KPLEncodingTypeFloat:
        case KPLEncodingTypeDouble:
        case KPLEncodingTypeLongDouble:
        return YES;
        default: return NO;
    }
    
    return NO;
}

@implementation NSObject (KPLModel)

+ (NSDictionary *)kpl_dictonaryWithJSON:(id)json {
    if (!json || json == (id)kCFNull) return nil;
    NSDictionary *dic = nil;
    NSData *jsonData = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        dic = json;
    } else if ([json isKindOfClass:[NSString class]]) {
        jsonData = [(NSString *)json dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([json isKindOfClass:[NSData class]]) {
        jsonData = json;
    }
    if (jsonData) {
        dic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
        if (![dic isKindOfClass:[NSDictionary class]]) dic = nil;
    }
    return dic;
}

+ (instancetype)kpl_modelWithJSON:(id)json {
    NSDictionary *dic = [self kpl_dictonaryWithJSON:json];
    return [self kpl_modelWithDictionary:dic];
}

+ (instancetype)kpl_modelWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary || dictionary == (id)kCFNull) return nil;
    if (![dictionary isKindOfClass:[NSDictionary class]]) return nil;
    
    Class cls = [self class];
    
    return nil;
    
}

@end

/// A class info in object model.
@interface _KPLModelMeta : NSObject {
    @package
    KPLClassInfo *_classInfo;
/*
    /// Key:mapped key and key path, Value:_KPLModelPropertyMeta.
    NSDictionary *_mapper;
    /// Array<_KPLModelPropertyMeta>, all property meta of this model.
    NSArray *_allPropertyMetas;
    /// Array<_KPLModelPropertyMeta>, property meta which is mapped to a key path.
    NSArray *_keyPathPropertyMetas;
    /// Array<_KPLModelPropertyMeta>, property meta which is mapped to multi keys.
    NSArray *_multiKeysPropertyMetas;
    /// The number of mapped key (and key path), same to _mapper.count.
    NSUInteger _keyMappedCount;
    /// Model class type.
    KPLEncodingNSType _nsType;
    */
}

@end

@implementation _KPLModelMeta

//- (instancetype)initWithClass:(Class)cls {
//    KPLClassInfo *classInfo = [KPLClassInfo classInfoWIthClass:cls];
//    
//}


@end
