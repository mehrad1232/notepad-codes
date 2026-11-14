#import <UIKit/UIKit.h>

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    // Intentionally minimal: NOVA remains a standalone app.
    // Launch the browser with the nova:// URL scheme from Shortcuts or another launcher.
}
%end
