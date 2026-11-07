#import <Foundation/Foundation.h>
#import "NFFilter.h"

#ifdef __cplusplus
extern "C" {
#endif

BOOL NFSettingsEnabled(void);
void NFSettingsSetEnabled(BOOL enabled);
NSArray<NFFilter *> *NFSettingsFilters(void);
void NFSettingsSetFilters(NSArray<NFFilter *> *filters);
NSInteger NFSettingsHistoryLimit(void);
void NFSettingsSetHistoryLimit(NSInteger limit);
NSInteger NFSettingsHistoryRetentionDays(void);
void NFSettingsSetHistoryRetentionDays(NSInteger days);
void NFSettingsPostChanged(void);
void NFSettingsResetToDefaults(void);

#ifdef __cplusplus
}
#endif
