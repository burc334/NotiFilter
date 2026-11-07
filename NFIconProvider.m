#import "NFIconProvider.h"

@interface UIImage (NFPrivateIcons)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier
                                               format:(int)format
                                                scale:(CGFloat)scale;
@end

@implementation NFIconProvider

+ (UIImage *)iconForBundleIdentifier:(NSString *)bundleIdentifier {
    if (bundleIdentifier.length == 0) {
        return nil;
    }
    if (![UIImage respondsToSelector:@selector(_applicationIconImageForBundleIdentifier:format:scale:)]) {
        return nil;
    }

    @try {
        CGFloat scale = [UIScreen mainScreen].scale;
        return [UIImage _applicationIconImageForBundleIdentifier:bundleIdentifier
                                                          format:2
                                                           scale:scale];
    } @catch (NSException *exception) {
        return nil;
    }
}

@end
