TARGET := iphone:clang:latest:12.0
ARCHS := arm64
INSTALL_TARGET_PROCESSES = NOVA

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NOVALaunch
NOVALaunch_FILES = Tweak.xm
NOVALaunch_CFLAGS = -fobjc-arc
NOVALaunch_FRAMEWORKS = UIKit WebKit
NOVALaunch_EXTRA_FRAMEWORKS =

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 NOVA || true"
