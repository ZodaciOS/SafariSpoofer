#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <Cephei/HBPreferences.h>
#import <rootless.h>

static HBPreferences *prefs;
static BOOL enabled;
static NSString *spoofedVersion;
static NSString *spoofedDevice;
static NSString *spoofedUserAgent;

static void loadPrefs() {
    enabled = [prefs boolForKey:@"enabled"];
    spoofedVersion = [prefs objectForKey:@"iosVersion"] ?: @"18.3";
    spoofedDevice = [prefs objectForKey:@"deviceModel"] ?: @"iPhone16,2";
    
    NSString *customUA = [prefs objectForKey:@"customUserAgent"];
    if (customUA && customUA.length > 0) {
        spoofedUserAgent = customUA;
    } else {
        spoofedUserAgent = [NSString stringWithFormat:@"Mozilla/5.0 (iPhone; CPU iPhone OS %@ like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/%@ Mobile/15E148 Safari/604.1", 
            [spoofedVersion stringByReplacingOccurrencesOfString:@"." withString:@"_"],
            spoofedVersion];
    }
}

%hook WKWebView

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    if (!enabled) {
        return %orig;
    }
    
    if (!configuration.applicationNameForUserAgent || configuration.applicationNameForUserAgent.length == 0) {
        configuration.applicationNameForUserAgent = spoofedUserAgent;
    }
    
    return %orig;
}

%end

%hook WKWebViewConfiguration

- (void)setApplicationNameForUserAgent:(NSString *)applicationNameForUserAgent {
    if (enabled && spoofedUserAgent) {
        %orig(spoofedUserAgent);
    } else {
        %orig;
    }
}

%end

%hook WKNavigator

- (NSString *)userAgent {
    if (enabled && spoofedUserAgent) {
        return spoofedUserAgent;
    }
    return %orig;
}

%end

%hook UIWebView

- (instancetype)initWithFrame:(CGRect)frame {
    UIWebView *webView = %orig;
    
    if (enabled && spoofedUserAgent) {
        [webView setValue:spoofedUserAgent forKey:@"userAgent"];
    }
    
    return webView;
}

%end

%hook WKPreferences

- (instancetype)init {
    WKPreferences *prefs = %orig;
    return prefs;
}

%end

%hook WKUserContentController

- (void)addUserScript:(WKUserScript *)userScript {
    %orig;
    
    if (enabled) {
        NSString *js = [NSString stringWithFormat:@"\
            Object.defineProperty(navigator, 'platform', { \
                get: function() { return 'iPhone'; } \
            }); \
            Object.defineProperty(navigator, 'userAgent', { \
                get: function() { return '%@'; } \
            }); \
            Object.defineProperty(navigator, 'appVersion', { \
                get: function() { return '%@ (iPhone; CPU iPhone OS %@ like Mac OS X)'; } \
            });",
            spoofedUserAgent,
            spoofedVersion,
            [spoofedVersion stringByReplacingOccurrencesOfString:@"." withString:@"_"]
        ];
        
        WKUserScript *script = [[WKUserScript alloc] initWithSource:js 
                                                      injectionTime:WKUserScriptInjectionTimeAtDocumentStart 
                                                   forMainFrameOnly:NO];
        %orig(script);
    }
}

%end

%ctor {
    @autoreleasepool {
        prefs = [[HBPreferences alloc] initWithIdentifier:@"com.zodacios.safarispoofer"];
        [prefs registerBool:&enabled default:YES forKey:@"enabled"];
        
        loadPrefs();
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                       NULL,
                                       (CFNotificationCallback)loadPrefs,
                                       CFSTR("com.zodacios.safarispoofer/ReloadPrefs"),
                                       NULL,
                                       CFNotificationSuspensionBehaviorCoalesce);
    }
}
