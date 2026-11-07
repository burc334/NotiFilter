#import <Foundation/Foundation.h>

@interface NFNotificationContext : NSObject

@property (nonatomic, copy) NSString *sectionIdentifier;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, assign) BOOL criticalAlert;

+ (instancetype)contextWithRequest:(id)request;
+ (instancetype)contextWithBulletin:(id)bulletin;

@end
