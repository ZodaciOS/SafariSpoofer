export THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:16.0:16.0
INSTALL_TARGET_PROCESSES = MobileSafari
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SafariSpoofer

SafariSpoofer_FILES = Tweak.x
SafariSpoofer_CFLAGS = -fobjc-arc
SafariSpoofer_FRAMEWORKS = UIKit Foundation WebKit
SafariSpoofer_EXTRA_FRAMEWORKS = Cephei

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += SafariSpooferPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
