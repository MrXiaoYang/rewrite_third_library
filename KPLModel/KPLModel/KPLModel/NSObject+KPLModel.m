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

/// Parse a number value from 'id'.
static force_inline NSNumber *KPLNSNumberCreateFromID(__unsafe_unretained id value) {
    static NSCharacterSet *dot;
    static NSDictionary *dic;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dot = [NSCharacterSet characterSetWithRange:NSMakeRange('.', 1)];
        dic = @{
                @"TRUE"   : @(YES),
                @"True"   : @(YES),
                @"true"   : @(YES),
                @"FALSE"  : @(NO),
                @"False"  : @(NO),
                @"false"  : @(NO),
                @"YES"    : @(YES),
                @"Yes"    : @(YES),
                @"yes"    : @(YES),
                @"NO"     : @(NO),
                @"No"     : @(NO),
                @"no"     : @(NO),
                @"NIL"    : (id)kCFNull,
                @"Nil"    : (id)kCFNull,
                @"nil"    : (id)kCFNull,
                @"NULL"   : (id)kCFNull,
                @"Null"   : (id)kCFNull,
                @"null"   : (id)kCFNull,
                @"(NULL)" : (id)kCFNull,
                @"(Null)" : (id)kCFNull,
                @"(null)" : (id)kCFNull,
                @"<NULL>" : (id)kCFNull,
                @"<Null>" : (id)kCFNull,
                @"<null>" : (id)kCFNull,
                };
    });
    
    if (!value || value == (id)kCFNull) return nil;
    if ([value isKindOfClass:[NSNumber class]]) return value;
    if ([value isKindOfClass:[NSString class]]) {
        NSNumber *num = dic[value];
        if (num != nil) {
            if (num == (id)kCFNull) return nil;
            return num;
        }
        if ([(NSString *)value rangeOfCharacterFromSet:dot].location != NSNotFound) {
            const char *cstring = ((NSString *)value).UTF8String;
            if (!cstring) return nil;
            double num = atof(cstring);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        } else {
            const char *cstring = ((NSString *)value).UTF8String;
            if (!cstring) return nil;
            return @(atoll(cstring));
        }
    }
    return nil;
}

/// Parser string to date.
static force_inline NSDate *KPLNSDateFromString(__unsafe_unretained NSString *string) {
    typedef NSDate * (^KPLNSDateParseBlock)(NSString *string);
    #define kParserNum 34
    static KPLNSDateParseBlock blocks[kParserNum + 1] = {0};
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       
        {
            /*
             2014-01-20 // Google
             */
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter.dateFormat = @"yyyy-MM-dd";
            blocks[10] = ^(NSString *string) {
                return [formatter dateFromString:string];
            };
        }
        
        {
            /*
             2014-01-20 12:24:48
             2014-01-20T12:24:48    // Google
             2014-01-20 12:24:48.000
             2014-01-20T12:24:48.000
             */
            NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
            formatter1.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter1.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter1.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
            
            NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter2.dateFormat = @"yyyy-MM-dd HH:mm:ss";
            
            NSDateFormatter *formatter3 = [[NSDateFormatter alloc] init];
            formatter3.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter3.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter3.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS";
            
            NSDateFormatter *formatter4 = [[NSDateFormatter alloc] init];
            formatter4.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter4.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter4.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
            
            blocks[19] = ^(NSString *string) {
                if ([string characterAtIndex:10] == 'T') {
                    return [formatter1 dateFromString:string];
                } else {
                    return [formatter2 dateFromString:string];
                }
            };
            
            blocks[23] = ^(NSString *string) {
                if ([string characterAtIndex:10] == 'T') {
                    return [formatter3 dateFromString:string];
                } else {
                    return [formatter4 dateFromString:string];
                }
            };
        }
        
        {
            /*
             2014-01-20T12:24:48Z       // Github, Apple
             2014-01-20T12:24:48+0800   // Facebook
             2014-01-20T12:24:48+12:00  // Google
             2014-01-20T12:24:48.000Z
             2014-01-20T12:24:48.000+0800
             2014-01-20T12:24:48.000+12:00
             */
            NSDateFormatter *formatter1 = [NSDateFormatter new];
            formatter1.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter1.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter1.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
            
            NSDateFormatter *formatter2 = [NSDateFormatter new];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter2.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
            
            blocks[20] = ^(NSString *string) { return [formatter1 dateFromString:string]; };
            blocks[24] = ^(NSString *string) { return [formatter1 dateFromString:string]?: [formatter2 dateFromString:string]; };
            blocks[25] = ^(NSString *string) { return [formatter1 dateFromString:string]; };
            blocks[28] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
            blocks[29] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
        }
        
        {
            /*
             Fri Sep 04 00:12:21 +0800 2015 //  Weibo, Twitter
             Fri Sep 04 00:12:21.000 +0800 2015
             */
            NSDateFormatter *formatter1 = [NSDateFormatter new];
            formatter1.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter1.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter1.dateFormat = @"EEE MMM dd HH:mm:ss Z yyyy";
            
            NSDateFormatter *formatter2 = [NSDateFormatter new];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter2.dateFormat = @"EEE MMM dd HH:mm:ss.SSS Z yyyy";
            
            blocks[30] = ^(NSString *string) {
                return [formatter1 dateFromString:string];
            };
            
            blocks[34] = ^(NSString *string) {
                return [formatter2 dateFromString:string];
            };
        }
    });
    if (!string) return nil;
    if (string.length > kParserNum) return nil;
    KPLNSDateParseBlock parser = blocks[string.length];
    if (!parser) return nil;
    return parser(string);
    #undef kParserNum
}

