#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import <CaptainHook.h>
#define PreferencesPlist @"/var/mobile/Library/Preferences/me.qusic.mailtoopener.plist"
#define PreferencesNotification "me.qusic.mailtoopener.preferencesChanged"
#define iOS7() (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0)
typedef NS_ENUM(NSInteger, MailApp) {
    Mail = 0,
    MailComposeView,
    Gmail,
    Sparrow
};
static MailApp PreferedMailApp;
static MFMailComposeViewController *MailComposeViewController;
static id<MFMailComposeViewControllerDelegate> MailComposeViewDelegate;
static UIWindow *PresentedWindow;
@interface UIWindow (Private)
+ (UIWindow *)keyWindow;
@end
@interface NSString (URLCoding)
- (NSString *)MailtoOpener_URLEncodedString;
- (NSString *)MailtoOpener_URLDecodedString;
@end
@interface MFMailComposeViewController (MailtoOpener)
- (void)MailtoOpener_present;
- (void)MailtoOpener_dismiss;
@end
__attribute__((visibility("hidden")))
@interface _MailtoOpenerMailComposeViewControllerDelegate : NSObject <MFMailComposeViewControllerDelegate>
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error;
@end
@implementation NSString (MailtoOpener)
- (NSString *)MailtoOpener_URLEncodedString
{ return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)self, NULL, CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8)); }
- (NSString *)MailtoOpener_URLDecodedString
{ return (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (__bridge CFStringRef)self, CFSTR(""), kCFStringEncodingUTF8); }
@end
@implementation MFMailComposeViewController (MailtoOpener)
- (void)MailtoOpener_present
{
    MailComposeViewDelegate = [[_MailtoOpenerMailComposeViewControllerDelegate alloc]init];
    self.mailComposeDelegate = MailComposeViewDelegate;
    CGRect frame = [[UIScreen mainScreen]bounds];
    CGFloat height = frame.size.height;
    CGRect initialFrame = frame;
    initialFrame.origin.y += height;
    PresentedWindow = [[UIWindow alloc]initWithFrame:initialFrame];
    PresentedWindow.windowLevel = 1001;
    PresentedWindow.rootViewController = self;
    [PresentedWindow makeKeyAndVisible];
    [UIView animateWithDuration:0.4 animations:^{
        PresentedWindow.frame = frame;
    }];
}
-(void)MailtoOpener_dismiss
{
    CGRect frame = PresentedWindow.frame;
    CGFloat height = frame.size.height;
    CGRect endFrame = frame;
    endFrame.origin.y += height;
    [UIView animateWithDuration:0.4 animations:^{
        PresentedWindow.frame = endFrame;
    } completion:^(BOOL finished) {
        MailComposeViewController = nil;
        MailComposeViewDelegate = nil;
        PresentedWindow = nil;
    }];
}
@end
@implementation _MailtoOpenerMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller MailtoOpener_dismiss];
}
@end
static NSDictionary *parametersFromMailtoURL(NSURL *url)
{
    NSMutableDictionary *parameterDictionary = nil;
    if ([url.scheme isEqualToString:@"mailto"]) {
        parameterDictionary = [[NSMutableDictionary alloc]init];
        NSString *mailtoParameterString = [[url absoluteString]substringFromIndex:[@"mailto:"length]];
        NSUInteger questionMarkLocation = [mailtoParameterString rangeOfString:@"?"].location;
        if (questionMarkLocation != NSNotFound) {
            [parameterDictionary setObject:[[mailtoParameterString substringToIndex:questionMarkLocation]MailtoOpener_URLDecodedString]forKey:@"recipient"];
            NSString *parameterString = [mailtoParameterString substringFromIndex:questionMarkLocation+1];
            NSArray *keyValuePairs = [parameterString componentsSeparatedByString:@"&"];
            for (NSString *queryString in keyValuePairs) {
                NSArray *keyValuePair = [queryString componentsSeparatedByString:@"="];
                if (keyValuePair.count == 2)
                    [parameterDictionary setObject:[[keyValuePair objectAtIndex:1]MailtoOpener_URLDecodedString]forKey:[[keyValuePair objectAtIndex:0]MailtoOpener_URLDecodedString]];
            }
        } else {
            [parameterDictionary setObject:[mailtoParameterString MailtoOpener_URLDecodedString]forKey:@"recipient"];
        }
    }
    return parameterDictionary;
}
CHDeclareClass(SpringBoard);
CHOptimizedMethod(6, self, void, SpringBoard, _openURLCore, NSURL *, url, display, id, display, animating, BOOL, animating, sender, id, sender, additionalActivationFlags, id, flags, activationHandler, id, handler)
{
    if ([url.scheme isEqualToString:@"mailto"]) {
        NSDictionary *parameters = parametersFromMailtoURL(url);
        NSString *recipient = parameters[@"recipient"];
        NSString *subject = parameters[@"subject"];
        NSString *body = parameters[@"body"];
        switch (PreferedMailApp) {
            case Mail: {
                CHSuper(6, SpringBoard, _openURLCore, url, display, display, animating, animating, sender, sender, additionalActivationFlags, flags, activationHandler, handler);
                break;
            }
            case MailComposeView: {
                MailComposeViewController = [[MFMailComposeViewController alloc]init];
                [MailComposeViewController setToRecipients:@[recipient]];
                [MailComposeViewController setSubject:subject];
                [MailComposeViewController setMessageBody:body isHTML:NO];
                [MailComposeViewController MailtoOpener_present];
                break;
            }
            case Gmail: {
                NSString *newURL = [NSString stringWithFormat:@"googlegmail:///co?subject=%@&body=%@&to=%@",subject,body,recipient];
                [[UIApplication sharedApplication]openURL:[NSURL URLWithString:newURL]];
                break;
            }
            case Sparrow: {
                NSString *newURL = [NSString stringWithFormat:@"sparrow:%@",recipient];
                [[UIApplication sharedApplication]openURL:[NSURL URLWithString:newURL]];
                break;
            }
            default: {
                CHSuper(6, SpringBoard, _openURLCore, url, display, display, animating, animating, sender, sender, additionalActivationFlags, flags, activationHandler, handler);
                break;
            }
        }
    } else {
        CHSuper(6, SpringBoard, _openURLCore, url, display, display, animating, animating, sender, sender, additionalActivationFlags, flags, activationHandler, handler);
    }
}
CHOptimizedMethod(5, self, void, SpringBoard, _openURLCore, NSURL *, url, display, id, display, animating, BOOL, animating, sender, id, sender, additionalActivationFlags, id, flags)
{
    if ([url.scheme isEqualToString:@"mailto"]) {
        NSDictionary *parameters = parametersFromMailtoURL(url);
        NSString *recipient = parameters[@"recipient"];
        NSString *subject = parameters[@"subject"];
        NSString *body = parameters[@"body"];
        switch (PreferedMailApp) {
            case Mail: {
                CHSuper(5, SpringBoard, _openURLCore, url, display, display, animating, animating, sender, sender, additionalActivationFlags, flags);
                break;
            }
            case MailComposeView: {
                MailComposeViewController = [[MFMailComposeViewController alloc]init];
                [MailComposeViewController setToRecipients:@[recipient]];
                [MailComposeViewController setSubject:subject];
                [MailComposeViewController setMessageBody:body isHTML:NO];
                [MailComposeViewController MailtoOpener_present];
                break;
            }
            case Gmail: {
                NSString *newURL = [NSString stringWithFormat:@"googlegmail:///co?subject=%@&body=%@&to=%@",subject,body,recipient];
                [[UIApplication sharedApplication]openURL:[NSURL URLWithString:newURL]];
                break;
            }
            case Sparrow: {
                NSString *newURL = [NSString stringWithFormat:@"sparrow:%@",recipient];
                [[UIApplication sharedApplication]openURL:[NSURL URLWithString:newURL]];
                break;
            }
            default: {
                CHSuper(5, SpringBoard, _openURLCore, url, display, display, animating, animating, sender, sender, additionalActivationFlags, flags);
                break;
            }
        }
    } else {
        CHSuper(5, SpringBoard, _openURLCore, url, display, display, animating, animating, sender, sender, additionalActivationFlags, flags);
    }
}
static void loadPreferences(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:PreferencesPlist];
    PreferedMailApp = [preferences[@"PreferedMailApp"]integerValue];
}
CHConstructor
{
	@autoreleasepool {
        CHLoadLateClass(SpringBoard);
        if (iOS7()) {
            CHHook(6, SpringBoard, _openURLCore, display, animating, sender, additionalActivationFlags, activationHandler);
        } else {
            CHHook(5, SpringBoard, _openURLCore, display, animating, sender, additionalActivationFlags);
        }
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, loadPreferences, CFSTR(PreferencesNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(PreferencesNotification), NULL, NULL, TRUE);
    }
}