TARGET := iphone:clang:12.0:12.0
ARCHS := arm64
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NOVALaunch
NOVALaunch_FILES = Tweak.xm
NOVALaunch_CFLAGS = -fobjc-arc
NOVALaunch_FRAMEWORKS = UIKit
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
