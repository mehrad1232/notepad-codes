#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

// Scoped to ai.nova.browser through Filter.plist. This never injects into Safari
// or unrelated apps. It adds only feature-detection-friendly ES polyfills.
%hook WKWebView
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"ai.nova.browser"] && configuration) {
        NSString *source =
        @"(function(){'use strict';"
        "if(!String.prototype.replaceAll){Object.defineProperty(String.prototype,'replaceAll',{value:function(search,replacement){return this.split(search).join(replacement);},configurable:true,writable:true});}"
        "if(!Object.fromEntries){Object.fromEntries=function(entries){var o={};for(var i=0;i<entries.length;i++){o[entries[i][0]]=entries[i][1];}return o;};}"
        "if(!Promise.allSettled){Promise.allSettled=function(items){return Promise.all(Array.prototype.map.call(items,function(p){return Promise.resolve(p).then(function(value){return {status:'fulfilled',value:value};},function(reason){return {status:'rejected',reason:reason};});}));};}"
        "})();";
        WKUserScript *polyfills = [[WKUserScript alloc] initWithSource:source
                                                        injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                     forMainFrameOnly:NO];
        [configuration.userContentController addUserScript:polyfills];
    }
    return %orig(frame, configuration);
}
%end