/// Get the 'NSBlock' class.
static force_inline Class KPLNSBlockClass() {
    static Class cls;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void (^block)(void) = ^{};
        cls = ((NSObject *)block).class;
        while (class_getSuperclass(cls) != [NSObject class]) {
            cls = class_getSuperclass(cls);
        };
    });
    return cls; // current is 'NSBlock'
}

/**
 Get the ISO date formatter.
 ISO8601 format example:
 2010-07-09T16:13:30+12:00
 2011-01-11T11:11:11+0000
 2011-01-26T19:06:43Z
 
 length: 20/24/25
*/
static force_inline NSDateFormatter *KPLISODateFormatter() {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    });
    return formatter;
}

/// Get the value with key paths from dictioanry
/// The dic should be NSDictionary, and the keyPath should not be nil.
static force_inline id KPLValueForKeyPath(__unsafe_unretained NSDictionary *dic, __unsafe_unretained NSArray *keyPaths) {
    id value = nil;
    for (NSUInteger i = 0, max = keyPaths.count; i < max; i++ ) {
        value = dic[keyPaths[i]];
        if (i + 1 < max) {
            if ([value isKindOfClass:[NSDictionary class]]) {
                dic = value;
            } else {
                return nil;
            }
        }
    }
    return value;
}

/// Get the values with multi key (or key path) from dictionary
/// The dic should be NSDictionary
static force_inline id KPLValueForMultiKeys(__unsafe_unretained NSDictionary *dic, __unsafe_unretained NSArray *multiKeys) {
    id value = nil;
    for (NSString *key in multiKeys) {
        if ([key isKindOfClass:[NSString class]]) {
            value = dic[key];
            if (value) break;
        } else {
            value = KPLValueForKeyPath(dic, (NSArray *)key);
            if (value) break;
        }
    }
    return value;
}

/// A property info in object model
@interface _KPLModelPropertyMeta : NSObject {
    @package
    NSString *_name;    ///< property's name
    KPLEncodingType _type; ///< property's type
    KPLEncodingNSType _nsType; ///< property's Foundation type
    BOOL _isCNumber; ///< is c number type
    Class _cls; ///< property's class, or nil
    Class _genericCls; ///< container's generic class, or nil if threr's no generic class
    SEL _getter; ///< getter, or nil if the instances cannot respond
    SEL _setter; ///< setter, or nil if the instances cannot respond
    BOOL _isKVCCompatible; ///< YES if it can access with key-value coding
    BOOL _isStructAvailableForKeyedArchiver; ///< YES if the struct can encoded with keyed archiver/unarchiver
    BOOL _hasCustomClassFromDictionary; ///< class/generic class implements +modelCustomClassForDictionary:
    
    /*
     property->key:         _mappedToKey:key        _mapperToKeyPath:nil    _mappedToKeyArray:nil
     property->keyPath:     _mappedToKey:keyPath    _mappedToKeyPath:keyPath(array) _mappedToKeyArray:nil
     property->keys:        _mappedToKey:keys[0]    _mappedToKeyPath:nil/keyPath    _mappedToKeyArray:keys(array)
     */
    NSString *_mappedToKey; ///< the key mapped to
    NSArray *_mappedToKeyPath;  ///< the key path mapped to (nil if the name is not key path)
    NSArray *_mappedToKeyArray; ///< the key(NSStting) or keyPath(NSArray) array (nil if not mapped to multiple keys)
    KPLClassPropertyInfo *_info;    ///< property's info
    _KPLModelPropertyMeta *_next;   ///< next meta if there are multiple properties mapped to the same key.
}

@end

