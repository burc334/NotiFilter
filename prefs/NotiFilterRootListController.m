#import "NotiFilterRootListController.h"
#import "NFConstants.h"
#import "NFSettings.h"
#import "NFTransfer.h"
#import "NotiFilterFilterListController.h"
#import "NotiFilterHistoryController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface NotiFilterRootListController () <UIDocumentPickerDelegate>
- (void)presentImportOptionsForFiltersNow:(NSArray<NFFilter *> *)filters;
- (void)confirmReplaceWithFiltersNow:(NSArray<NFFilter *> *)filters;
@end

@implementation NotiFilterRootListController

- (NSArray *)specifiers {
    NSArray *specifiers = [self valueForKey:@"_specifiers"];
    if (specifiers.count == 0) {
        specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
        if (specifiers) {
            [self setValue:specifiers forKey:@"_specifiers"];
        }
    }
    return specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"NotiFilter";

    for (PSSpecifier *specifier in self.specifiers) {
        if ([specifier.name isEqualToString:@"About"]) {
            [specifier setProperty:
                [NSString stringWithFormat:@"NotiFilter %@\nDeveloped by burc334", NF_VERSION]
                            forKey:PSFooterTextGroupKey];
        }
    }
}

- (void)viewFilters {
    NotiFilterFilterListController *filters =
        [[NotiFilterFilterListController alloc] init];
    [self.navigationController pushViewController:filters animated:YES];
}

- (void)viewHistory {
    NotiFilterHistoryController *history =
        [[NotiFilterHistoryController alloc] init];
    [self.navigationController pushViewController:history animated:YES];
}

- (void)applySettings:(PSSpecifier *)specifier {
    (void)specifier;
    NFSettingsPostChanged();
    [self reloadSpecifiers];
    [self showMessageWithTitle:@"Applied"
                       message:@"NotiFilter settings are active."];
}

- (void)resetDefaults:(PSSpecifier *)specifier {
    (void)specifier;
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Reset to Defaults?"
                                            message:@"This clears all filters and settings. History is kept."
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        (void)action;
        NFSettingsResetToDefaults();
        [self reloadSpecifiers];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)importFilters:(PSSpecifier *)specifier {
    (void)specifier;
    UIDocumentPickerViewController *picker =
        [[UIDocumentPickerViewController alloc]
            initForOpeningContentTypes:@[UTTypeJSON, UTTypeData]
                               asCopy:YES];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)exportFilters:(PSSpecifier *)specifier {
    (void)specifier;
    NSArray<NFFilter *> *filters = NFSettingsFilters();
    NSError *error = nil;
    NSData *data = [NFTransfer exportDataWithFilters:filters error:&error];
    if (!data) {
        [self showError:error.localizedDescription ?: @"The filters could not be exported."];
        return;
    }

    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"NotiFilter-Filters.json"];
    NSURL *url = [NSURL fileURLWithPath:path];
    if (![data writeToURL:url options:NSDataWritingAtomic error:&error]) {
        [self showError:error.localizedDescription ?: @"The filter file could not be written."];
        return;
    }

    UIActivityViewController *activity =
        [[UIActivityViewController alloc] initWithActivityItems:@[url]
                                           applicationActivities:nil];
    activity.completionWithItemsHandler =
        ^(UIActivityType activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        (void)activityType;
        (void)completed;
        (void)returnedItems;
        (void)activityError;
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    };
    if (activity.popoverPresentationController) {
        activity.popoverPresentationController.sourceView = self.view;
        activity.popoverPresentationController.sourceRect = self.view.bounds;
    }
    [self presentViewController:activity animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
    didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    (void)controller;
    NSURL *url = urls.firstObject;
    if (!url) {
        return;
    }

    BOOL accessing = [url startAccessingSecurityScopedResource];
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (accessing) {
        [url stopAccessingSecurityScopedResource];
    }

    if (!data) {
        [self showError:error.localizedDescription ?: @"The selected file could not be read."];
        return;
    }

    NSArray<NFFilter *> *filters = [NFTransfer filtersFromData:data error:&error];
    if (!filters) {
        [self showError:error.localizedDescription ?: @"The selected file is not a valid NotiFilter export."];
        return;
    }

    [self presentImportOptionsForFilters:filters];
}
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    (void)controller;
}

- (void)presentImportOptionsForFilters:(NSArray<NFFilter *> *)filters {
    [self presentImportOptionsForFiltersNow:filters];
}

- (void)presentImportOptionsForFiltersNow:(NSArray<NFFilter *> *)filters {
    NSString *message = [NSString stringWithFormat:
        @"%lu filter%@ found.\n\nMerge keeps existing filters. Replace removes all current filters.",
        (unsigned long)filters.count,
        filters.count == 1 ? @"" : @"s"];
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Import Filters"
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    UIAlertAction *merge = [UIAlertAction actionWithTitle:@"Merge"
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction *action) {
        (void)action;
        [self applyImportedFilters:filters replace:NO];
    }];
    [alert addAction:merge];
    [alert addAction:[UIAlertAction actionWithTitle:@"Replace"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        (void)action;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self confirmReplaceWithFilters:filters];
        });
    }]];
    alert.preferredAction = merge;
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)confirmReplaceWithFilters:(NSArray<NFFilter *> *)filters {
    [self confirmReplaceWithFiltersNow:filters];
}

- (void)confirmReplaceWithFiltersNow:(NSArray<NFFilter *> *)filters {
    NSString *message = [NSString stringWithFormat:
        @"This deletes all existing filters and imports %lu filter%@.",
        (unsigned long)filters.count,
        filters.count == 1 ? @"" : @"s"];
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Replace All Filters?"
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Replace"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        (void)action;
        [self applyImportedFilters:filters replace:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)applyImportedFilters:(NSArray<NFFilter *> *)filters replace:(BOOL)replace {
    NSArray<NFFilter *> *result = replace
        ? filters
        : [NFTransfer mergeExistingFilters:NFSettingsFilters() withImportedFilters:filters];
    NFSettingsSetFilters(result);
    NFSettingsPostChanged();
    [self reloadSpecifiers];
    [self showMessageWithTitle:@"Import Complete"
                       message:[NSString stringWithFormat:
                           @"Imported %lu filter%@.",
                           (unsigned long)filters.count,
                           filters.count == 1 ? @"" : @"s"]];
}

- (void)showMessageWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showError:(NSString *)message {
    [self showMessageWithTitle:@"Import/Export Failed" message:message];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [super setPreferenceValue:value specifier:specifier];
    NFSettingsPostChanged();
}

@end
