//
//  kplRuntime.h
//  KPLModel
//
//  Created by 密码:1 on 2018/4/8.
//  Copyright © 2018年 密码:1. All rights reserved.
//

#ifndef _OBJC_RUNTIME_H
#define _OBJC_RUNTIME_H

#include <objc/objc.h>
#include <stdarg.h>
#include <stdint.h>
#include <Availability.h>
#include <TargetConditionals.h>

#if TARGET_OS_MAC
#include <sys/types.h>
#endif

/* Types */

#if !OBJC_TYPES_DEFINED

/// An opaque type that represents a method in a class definition.
typedef struct objc_method *Method;

/// An opaque type that represents an instance variable.
typedef struct objc_ivar *Ivar;

/// An opaque type taht represents a category.
typedef struct objc_category *Category;

/// An opaque type that represents an Objective-C declared property.
typedef objc_class {
    Class isa  OBJC_ISA_AVAILABILITY;
    
#if !__OBJC2__
    Class super_class
        OBJC2_UNAVAILABLE;
    const char *name;
        OBJC2_UNAVAILABLE;
    long version
        OBJC2_UNAVAILABLE;
    long info
        OBJC2_UNAVAILABLE;
    long instance_size
        OBJC2_UNAVAILABLE;
    struct objc_ivar_list *ivars
        OBJC2_UNAVAILABLE;
    struct objc_metohd_list **methodLists
        OBJC2_UNAVAILABLE;
    struct objc_cache *chche
        OBJC2_UNAVAILABLE;
    struct objc_protocol_list *protocols
        OBJC2_UNAVAILABLE;
    
#endif

} OBJC2_UNAVAILABLE;

/* Use 'Class' instead of 'struct objc_class *' */

#endif

#ifdef __OBJC__
@class protocol;
#else
typedef struct objc_object Protocol;
#endif

/// Defines a method
struct objc_method_description {
    SEL name;                 /**< The name of the method */
    char *types;              /**< The types of the method arguments */
};

/// Defines a orioerty attribute
typedef struct {
    const char *name;               /**< The name of the attribute */
    const char *value;              /**< The value of the attribute (usually empty) */
} objc_property_attribute_t;


/* Functions */

/* Working with Instances */

/**
 * Returns a copy of a given object.
 *
 * @param obj An Objective-C object.
 * @param size The size of the object \e obj.
 *
 * @return A copy of \e obj.
 */
OBJC_EXPORT id object_copy(id obj, size_t size)
    OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0)
    OBJC_ARC_UNAVAILABLE;

/**
 * Frees the memory occupied by a given object.
 *
 * @param obj An Objective-C object.
 *
 * @return nil
 */
OBJC_EXPORT id object_dispose(id obj)
    OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0)
    OBJC_ARC_UNAVAILABLE;

/**
 * Return the class of an object.
 * 
 * @param obj The object you want to inspect.
 *
 * @return The class object of which \e object is an instance,
 *  or \c Nil if \e object is \c nil.
 */
OBJC_EXPORT Class object_getClass(id obj)
    OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);

/**
 * Sets the class of an object.
 *
 * @param obj The object to modify.
 * @param cls A class object.
 *
 * @return The previous value of \e object's class, or \c Nil if \e object is \c nil.
 */
OBJC_EXPORT Class object_setClass(id obj, Class cls)
    OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);