@implementation _KPLModelPropertyMeta
+ (instancetype)metaWithClassInfo:(KPLClassInfo *)classInfo propertyInfo:(KPLClassPropertyInfo *)propertyInfo generic:(Class)generic {
    
    // support pseudo gengric class with protocol name
    if (!generic && propertyInfo.protocols) {
        for (NSString *protocol in propertyInfo.protocols) {
            Class cls = objc_getClass(protocol.UTF8String);
            if (cls) {
                generic = cls;
                break;
            }
        }
    }
   
    _KPLModelPropertyMeta *meta = [self new];
    meta->_name = propertyInfo.name;
    meta->_type = propertyInfo.type;
    meta->_info= propertyInfo;
    meta->_genericCls = generic;
   
    if ((meta->_type & KPLEncodingTypeMask) == KPLEncodingTypeObject) {
        meta->_nsType = KPLClassGetNSType(propertyInfo.cls);
    } else {
        meta->_isCNumber = KPLEncodingTypeIsCNumber(meta->_type);
    }
    if ((meta->_type & KPLEncodingTypeMask) == KPLEncodingTypeStruct) {
        /*
         It seems that NSKeyedUnarchiver cannot decode NSValue except these structs:
         */
        static NSSet *types = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableSet *set = [NSMutableSet new];
            // 32 bit
            [set addObject:@"{CGSize=ff}"];
            [set addObject:@"{CGPoint=ff}"];
            [set addObject:@"{CGRect={CGPoint=ff}{CGSize=ff}}"];
            [set addObject:@"{CGAffineTransform=ffffff}"];
            [set addObject:@"{UIEdgeInsets=ffff}"];
            [set addObject:@"{UIOffset=ff}"];
            // 64 bit
            [set addObject:@"{CGSize=dd}"];
            [set addObject:@"{CGPoint=dd}"];
            [set addObject:@"{CGRect={CGPoint=dd}{CGSize=dd}}"];
            [set addObject:@"{CGAffineTransform=dddddd}"];
            [set addObject:@"{UIEdgeInsets=dddd}"];
            [set addObject:@"{UIOffset=dd}"];
            types = set;
        });
        
        if ([types containsObject:propertyInfo.typeEncoding]) {
            meta->_isStructAvailableForKeyedArchiver = YES;
        }
    }
    meta->_cls = propertyInfo.cls;
    
    if (generic) {
        meta->_hasCustomClassFromDictionary = [generic respondsToSelector:@selector(modelCustomClassForDictionary:)];
    } else if (meta->_cls && meta->_nsType == KPLEncodingTypeNSUnkonwn) {
        meta->_hasCustomClassFromDictionary = [meta->_cls respondsToSelector:@selector(modelCustomClassForDictionary:)];
    }
    
    if (propertyInfo.getter) {
        if ([classInfo.cls instancesRespondToSelector:propertyInfo.getter]) {
            meta->_getter = propertyInfo.getter;
        }
    }
    if (propertyInfo.setter) {
        if ([classInfo.cls instancesRespondToSelector:propertyInfo.setter]) {
            meta->_setter = propertyInfo.setter;
        }
    }
    
    if (meta->_getter && meta->_setter) {
        /*
         KVC invalid type:
         long double
         pointer (such as SEL/CoreFoundation objcet)
         */
        switch (meta->_type & KPLEncodingTypeMask) {
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
            case KPLEncodingTypeObject:
            case KPLEncodingTypeClass:
            case KPLEncodingTypeBlock:
            case KPLEncodingTypeStruct:
            case KPLEncodingTypeUnion: {
                meta->_isKVCCompatible = YES;
            } break;
            default:
                break;
        }
    }
    return meta;
}

@end

/// A class info in object model.
@interface _KPLModelMeta : NSObject {
    @package
    KPLClassInfo *_classInfo;
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
   
    BOOL _hasCustomWillTransformFromDictionary;
    BOOL _hasCustomTransformFromDictionary;
    BOOL _hasCustomTransformToDictionary;
    BOOL _hasCustomClassFromDictionary;
}

@end

@implementation _KPLModelMeta

