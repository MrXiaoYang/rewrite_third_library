//
//  NSObject+KPLModel.m
//  KPLModel
//
//  Created by 密码:1 on 2018/4/8.
//  Copyright © 2018年 密码:1. All rights reserved.
//

#import "NSObject+KPLModel.h"
#import "KPLClassInfo.h"


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

- (instancetype)initWithClass:(Class)cls {
    KPLClassInfo *classInfo = [KPLClassInfo classInfoWIthClass:cls];
    
}


@end
