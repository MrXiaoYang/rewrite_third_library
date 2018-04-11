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
}


@end

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
