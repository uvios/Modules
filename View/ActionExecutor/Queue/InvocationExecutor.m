#import "InvocationExecutor.h"

@implementation InvocationExecutor

-(void)execute:(NSDictionary *)config objects:(NSArray *)objects values:(NSArray *)values times:(NSArray *)times durationsRep:(NSMutableArray *)durationsQueue beginTimesRep:(NSMutableArray *)beginTimesQueue
{
    for (int i = 0; i < objects.count; i++) {
        
        UIView* view = [objects objectAtIndex: i];
        id object = config[@"object"] ? [view valueForKey: config[@"object"]] : view ;
        
        NSString* selectorString = config[@"selector"];
        SEL selector = NSSelectorFromString(selectorString);
        NSArray* values = config[@"values"];
        
        if ([object respondsToSelector:selector]) {
            NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[object methodSignatureForSelector:selector]];
            [invocation setTarget: object];
            [invocation setSelector: selector];
            
            // ... set arguments
            for (int i = 0; i < values.count; i++) {
                id value = values[i];
                [invocation setArgument: &value atIndex:2 + i]; // arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
            }
            
            [invocation retainArguments];
            [invocation invoke];
        }
        
    }
}

@end
