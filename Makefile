export THEOS ?= $(HOME)/theos
THEOS_PACKAGE_SCHEME ?= rootless

TARGET = iphone:clang:latest:18.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NotiFilter
NotiFilter_FILES = Tweak.xm NFSettings.m NFFilter.m NFNotificationContext.m NFDecision.m NFFilterEngine.m NFHistoryStore.m
NotiFilter_FRAMEWORKS = Foundation UIKit
NotiFilter_CFLAGS = -fobjc-arc -Wall -Wextra -Wno-unused-parameter
NotiFilter_LDFLAGS += -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = NotiFilterPrefs
NotiFilterPrefs_FILES = prefs/NotiFilterRootListController.m \
                        prefs/NotiFilterFilterListController.m \
                        prefs/NotiFilterFilterEditorController.m \
                        prefs/NotiFilterChoiceController.m \
                        prefs/NotiFilterAppPickerController.m \
                        prefs/NotiFilterHistoryController.m \
                        prefs/NotiFilterFilterRowCell.m \
                        prefs/NotiFilterInlineTextFieldCell.m \
                        prefs/NotiFilterTimePickerController.m \
                        prefs/NotiFilterWeekdayController.m \
                        prefs/NFTransfer.m \
                        NFHistoryStore.m \
                        NFIconProvider.m \
                        NFFilter.m \
                        NFSettings.m
NotiFilterPrefs_FRAMEWORKS = UIKit Foundation UniformTypeIdentifiers
NotiFilterPrefs_PRIVATE_FRAMEWORKS = Preferences
NotiFilterPrefs_INSTALL_PATH = /Library/PreferenceBundles
NotiFilterPrefs_RESOURCE_DIRS = prefs/Resources
NotiFilterPrefs_CFLAGS = -fobjc-arc -Wall -Wextra -I$(THEOS_PROJECT_DIR)
NotiFilterPrefs_LDFLAGS += -F$(THEOS)/sdks/iPhoneOS14.5.sdk/System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/bundle.mk