- (instancetype)initWithClass:(Class)cls {
    KPLClassInfo *classInfo = [KPLClassInfo classInfoWithClass:cls];
    if (!classInfo) return nil;
    self = [super init];
    
    // Get black list
    NSSet *blacklist = nil;
    if ([cls respondsToSelector:@selector(modelPropertyBlacklist)]) {
        NSArray *properties = [(id<KPLModel>)cls modelPropertyBlacklist];
        if (properties) {
            blacklist = [NSSet setWithArray:properties];
        }
    }
    
    // Get white list
    NSSet *whitelist = nil;
    if ([cls respondsToSelector:@selector(modelPropertyWhitelist)]) {
        NSArray *properties = [(id<KPLModel>)cls modelPropertyWhitelist];
        if (properties) {
            whitelist = [NSSet setWithArray:properties];
        }
    }
    
    // Get container property's generic class
    NSDictionary *genericMapper = nil;
    if ([cls respondsToSelector:@selector(modelContainerPropertyGenericClass)]) {
        genericMapper = [(id<KPLModel>)cls modelContainerPropertyGenericClass];
        if (genericMapper) {
            NSMutableDictionary *tmp = [NSMutableDictionary new];
            [genericMapper enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if (![key isKindOfClass:[NSString class]]) return;
                Class meta = object_getClass(obj);
                if (!meta) return;
                if (class_isMetaClass(meta)) {
                    tmp[key] = obj;
                } else if ([obj isKindOfClass:[NSString class]]) {
                    Class cls = NSClassFromString(obj);
                    if (cls) {
                        tmp[key] = obj;
                    }
                }
            }];
            genericMapper = tmp;
        }
    }
    
    // Create all property metas.
    NSMutableDictionary *allPropertyMetas = [NSMutableDictionary new];
    KPLClassInfo *curClassInfo = classInfo;
    while (curClassInfo && curClassInfo.superCls != nil) { // recursive parse super class, but ignore root class (NSObject/NSProxy)
        for (KPLClassPropertyInfo *propertyInfo in curClassInfo.propertyInfos.allValues) {
            if (!propertyInfo.name) continue;
            if (blacklist && [blacklist containsObject:propertyInfo.name]) continue;
            if (whitelist && ![whitelist containsObject:propertyInfo.name]) continue;
            _KPLModelPropertyMeta *meta = [_KPLModelPropertyMeta metaWithClassInfo:classInfo propertyInfo:propertyInfo generic:genericMapper[propertyInfo.name]];
            if (!meta || !meta->_name) continue;
            if (!meta->_getter || !meta->_setter) continue;
            if (allPropertyMetas[meta->_name]) continue;
            allPropertyMetas[meta->_name] = meta;
        }
        curClassInfo = curClassInfo.superClassInfo;
    }
    if (allPropertyMetas.count) _allPropertyMetas = allPropertyMetas.allValues.copy;
    
    // create mapper
    NSMutableDictionary *mapper = [NSMutableDictionary new];
    NSMutableArray *keyPathPropertyMetas = [NSMutableArray new];
    NSMutableArray *multiKeysPropertyMetas = [NSMutableArray new];
    
    if ([cls respondsToSelector:@selector(modelCustomPropertyMapper)]) {
        NSDictionary *customMapper = [(id <KPLModel>)cls modelCustomPropertyMapper];
        [customMapper enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *mappedToKey, BOOL *stop) {
            _KPLModelPropertyMeta *propertyMeta = allPropertyMetas[propertyName];
            if (!propertyMeta) return;
            [allPropertyMetas removeObjectForKey:propertyName];
            
            if ([mappedToKey isKindOfClass:[NSString class]]) {
                if (mappedToKey.length == 0) return;
                
                propertyMeta->_mappedToKey = mappedToKey;
                NSArray *keyPath = [mappedToKey componentsSeparatedByString:@"."];
                for (NSString *onePath in keyPath) {
                    if (onePath.length == 0) {
                        NSMutableArray *tmp = keyPath.mutableCopy;
                        [tmp removeObject:@""];
                        keyPath = tmp;
                        break;
                    }
                }
                if (keyPath.count > 1) {
                    propertyMeta->_mappedToKeyPath = keyPath;
                    [keyPathPropertyMetas addObject:propertyMeta];
                }
                propertyMeta->_next = mapper[mappedToKey] ?: nil;
                mapper[mappedToKey] = propertyMeta;
            } else if ([mappedToKey isKindOfClass:[NSArray class]]) {
                
                NSMutableArray *mappedToKeyArray = [NSMutableArray array];
                for (NSString *oneKey in ((NSArray *)mappedToKey)) {
                    if (![oneKey isKindOfClass:[NSString class]]) continue;
                    if (oneKey.length == 0) continue;
                    
                    NSArray *keyPath = [oneKey componentsSeparatedByString:@"."];
                    if (keyPath.count > 1) {
                        [mappedToKeyArray addObject:keyPath];
                    } else {
                        [mappedToKeyArray addObject:oneKey];
                    }
                    
                    if (!propertyMeta->_mappedToKey) {
                        propertyMeta->_mappedToKey = oneKey;
                        propertyMeta->_mappedToKeyPath = keyPath.count > 1 ? keyPath : nil;
                    }
                }
                if (!propertyMeta->_mappedToKey) return;
                
                propertyMeta->_mappedToKeyArray = mappedToKeyArray;
                [multiKeysPropertyMetas addObject:propertyMeta];
                
                propertyMeta->_next = mapper[mappedToKey] ?: nil;
                mapper[mappedToKey] = propertyMeta;
                
            }
        }];
    }
    
    [allPropertyMetas enumerateKeysAndObjectsUsingBlock:^(NSString *name, _KPLModelPropertyMeta *propertyMeta, BOOL *stop) {
        propertyMeta->_mappedToKey = name;
        propertyMeta->_next = mapper[name] ?: nil;
        mapper[name] = propertyMeta;
    }];
    
    if (mapper.count) _mapper = mapper;
    if (keyPathPropertyMetas) _keyPathPropertyMetas = keyPathPropertyMetas;
    if (multiKeysPropertyMetas) _multiKeysPropertyMetas = multiKeysPropertyMetas;
    
    _classInfo = classInfo;
    _keyMappedCount = _allPropertyMetas.count;
    _nsType = KPLClassGetNSType(cls);
    _hasCustomWillTransformFromDictionary = ([cls instanceMethodForSelector:@selector(modelCustomWillTransformFromDictionary:)]);
    _hasCustomTransformFromDictionary = ([cls instanceMethodForSelector:@selector(modelCustomTransformFromDictionary:)]);
    _hasCustomTransformToDictionary = ([cls instanceMethodForSelector:@selector(modelCustomTransformToDictionary:)]);
    _hasCustomClassFromDictionary = ([cls instanceMethodForSelector:@selector(modelCustomClassForDictionary:)]);
    
    return self;
}

