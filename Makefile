TWEAK_NAME = MailtoOpener
MailtoOpener_FILES = Tweak.m
MailtoOpener_FRAMEWORKS = UIKit MessageUI
MailtoOpener_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

export TARGET = iphone:clang
export ARCHS = armv7 arm64
export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 4.0
export TARGET_IPHONEOS_DEPLOYMENT_VERSION_arm64 = 7.0
export ADDITIONAL_OBJCFLAGS = -fobjc-arc -fvisibility=hidden
export INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	$(ECHO_NOTHING)pref="$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences" && mkdir -p "$$pref" && cp MailtoOpenerPreferences.plist "$$pref/MailtoOpener.plist" && cp *.png "$$pref"$(ECHO_END)
