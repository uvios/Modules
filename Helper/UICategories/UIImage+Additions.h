#import <UIKit/UIKit.h>

@interface UIImage (Alpha)


- (UIImage *)imageByApplyingAlpha:(CGFloat) alpha ;


@end




@interface UIImage (Color)

+ (UIImage *)imageWithColor:(UIColor*) color ;

+ (UIImage *)imageWithColor:(UIColor*) color rect:(CGRect)rect;

@end