/// Returns the cached model class meta
+ (instancetype)metaWithClass:(Class)cls {
    if (!cls) return nil;
    static CFMutableDictionaryRef cache;
    static dispatch_once_t onceToken;
    static dispatch_semaphore_t lock;
    dispatch_once(&onceToken, ^{
        cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    _KPLModelMeta *meta = CFDictionaryGetValue(cache, (__bridge const void *)cls);
    dispatch_semaphore_signal(lock);
    if (!meta || meta->_classInfo.needUpdate) {
        meta = [[_KPLModelMeta alloc] initWithClass:cls];
        if (meta) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionaryGetValue(cache, (__bridge const void *)meta);
            dispatch_semaphore_signal(lock);
        }
    }
    return meta;
}

@end

/**
 Get number from property.
 @discussion Caller should hold strong reference to the parameters before this function returns.
 @param model Should not be nil.
 @param meta Should not be nil, meta.isCNumber should be YES, meta.getter should not be nil.
 @return A number object, or nil if failed.
 */
static force_inline NSNumber *ModelCreateNumberFromProperty(__unsafe_unretained id model, __unsafe_unretained _KPLModelPropertyMeta *meta) {
    
    switch (meta->_type & KPLEncodingTypeMask) {
        case KPLEncodingTypeBool: {
            return @(((bool (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case KPLEncodingTypeInt8: {
            return @(((int8_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case KPLEncodingTypeUInt8: {
            return @(((UInt8 (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case KPLEncodingTypeInt16: {
            return @(((int16_t (*)(id, SEL))(void *)objc_msgSend)((id)model, meta->_getter));
        }
        case KPLEncodingTypeUInt16: {
            return @(((UInt16 (*)(id, SEL)) objc_msgSend)((id)model, meta->_getter));
        }
        case KPLEncodingTypeInt32: {
            return @(((int32_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case KPLEncodingTypeUInt32: {
            return @(((int32_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case KPLEncodingTypeInt64: {
            return @(((int64_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case KPLEncodingTypeUInt64: {
            return @(((UInt64 (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case KPLEncodingTypeFloat: {
            float num = ((float (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        }
        case KPLEncodingTypeDouble: {
            double num = ((double (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        }
        case KPLEncodingTypeLongDouble: {
            double num = ((double (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        }
        default: return nil;
    }
}

/**
 Get number to property.
 @discussion Caller should hold strong reference to the parameters before this function returns.
 */
static force_inline void ModelSetNumberToProperty(__unsafe_unretained id model, __unsafe_unretained NSNumber *num, __unsafe_unretained _KPLModelPropertyMeta *meta) {
    
    switch (meta->_type & KPLEncodingTypeMask) {
        case KPLEncodingTypeBool: {
            ((void (*)(id, SEL, bool))(void *) objc_msgSend)((id)model, meta->_setter ,num.boolValue);
        } break;
        case KPLEncodingTypeInt8: {
            ((void (*)(id, SEL, int8_t))(void *) objc_msgSend)((id)model, meta->_setter, (int8_t)num.charValue);
        } break;
        case KPLEncodingTypeUInt8: {
            ((void (*)(id, SEL, UInt8))(void *) objc_msgSend)((id)model, meta->_setter, (UInt8)num.unsignedCharValue);
        } break;
        case KPLEncodingTypeInt16: {
            ((void (*)(id, SEL, int16_t))(void *) objc_msgSend)((id)model, meta->_setter, (int16_t)num.shortValue);
        } break;
        case KPLEncodingTypeUInt16: {
            ((void (*)(id, SEL, UInt16))(void *) objc_msgSend)((id)model, meta->_setter, (UInt16)num.unsignedShortValue);
        } break;
        case KPLEncodingTypeInt32: {
            ((void (*)(id, SEL, int32_t))(void *) objc_msgSend)((id)model, meta->_setter, (int32_t)num.intValue);
        } break;
        case KPLEncodingTypeUInt32: {
            ((void (*)(id, SEL, UInt32))(void *) objc_msgSend)((id)model, meta->_setter, (UInt32)num.unsignedIntValue);
        } break;
        case KPLEncodingTypeInt64: {
            if ([num isKindOfClass:[NSDecimalNumber class]]) {
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)model, meta->_setter, (int64_t)num.stringValue.longLongValue);
            } else {
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)model, meta->_setter, (int64_t)num.longLongValue);
            }
        } break;
        case KPLEncodingTypeUInt64: {
            if ([num isKindOfClass:[NSDecimalNumber class]]) {
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)model, meta->_setter, (int64_t)num.stringValue.longLongValue);
            } else {
                ((void (*)(id, SEL, UInt64))(void *) objc_msgSend)((id)model, meta->_setter, (UInt64)num.unsignedLongLongValue);
            }
        } break;
        case KPLEncodingTypeFloat: {
            float f = num.floatValue;
            if (isnan(f) || isinf(f)) f = 0;
            ((void (*)(id, SEL, float))(void *)objc_msgSend)((id)model, meta->_setter, f);
        } break;
        case KPLEncodingTypeDouble: {
            double d = num.doubleValue;
            if (isnan(d) || isinf(d)) d = 0;
            ((void (*)(id, SEL, double))(void *) objc_msgSend)((id)model, meta->_setter, d);
        } break;
        case KPLEncodingTypeLongDouble: {
            long double d = num.longLongValue;
            if (isnan(d) || isinf(d)) d = 0;
            ((void (*)(id, SEL, long double))(void *) objc_msgSend)((id)model, meta->_setter, (long double)d);
        } // break; commented for code coverage in next line 
            
        default: break;
    }
    
}

/**
 Set value to model with a property meta.
 
 @discussion Caller should strong reference to the parameters before this function returns.
 
 
 */
static void ModelSetValueForProperty(__unsafe_unretained id model, __unsafe_unretained id value, _KPLModelPropertyMeta *meta) {
    if (meta->_isCNumber) {
        NSNumber *num = KPLNSNumberCreateFromID(value);
        ModelSetNumberToProperty(model, num, meta);
        if (num != nil) [num class];  // hold the number
    } else if (meta->_nsType) {
        if (value == (id)kCFNull) {
            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (id)nil);
        } else {
            switch (meta->_nsType) {
                case KPLEncodingTypeNSString:
                case KPLEncodingTypeNSMutableString: {
                    if ([value isKindOfClass:[NSString class]]) {
                        if (meta->_nsType == KPLEncodingTypeNSString) {
                            ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                        } else {
                            ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, ((NSString *)value).mutableCopy);
                        }
                    } else if ([value isKindOfClass:[NSNumber class]]) {
                        ((void(*)(id, SEL, id)) objc_msgSend)((id)model, meta->_setter, (meta->_nsType == KPLEncodingTypeNSString) ? ((NSNumber *)value).stringValue : ((NSNumber *)value).mutableCopy);
                    } else if ([value isKindOfClass:[NSData class]]) {
                        NSMutableString *string = [[NSMutableString alloc] initWithData:value encoding:NSUTF8StringEncoding];
                        ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, string);
                    } else if ([value isKindOfClass:[NSURL class]]) {
                        ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (meta->_nsType == KPLEncodingTypeNSString) ? ((NSURL *)value).absoluteString : ((NSURL *)value).absoluteString.mutableCopy);
                    } else if ([value isKindOfClass:[NSAttributedString class]]) {
                        ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (meta->_nsType == KPLEncodingTypeNSString) ? ((NSAttributedString *)value).string : ((NSAttributedString *)value).string.mutableCopy);
                    }
                } break;
                    
                case KPLEncodingTypeNSValue:
                case KPLEncodingTypeNSNumber:
                case KPLEncodingTypeNSDecimalNumber: {
                    if (meta->_nsType == KPLEncodingTypeNSNumber) {
                        ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, KPLNSNumberCreateFromID(value));
                    } else if (meta->_type == KPLEncodingTypeNSDecimalNumber) {
                        if ([value isKindOfClass:[NSDecimalNumber class]]) {
                            ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                        } else if ([value isKindOfClass:[NSNumber class]]) {
                            NSDecimalNumber *decNum = [NSDecimalNumber decimalNumberWithDecimal:[((NSNumber *)value) decimalValue]];
                            ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, decNum);
                        } else if ([value isKindOfClass:[NSString class]]) {
                            NSDecimalNumber *decNum = [NSDecimalNumber decimalNumberWithString:value];
                            NSDecimal dec = decNum.decimalValue;
                            if (dec._length == 0 && dec._isNegative) {
                                decNum = nil; // NaN
                            }
                            ((void(*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, decNum);
                        }
                    } else { // KPLEncodingTypeNSValue
                        if ([value isKindOfClass:[NSValue class]]) {
                            ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                        }
                    }
                } break;
                    
                case KPLEncodingTypeNSData:
                case KPLEncodingTypeNSMutableData: {
                    if ([value isKindOfClass:[NSData class]]) {
                        if (meta->_nsType == KPLEncodingTypeNSData) {
                            ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                        } else {
                            NSMutableData *data = ((NSData *)value).mutableCopy;
                            ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, data);
                        }
                    } else if ([value isKindOfClass:[NSString class]]) {
                        NSData *data = [(NSString *)value dataUsingEncoding:NSUTF8StringEncoding];
                        if (meta->_nsType == KPLEncodingTypeNSMutableData) {
                            data = ((NSData *)data).mutableCopy;
                        }
                        ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, data);
                    }
                } break;
                    
                case KPLEncodingTypeNSDate: {
                    if ([value isKindOfClass:[NSDate class]]) {
                        ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                    } else if ([value isKindOfClass:[NSString class]]) {
                        ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, KPLNSDateFromString(value));
                    }
                } break;
                    
                case KPLEncodingTypeNSURL: {
                    if ([value isKindOfClass:[NSURL class]]) {
                        ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                    } else if ([value isKindOfClass:[NSString class]]) {
                        NSCharacterSet *set = [NSCharacterSet whitespaceCharacterSet];
                        NSString *str = [value stringByTrimmingCharactersInSet:set];
                        if (str.length == 0) {
                            ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, nil);
                        } else {
                            ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, [NSURL URLWithString:str]);
                        }
                    }
                } break;
                   
                case KPLEncodingTypeNSArray:
                case KPLEncodingTypeNSMutableArray: {
                    if (meta->_genericCls) {
                        NSArray *valueArr = nil;
                        if ([value isKindOfClass:[NSArray class]])
                            valueArr = value;
                        else if ([value isKindOfClass:[NSSet class]])
                            valueArr = ((NSSet *)value).allObjects;
                        
                        if (valueArr) {
                            NSMutableArray *objectArr = [NSMutableArray new];
                            for (id one in valueArr) {
                                if ([one isKindOfClass:meta->_genericCls]) {
                                    [objectArr addObject:one];
                                } else if ([one isKindOfClass:[NSDictionary class]]) {
                                    Class cls = meta->_genericCls;
                                    if (meta->_hasCustomClassFromDictionary) {
                                        cls = [cls modelCustomClassForDictionary:one];
                                        if (!cls) cls = meta->_genericCls;  // for xcode code coverage
                                    }
                                    NSObject *newOne = [cls new];
                                    [newOne kpl_modelSetWithDictionary:one];
                                    if (newOne) [objectArr addObject:newOne];
                                }
                            }
                            ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, objectArr);
                        }
                    } else {
                        if ([value isKindOfClass:[NSArray class]]) {
                            if (meta->_nsType == KPLEncodingTypeNSArray) {
                                ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                            } else {
                                ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, ((NSArray *)value).mutableCopy);
                            }
                        } else if ([value isKindOfClass:[NSSet class]]) {
                            if (meta->_nsType == KPLEncodingTypeNSArray) {
                                ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, ((NSSet *)value).allObjects);
                            } else {
                                ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, ((NSSet *)value).allObjects.mutableCopy);
                            }
                        }
                    }
                } break;
                   
                case KPLEncodingTypeNSDictionary:
                case KPLEncodingTypeNSMutableDictionary: {
                    if ([value isKindOfClass:[NSDictionary class]]) {
                        if (meta->_genericCls) {
                            NSMutableDictionary *dic = [NSMutableDictionary new];
                            [((NSDictionary *)value) enumerateKeysAndObjectsUsingBlock:^(NSString *oneKey, id oneValue, BOOL *stop) {
                                if ([oneValue isKindOfClass:[NSDictionary class]]) {
                                    Class cls = meta->_genericCls;
                                    if (meta->_hasCustomClassFromDictionary) {
                                        cls = [cls modelCustomClassForDictionary:oneValue];
                                        if (!cls) cls = meta->_genericCls; // for xcode code coverage
                                    }
                                    NSObject *newOne = [cls new];
                                    [newOne kpl_modelSetWithDictionary:(id)newOne];
                                    if (newOne) dic[oneKey] = newOne;
                                }
                            }];
                            ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, dic);
                        } else {
                            if (meta->_nsType == KPLEncodingTypeNSDictionary) {
                                ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                            } else {
                                ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, ((NSDictionary *)value).mutableCopy);
                            }
                        }
                    } 
                } break;
                    
                case KPLEncodingTypeNSSet:
                case KPLEncodingTypeNSMutableSet: {
                    NSSet *valueSet = nil;
                    if ([value isKindOfClass:[NSArray class]]) valueSet = [NSMutableSet setWithArray:value];
                    else if ([value isKindOfClass:[NSSet class]])
                        valueSet = ((NSSet *)value);
                    
                    if (meta->_genericCls) {
                        NSMutableSet *set = [NSMutableSet new];
                        for (id one in valueSet) {
                            if ([one isKindOfClass:meta->_genericCls]) {
                                [set addObject:one];
                            } else if ([one isKindOfClass:[NSDictionary class]]) {
                                Class cls = meta->_genericCls;
                                if (meta->_hasCustomClassFromDictionary) {
                                    cls = [cls modelCustomClassForDictionary:one];
                                    if (!cls) cls = meta->_genericCls; // for xcode code coverage
                                }
                                NSObject *newOne = [cls new];
                                [newOne kpl_modelSetWithDictionary:one];
                                if (newOne) [set addObject:newOne];
                            }
                        }
                        ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, set);
                    } else {
                        if (meta->_nsType == KPLEncodingTypeNSSet) {
                            ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, valueSet);
                        } else {
                            ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, ((NSSet *)valueSet).mutableCopy);
                        }
                    }
                    
                } // break; command for code coverage in next line
                    
                default: break;
            }
        }
    } else {
        BOOL isNull = (value == (id)kCFNull);
        switch (meta->_type & KPLEncodingTypeMask) {
                
            case KPLEncodingTypeObject: {
                Class cls = meta->_genericCls ?: meta->_cls;
                if (isNull) {
                    ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (id)nil);
                } else if ([value isKindOfClass:cls] || !cls) {
                    ((void(*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (id)value);
                } else if ([value isKindOfClass:[NSDictionary class]]) {
                    NSObject *one = nil;
                    if (meta->_getter) {
                        one = ((id (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter);
                    }
                    if (one) {
                        [one kpl_modelSetWithDictionary:value];
                    } else {
                        if (meta->_hasCustomClassFromDictionary) {
                            cls = [cls modelCustomClassForDictionary:value] ?: cls;
                        }
                        one = [cls new];
                        [one kpl_modelSetWithDictionary:value];
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (id)one);
                    }
                    
                }
            } break;
                
            case KPLEncodingTypeClass: {
                if (isNull) {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (Class)NULL);
                } else {
                    Class cls = nil;
                    if ([value isKindOfClass:[NSString class]]) {
                        cls = NSClassFromString(value);
                        if (cls) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (Class)value);
                        }
                    } else {
                        cls = object_getClass(value);
                        if (cls) {
                            if (class_isMetaClass(cls)) {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (Class)value);
                            }
                        }
                    }
                }
            } break;
                
            case KPLEncodingTypeSEL: {
                if (isNull) {
                    ((void (*)(id, SEL, SEL))(void *) objc_msgSend)((id)model, meta->_setter, (SEL)NULL);
                } else if ([value isKindOfClass:[NSString class]]) {
                    SEL sel = NSSelectorFromString(value);
                    if (sel) ((void (*)(id, SEL, SEL))(void *) objc_msgSend)((id)model, meta->_setter, (SEL)sel);
                }
            } break;
            case KPLEncodingTypeBlock: {
                if (isNull) {
                    ((void (*)(id, SEL, void(^)()))(void *) objc_msgSend)((id)model, meta->_setter, (void (^)())NULL);
                } else if ([value isKindOfClass:KPLNSBlockClass()]) {
                    ((void (*)(id, SEL, void (^)()))(void *) objc_msgSend)((id)model, meta->_setter, (void (^)())value);
                }
            } break;
                
            case KPLEncodingTypeStruct:
            case KPLEncodingTypeUnion:
            case KPLEncodingTypeCArray: {
                if ([value isKindOfClass:[NSValue class]]) {
                    const char *valueType = ((NSValue *)value).objCType;
                    const char *metaType = meta->_info.typeEncoding.UTF8String;
                    if (valueType && metaType && strcmp(valueType, metaType)) {
                        [model setValue:value forKey:meta->_name];
                    }
                }
            } break;
                
            case KPLEncodingTypePointer:
            case KPLEncodingTypeCString: {
                if (isNull) {
                    ((void (*)(id, SEL, void *))(void *) objc_msgSend)((id)model, meta->_setter, (void *)NULL);
                } else if ([value isKindOfClass:[NSValue class]]) {
                    NSValue *nsValue = value;
                    if (nsValue.objCType && strcmp(nsValue.objCType, "^v") == 0) {
                        ((void (*)(id, SEL, void *))(void *) objc_msgSend)((id)model, meta->_setter, nsValue.pointerValue);
                    }
                }
            } // break; command for code coverage in next line
                
            default: break;
        }
    }
}


typedef struct {
    void *modelMeta;    ///< _KPLModelMeta
    void *model;        ///< id (self)
    void *dictionary;   ///< NSDictionary (json)
} ModelSetContext;

/**
 Apply function for dictionary, to set the key-value pair to model.
 
 @param _key        should not be nil, NSString.
 @param _value      should not be nil.
 @param _context    _context.modelMeta and _context.model should not be nil.
 */
static void ModelSetWithDictionaryFunction(const void *_key, const void *_value, void *_context) {
    ModelSetContext *context = _context;
    __unsafe_unretained _KPLModelMeta *meta = (__bridge _KPLModelMeta *)(context->modelMeta);
    __unsafe_unretained _KPLModelPropertyMeta *propertyMeta = [meta->_mapper objectForKey:(__bridge id)(_key)];
    __unsafe_unretained id model = (__bridge id)(context->model);
    while (propertyMeta) {
        if (propertyMeta->_setter) {
            ModelSetValueForProperty(model, (__bridge __unsafe_unretained id)_value, propertyMeta);
        }
        propertyMeta = propertyMeta->_next;
    };
}


static void ModelSetWithPropertyMetaArrayFunction(const void *_propertyMeta, void *_context) {
    ModelSetContext *context = _context;
    __unsafe_unretained NSDictionary *dictionary = (__bridge NSDictionary *)(context->dictionary);
    __unsafe_unretained _KPLModelPropertyMeta *propertyMeta = (__bridge _KPLModelPropertyMeta *)(_propertyMeta);
    if (!propertyMeta->_setter) return;
    id value = nil;
    
    if (propertyMeta->_mappedToKeyArray) {
        value = KPLValueForMultiKeys(dictionary, propertyMeta->_mappedToKeyArray);
    } else if (propertyMeta->_mappedToKeyPath) {
        value = KPLValueForKeyPath(dictionary, propertyMeta->_mappedToKeyPath);
    } else {
        value = [dictionary objectForKey:propertyMeta->_mappedToKey];
    }
    
    if (value) {
        __unsafe_unretained id model = (__bridge id)(context->model);
        ModelSetValueForProperty(model, value, propertyMeta);
    }
}

static id ModelToJSONNObjectRecursive(NSObject *model) {
    if (!model || model == (id)kCFNull) return model;
    if ([model isKindOfClass:[NSString class]]) return model;
    if ([model isKindOfClass:[NSNumber class]]) return model;
    if ([model isKindOfClass:[NSDictionary class]]) {
        if ([NSJSONSerialization isValidJSONObject:model]) return model;
        NSMutableDictionary *newDic = [NSMutableDictionary new];
        [((NSDictionary *)model) enumerateKeysAndObjectsUsingBlock:^(NSString *key, id  obj, BOOL *stop) {
            NSString *stringKey = [key isKindOfClass:[NSString class]] ? key : key.description;
            if (!stringKey) return;
            id jsonObj = ModelToJSONNObjectRecursive(model);
            newDic[stringKey] = jsonObj;
        }];
        return newDic;
    }
    if ([model isKindOfClass:[NSSet class]]) {
        NSArray *array = ((NSSet *)model).allObjects;
        if ([NSJSONSerialization isValidJSONObject:array]) return array;
        NSMutableArray *newArray = [NSMutableArray array];
        for (id obj in array) {
            if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]) {
                [newArray addObject:obj];
            } else {
                id jsonObj = ModelToJSONNObjectRecursive(obj);
                if (jsonObj && jsonObj != (id)kCFNull) [newArray addObject:jsonObj];
            }
        }
        return newArray;
    }
    if ([model isKindOfClass:[NSArray class]]) {
        if ([NSJSONSerialization isValidJSONObject:model]) return model;
        NSMutableArray *newArray = [NSMutableArray new];
        for (id obj in (NSArray *)model) {
            if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]) {
                [newArray addObject:obj];
            } else {
                id jsonObj = ModelToJSONNObjectRecursive(obj);
                if (jsonObj && jsonObj != (id)kCFNull) [newArray addObject:jsonObj];
            }
        }
        return newArray;
    }
    
    if ([model isKindOfClass:[NSURL class]]) return ((NSURL *)model).absoluteString;
    if ([model isKindOfClass:[NSAttributedString class]]) return ((NSAttributedString *)model).string;
    if ([model isKindOfClass:[NSDate class]]) return [KPLISODateFormatter() stringFromDate:(id)model];
    if ([model isKindOfClass:[NSData class]]) return nil;
    
    _KPLModelMeta *modelMeta = [_KPLModelMeta metaWithClass:[model class]];
    if (!modelMeta || modelMeta->_keyMappedCount == 0) return nil;
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:64];
    __unsafe_unretained NSMutableDictionary *dic = result; // avoid retain and release in block
    [modelMeta->_mapper enumerateKeysAndObjectsUsingBlock:^(NSString *propertyMappedKey, _KPLModelPropertyMeta *propertyMeta, BOOL *stop) {
        if (!propertyMeta->_getter) return;
        
        id value = nil;
        if (propertyMeta->_isCNumber) {
            value = ModelCreateNumberFromProperty(model, propertyMeta);
        } else if (propertyMeta->_nsType) {
            id v = ((id (*)(id, SEL))(void *) objc_msgSend)((id)model, propertyMeta->_getter);
            value = ModelToJSONNObjectRecursive(v);
        } else {
            switch (propertyMeta->_type & KPLEncodingTypeMask) {
                case KPLEncodingTypeObject: {
                    id v = ((Class (*)(id, SEL))(vod *) objc_msgSend)((id)model)
                } break;
                    
                default:
                    break;
            }
        }
    }];
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
