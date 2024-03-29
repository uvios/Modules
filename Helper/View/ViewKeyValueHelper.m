#import "ViewKeyValueHelper.h"

#import "ColorHelper.h"
#import "RectHelper.h"
#import "FrameTranslater.h"

#import <objc/runtime.h>



#define TYPE_UICOLOR            @"UIColor"
#define TYPE_UIIMAGE            @"UIImage" 



#define TYPE_CGCOLOR            @"CGColor"
#define TYPE_CGRECT             @"CGRect"
#define TYPE_CGPOINT            @"CGPoint"
#define TYPE_CGSIZE             @"CGSize"



#define TYPE_CATRANSFORM3D      @"CATransform3D"
#define TYPE_CGAFFINETRANSFORM  @"CGAffineTransform"




@implementation ViewKeyValueHelper
{
    KeyValueCodingTranslator translateValueHandler;
}


-(KeyValueCodingTranslator) translateValueHandler
{
    return translateValueHandler;
}

-(void) setTranslateValueHandler:(KeyValueCodingTranslator)handler
{
    translateValueHandler = handler;
}



#pragma mark - Public Methods

-(void) setValues: (NSDictionary*)config object:(NSObject*)object
{
    NSDictionary* propertiesTypes = [ViewKeyValueHelper getClassPropertieTypes: [object class]];
    for (NSString* key in config) {
        id value = config[key];
        [self setValue: value keyPath:key object:object propertiesTypes:propertiesTypes];
    }
}


-(void) setValue:(id)value keyPath:(NSString*)keyPath object:(NSObject*)object
{
    [self setValue:value keyPath:keyPath object:object propertiesTypes:nil];
}


// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CoreAnimation_guide/Key-ValueCodingExtensions/Key-ValueCodingExtensions.html

-(void) setValue:(id)value keyPath:(NSString*)keyPath object:(NSObject*)object propertiesTypes:(NSDictionary*)propertiesTypes
{
    if (!propertiesTypes) propertiesTypes = [ViewKeyValueHelper getClassPropertieTypes: [object class]];

    NSString* propertyType = propertiesTypes[keyPath];
    
    id translatedValue = [ViewKeyValueHelper translateValue: value type:propertyType];
    
    if (translateValueHandler) {
        translatedValue = translateValueHandler(object, value, propertyType, keyPath);
    }
    
    [object setValue:translatedValue forKeyPath: keyPath];
}





#pragma mark - Class Methods

+(ViewKeyValueHelper*) sharedInstance
{
    static ViewKeyValueHelper* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ViewKeyValueHelper alloc] init];
    });
    return sharedInstance;
}

// http://imapisit.com/post/18508442936/programmatically-get-property-name-type-value-with
// if you want a list of what will be returned for these primitives, search online for
// "objective-c" "Property Attribute Description Examples"
// apple docs list plenty of examples of what you get for int "i", long "l", unsigned "I", struct, etc.
// http://blog.csdn.net/icmmed/article/details/17298961
// http://stackoverflow.com/questions/16861204/property-type-or-class-using-reflection
// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html

+(NSMutableDictionary *)getClassPropertieTypes:(Class)clazz
{
    if (clazz == NULL) return nil;
    NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
    
    while (clazz != NULL) {
        
        unsigned int count, i;
        
        objc_property_t *properties = class_copyPropertyList(clazz, &count);
        
        for (i = 0; i < count; i++) {
            objc_property_t property = properties[i];
            const char *name = property_getName(property);
            const char *attributes = property_getAttributes(property);
            
            NSString *propertyName = [NSString stringWithUTF8String:name];
            
            NSString* propertyAttributes = [NSString stringWithUTF8String:attributes];              // "T{CGPoint=ff},N"
            NSArray * attributesArray = [propertyAttributes componentsSeparatedByString:@","];
            NSString * typeAttribute = [attributesArray firstObject];                               // "T{CGPoint=ff}"
            NSString * propertyType = [typeAttribute substringFromIndex:1];                         // "{CGPoint=ff}"
            
            [results setObject:propertyType forKey:propertyName];                                   // Cause @encode(CGPoint) = "{CGPoint=ff}"
        }
        free(properties);
        
        clazz = [clazz superclass];
    }
    return results;
}



+(NSArray *)getClassPropertiesNames: (Class)clazz
{
    NSMutableArray* results = [NSMutableArray array];
    
    unsigned int count, i;
    objc_property_t *properties = class_copyPropertyList(clazz, &count);
    
    for (i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:name];
        
        [results addObject: propertyName];
    }
    
    return results;
}









+(id) translateValue:(id)value type:(NSString*)type
{
    if (! type) return value;
    
    id result = value;
    
    const char* rawType = [type UTF8String];
    
    if (strcmp(rawType, @encode(CGColorRef)) == 0) {
        
        result = (id)[ColorHelper parseColor: value].CGColor;
        
    } else if (strcmp(rawType, @encode(CGRect)) == 0) {
        
        CGRect rect = [RectHelper parseRect: value];
        result = [NSValue valueWithCGRect: CanvasCGRect(rect)];
        
    } else if (strcmp(rawType, @encode(CGPoint)) == 0) {
        
        CGPoint point = [RectHelper parsePoint: value];
        result = [NSValue valueWithCGPoint: CanvasCGPoint(point)];
        
    } else if (strcmp(rawType, @encode(CGSize)) == 0) {
        
        CGSize size = [RectHelper parseSize: value];
        result = [NSValue valueWithCGSize: CanvasCGSize(size)];
        
    } else if ([self isType:TYPE_UICOLOR keyPathType:type]) {
        
        result = (id)[ColorHelper parseColor: value];
        
    } else if ([self isType:TYPE_UIIMAGE keyPathType:type]) {
        
        // for image path or name
        if ([value isKindOfClass:[NSString class]]) {
            result = [self getUIImageByPath: value];
        }
        
    }
    
    return result;
}


+(UIImage*) getUIImageByPath: (NSString*)path
{
    if ([path hasPrefix:@"/"]) {
        return [UIImage imageWithContentsOfFile: path];
        
    } else if ([path hasPrefix:@"~"]) {
        return [UIImage imageWithContentsOfFile: [path stringByReplacingOccurrencesOfString:@"~" withString:NSHomeDirectory()]];
        
    } else {
        return [UIImage imageNamed: path];
    }
    return nil;
}


+(NSString*) getResourcePath: (NSString*)path
{
    NSString* result = path;
    if ([path hasPrefix:@"/"]) {
        // do nothing
        
    } else if ([path hasPrefix:@"~"]) {
        result = [path stringByReplacingOccurrencesOfString:@"~" withString:NSHomeDirectory()];
        
    } else {
        result = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: path];
        
    }
    
    return result;
}


+(BOOL) isType:(NSString*)type keyPathType:(NSString*)keyPathType
{
    if (! keyPathType) return false;
    
    return [keyPathType rangeOfString:type].location != NSNotFound;
}




@end
