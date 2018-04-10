//
//  NSObject+KPLModel.h
//  KPLModel
//
//  Created by 密码:1 on 2018/4/8.
//  Copyright © 2018年 密码:1. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Provide same data-model method:
 
 * Convert json to any object, or convert any object to json.
 * Set object properties with a key-value dictionary (like KVC)
 * Implementations of 'NSCoding', 'NSCopying', 'hash-' and 'isEqual:'.
 
 See 'KPLModel' protocol for custom methods.
 
 
 Sample Code:
    
    *********************** json convertor ***********************
 
 @code 
    @interface KPLAuther : NSObject
    @property (nonatomic, strong) NSString *name;
    @property (nonatomic, assign) NSDate *birthday;
    @end
    @implementation KPLAuther
    @end
 
    @interface KPLBook : NSObject
    @property (nonatomic, copy) NSString *name;
    @property (nonatomic, assign) NSUInteger pages;
    @property (nonatomic, strong) KPLAuther *auther;
    @implementation KPLBook
    @end
 
    int main() {
        //  create model from json
        KPLBook *book = [KPLBook kpl_modelWithJSON:@{\"name\":\"Harry Potter\", \"pages\" : 256, \"author\" : {\"name\" : \"J.K.Rowling\", \"birthday\" : \"1965-07-31\"}}];
        
        // convert model to json
        NSString *json = [book kpl_modelToJSONString];
        // {"auther":{"name":"J.K.rowling", "birthday":"1965-07-31"}, "name":"Harry Potter", "pages":256}
 
 @endcode
    *********************** Coding/Copying/hash/equal ***********************
 
 @code
        @interface KPLShadow : NOSbject <NSCoding, NSCopying>
        @property (nonatomic, copy) NSString *name;
        @property (nonatomic, assign) CGSize size;
        @implementation KPLShadow
        - (void)encodeWithCoder:(NSCoder *)aCoder { [self kpl_modelEncodeWithCoder:aCoder]; }
        - (id)initWithCoder:(NSCoder *)aDecoder { self = [super init]; return [self kpl_modelInitWithCoder:aDecoder]; }
        - (id)copyWithZone:(NSZone *)zone { return [self kpl_modelCopy]; }
        - (NSUInteger)hash { return [self kpl_modelHash]; }
        - (BOOL)isEqual:(id)object { return [self kpl_modelIsEqual:object]; }
        @end
 @endcode
 */
@interface NSObject (KPLModel)

/**
 Creates and returns a new instance of the reciever from a json.
 This method is thread-safe.
 
 @param json  A json object in 'NSDictionary', 'NSString' or 'NSData'.
 @return A new instance created from the json, or nil if an error occurs.
 */
+ (nullable instancetype)kpl_modelWithJSON:(id)json;

/**
 Creates and returns a new instance of the reciever from a key-value dictionary
 This method is thread-safe
 
 @prarm dictionary  A key-value dictionary mapped to the instance's properties.
 Any invalid key-value pair in dictionary will be ignored.
 
 @return A new instance created from the dictionary, or nil if an error occurs.
 
 @discussion The key in 'dictionary' will mapped to the reciever's property name,
 and the value will set to the property. If the value's type does not match the property, this method will try to convert the value based on these rules.
    
    'NSString' or 'NSNumber' -> c number, such as BOOL, int, long, float, NSUInteger...
    'NSString' -> NSDate, parsed with format "yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd HH:mm:ss" or "yyyy-MM-dd".
    'NSString' -> NSURL.
    'NSValue' -> struct or union, such as CGRect, CGSize, ...
    'NSString' -> SEL, Class.
 */
+ (nullable instancetype)kpl_modelWithDictionary:(NSDictionary *)dictionary;

/**
 Set the reciever's properties with a json object.
 
 @discussion Any invalid data in json will be ignored.
 
 @param json A json object of 'NSDictionary', 'NSString' or 'NSData', mapped to the reciever's properties.
 
 @return Whether succeed.
 */
- (BOOL)kpl_modelSetWithJSON:(id)json;

/**
 Set the reciever's properties with a key-value dictionary.
 
 @param dic A key-value dictionary mapped to the receiver's properties.
 Any invalid key-value pair in dictionary will be ignored.
 
 @discussion The key in 'dictionary' will mapped to the reciever's property name,
 and the value will set to the property. If the value's type doesn't match the property, this method will try to convert the value based on these rules:
 
    'NSString', 'NSNumber' -> c number, such as BOOL, int, long, fkiat, NSUinteger...
    'NSString' -> NSDate, parsed with format "yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd HH:mm:ss" or "yyyy-MM-dd".
    'NSString' -> NSURL.
    'NSValue' -> struct or union, such as CGRect, CGSize, ...
    'NSString' -> SEL, Class.
 
 @return Whether succeed.
 */
- (BOOL)kpl_modelSetWithDictionary:(NSDictionary *)dic;

/**
 Generate a json object from the receiver's properties.
 
 @return A json object in 'NSDictionary' or 'NSArray', or nil if an error occurs.
 See [NSJSONSerialization isValidJSONObject] for more information.
 
 @discussion Any of the invalid property is ignored.
 If the reciver is 'NSArray', 'NSDictionary' or 'NSSet', it just convert
 the inner object to json object.
 */
- (nullable id)kpl_modelToJSONObject;

/**
 Generate a json string's data from the receiver's properties.
 
 @reutrn A json string's data, or nil if an error occurs.
 
 @discussion Any of the invalid property is ignored.
 If the reciver is 'NSArray', 'NSDictionary' or 'NSSet', it will also convert the inner object to json string.
 */
- (nullable NSData *)kpl_modelToJSONData;


/**
 Generate a json string from the receiver's properties.
 
 @return A json string, or nil if an error occurs.
 
 @discussion Any of the invalid property is ignored.
 If the receiver is 'NSArray', 'NSDictionary' or 'NSSet', it will also convert the inner object to json string.
 */
- (nullable NSString *)kpl_modelToJSONString;

/**
 Copy a instance with the receiver's properties.
 
 @return A copied instance, or nil if an error occurs.
 */
- (nullable id)kpl_modelCopy;

/**
 Encode the receiver's properties to a coder.
 
 @param aCoder An archiver object.
 */
- (void)kpl_modelEncodeWithCoder:(NSCoder *)aCoder;

/**
 Decode the receiver's properties from a decoder.
 
 @param aDecoder  An archiver object.
 
 @return self
 */
- (id)kpl_modelInitWithCoder:(NSCoder *)aDecoder;


/**
 Get a hash code with the receiver's properties.
 
 @return Hash code.
 */
- (NSUInteger)kpl_modelHash;

/**
 Compares the receiver with anthor object for equality, based on properties.
 
 @param model  Another object.
 
 @return 'YES' if the receiver is equal to the object, otherwise 'NO'
 */
- (BOOL)kpl_modelIsEqual:(id)model;

/**
 Description method for debugging purposes based on properties.
 
 @return A string that describes the contents of the receiver.
 */
- (NSString *)kpl_modelDescription;

@end

/**
 Provide some data-model method for NSArray.
 */
@interface NSArray (KPLModel)

/**
 Creates and returns an array from a json-array.
 This method is thread-safe.
 
 @param cls The instance's class in array.
 @oaran json A json array of 'NSArray', 'NSString' or 'NSData'.
    Example : [{"name":"Mary"}, {"name":"Joe"}]
 
 @return A array, or nil if an error occurs.
 */
+ (nullable NSArray *)kpl_modelArrayWithClass:(Class)cls json:(id)json;

@end

/**
 Provide some data-model method for NSDictionary
 */
@interface NSDictionary (KPLModel)

/**
 Creates and returns a dictionary from a json.
 This method is thread-safe.
 
 @param cls  The value instance's class in dictionary.
 @param json A json dictionary of 'NSDictionary', 'NSString' or 'NSData'.
    Example: {"user1":{"name":"Mary"}, "user2":{"name":"Joe"}}
 
 @return A dictionary, or nil if an error occurs.
 */
+ (nullable NSDictionary *)kpl_modelDictionaryWithClass:(Class)cls json:(id)json;
@end


/**
 If the default model transform does not fit to your model class, implement one or more method in this protocol to change the default key-value transform process.
 There's no need to add '<KPLModel>' to your class header.
 */
@protocol KPLModel <NSObject>
@optional

/**
 Custom property mapper
 
 @discussion If the key in JSON/Dictionary does not match to the model's property name,
 implements this method and returns the additional mapper.
 
 Example:
 
    json:
        {
            "n" : "Harry Pottery",
            "p" : 256,
            "ext" : {
                "desc" : "A book written by J.K.rowling."
            },
            "ID" : 100010
        }
    model:
    @code
        @interface KPLBook : NSObject
        @property NSString *name;
        @property NSInteger page;
        @property NSString *desc;
        @property NSString *bookID;
        @end
        @implemention
        + (NSDictionary *)modelCustomPropertyMapper {
            return @{
            @"name" : @"n",
            @"page" : @"p",
            @"desc" : @"ext.desc",
            @"bookID" : @[@"id", @"ID", @"book_id"]
            };
        }
        @end
    @encode
 
 @return A custom mapper for properties.
 */
+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper;

/**
 The gengric class mapper for container properties.
 
 @discussion If the property is container object, such as NSArray/NSSet/NSDictionary,
 implements this method and returns a property->class mapper, tells which kind of object will be add to the array/set/dictionary.
 
    Example:
    @code
        @class KPLShadow, KPLBorder, KPLAttachment;
        
        @interface KPLAttributes : NSObject
        @property NSString *name;
        @property NSArray *shadows;
        @property NSSet *borders;
        @property NSDictionary *attachments;
        @end
        @implementation KPLAttributes
        + (NSDictionary *)modelContainerPropertyGenericClass {
            return @{
                @"shadows" : [KPLShadow class],
                @"borders" : KPLBorder.class,
                @"attachments" : @"KPLAttachment"
            };
        }
        @end
    @encode
 
 @return A class mapper.
 */
+ (nullable NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass;

@end

NS_ASSUME_NONNULL_END
