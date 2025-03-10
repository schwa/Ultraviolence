#import <Foundation/Foundation.h>

@interface BundleFinder : NSObject
@end

@implementation BundleFinder
@end

@implementation NSBundle (Module)

+ (NSBundle *)ultraviolenceExampleShadersBundle {
    static NSBundle *moduleBundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundleName = @"UltraviolenceExamples_UltraviolenceExampleShaders";

        NSMutableArray<NSURL *> *overrides = [NSMutableArray array];

#if DEBUG
        // The 'PACKAGE_RESOURCE_BUNDLE_PATH' name is preferred since the expected value is a path.
        // The check for 'PACKAGE_RESOURCE_BUNDLE_URL' will be removed when all clients have switched over.
        NSDictionary *env = [[NSProcessInfo processInfo] environment];
        NSString *overridePath = env[@"PACKAGE_RESOURCE_BUNDLE_PATH"] ?: env[@"PACKAGE_RESOURCE_BUNDLE_URL"];
        if (overridePath) {
            [overrides addObject:[NSURL fileURLWithPath:overridePath]];
        }
#endif

        NSArray<NSURL *> *candidates = [overrides arrayByAddingObjectsFromArray:@[
            [NSBundle mainBundle].resourceURL,
            [[NSBundle bundleForClass:[BundleFinder class]] resourceURL],
            [NSBundle mainBundle].bundleURL
        ]];

        for (NSURL *candidate in candidates) {
            if (candidate) {
                NSURL *bundlePath = [candidate URLByAppendingPathComponent:[bundleName stringByAppendingString:@".bundle"]];
                NSBundle *bundle = [NSBundle bundleWithURL:bundlePath];
                if (bundle) {
                    moduleBundle = bundle;
                    return;
                }
            }
        }

        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Unable to find bundle named UltraviolenceExamples_UltraviolenceExampleShaders"
                                     userInfo:nil];
    });

    return moduleBundle;
}

@end
