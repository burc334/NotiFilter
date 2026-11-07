#import <Foundation/Foundation.h>
#import "NFFilter.h"

@interface NFTransfer : NSObject

+ (NSData *)exportDataWithFilters:(NSArray<NFFilter *> *)filters
                            error:(NSError **)error;

+ (NSArray<NFFilter *> *)filtersFromData:(NSData *)data
                                  error:(NSError **)error;

+ (NSArray<NFFilter *> *)mergeExistingFilters:(NSArray<NFFilter *> *)existing
                           withImportedFilters:(NSArray<NFFilter *> *)imported;

@end
