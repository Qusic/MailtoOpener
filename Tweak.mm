#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import <CaptainHook.h>

@interface UIWindow (Private)
+ (UIWindow *)keyWindow;
@end

__attribute__((visibility("hidden")))
@interface _MailtoOpenerMailComposeViewControllerDelegate : NSObject <MFMailComposeViewControllerDelegate>
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error;
@end

static NSString *globalIdentifier = @"me.qusic.mailtoopener";
static NSUserDefaults *preferences;
static MFMailComposeViewController *mailComposeController;
static id<MFMailComposeViewControllerDelegate> mailComposeDelegate;
static UIWindow *mailComposeWindow;

static void presentMailComposeView(NSString *recipient, NSString *subject, NSString *body) {
    if (mailComposeController == nil) {
        mailComposeController = [[MFMailComposeViewController alloc]init];
        mailComposeDelegate = [[_MailtoOpenerMailComposeViewControllerDelegate alloc]init];
        mailComposeController.mailComposeDelegate = mailComposeDelegate;
        [mailComposeController setToRecipients:@[recipient]];
        [mailComposeController setSubject:subject];
        [mailComposeController setMessageBody:body isHTML:NO];
        CGRect frame = [[UIScreen mainScreen]bounds];
        CGFloat height = frame.size.height;
        CGRect initialFrame = frame;
        initialFrame.origin.y += height;
        mailComposeWindow = [[UIWindow alloc]initWithFrame:initialFrame];
        mailComposeWindow.windowLevel = 1001;
        mailComposeWindow.rootViewController = mailComposeController;
        [mailComposeWindow makeKeyAndVisible];
        [UIView animateWithDuration:0.4 animations:^{
            mailComposeWindow.frame = frame;
        }];
    }
}

static void dismissMailComposeView() {
    if (mailComposeController != nil) {
        CGRect frame = mailComposeWindow.frame;
        CGFloat height = frame.size.height;
        CGRect endFrame = frame;
        endFrame.origin.y += height;
        [UIView animateWithDuration:0.4 animations:^{
            mailComposeWindow.frame = endFrame;
        } completion:^(BOOL finished) {
            mailComposeController = nil;
            mailComposeDelegate = nil;
            mailComposeWindow = nil;
        }];
    }
}

static NSString *stringURLEncode(NSString *string) {
    return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)string, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8));
}

static NSString *stringURLDecode(NSString *string) {
    return (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (__bridge CFStringRef)string, CFSTR(""), kCFStringEncodingUTF8);
}

@implementation _MailtoOpenerMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    dismissMailComposeView();
}
@end

static NSDictionary *parametersFromMailtoURL(NSURL *url) {
    NSMutableDictionary *parameterDictionary = nil;
    if ([url.scheme isEqualToString:@"mailto"]) {
        parameterDictionary = [[NSMutableDictionary alloc]init];
        NSString *mailtoParameterString = [url.absoluteString substringFromIndex:@"mailto:".length];
        NSUInteger questionMarkLocation = [mailtoParameterString rangeOfString:@"?"].location;
        if (questionMarkLocation != NSNotFound) {
            parameterDictionary[@"recipient"] = stringURLDecode([mailtoParameterString substringToIndex:questionMarkLocation]);
            NSString *parameterString = [mailtoParameterString substringFromIndex:questionMarkLocation+1];
            NSArray *keyValuePairs = [parameterString componentsSeparatedByString:@"&"];
            for (NSString *keyValuePair in keyValuePairs) {
                NSArray *keyValue = [keyValuePair componentsSeparatedByString:@"="];
                if (keyValue.count == 2) {
                    parameterDictionary[stringURLDecode(keyValue[0])] = stringURLDecode(keyValue[1]);
                }
            }
        } else {
            parameterDictionary[@"recipient"] = stringURLDecode(mailtoParameterString);
        }
    }
    return parameterDictionary;
}

static BOOL handleURL(NSURL *url) {
    if ([url.scheme isEqualToString:@"mailto"]) {
        NSString *app = [preferences stringForKey:@"PreferedMailApp"];
        NSDictionary *parameters = parametersFromMailtoURL(url);
        NSString *recipient = parameters[@"recipient"];
        NSString *subject = parameters[@"subject"];
        NSString *body = parameters[@"body"];
        if ([app isEqualToString:@"MailComposeView"]) {
            presentMailComposeView(recipient, subject, body);
            return YES;
        }
        recipient = stringURLEncode(recipient);
        subject = stringURLEncode(subject);
        body = stringURLEncode(body);
        if ([app isEqualToString:@"Inbox"]) {
            NSString *newURL = [NSString stringWithFormat:@"inbox-gmail://co?to=%@&subject=%@&body=%@", recipient, subject, body];
            [[UIApplication sharedApplication]openURL:[NSURL URLWithString:newURL]];
            return YES;
        }
        if ([app isEqualToString:@"Gmail"]) {
            NSString *newURL = [NSString stringWithFormat:@"googlegmail:///co?to=%@&subject=%@&body=%@", recipient, subject, body];
            [[UIApplication sharedApplication]openURL:[NSURL URLWithString:newURL]];
            return YES;
        }
        if ([app isEqualToString:@"Custom"]) {
            NSString *newURL = [preferences stringForKey:@"CustomURL"];
            newURL = [newURL stringByReplacingOccurrencesOfString:@"{{recipient}}" withString:recipient];
            newURL = [newURL stringByReplacingOccurrencesOfString:@"{{subject}}" withString:subject];
            newURL = [newURL stringByReplacingOccurrencesOfString:@"{{body}}" withString:body];
            [[UIApplication sharedApplication]openURL:[NSURL URLWithString:newURL]];
            return YES;
        }
    }
    return NO;
}

CHDeclareClass(SpringBoard);

CHOptimizedMethod(6, self, void, SpringBoard, _openURLCore, NSURL *, url, display, id, display, animating, BOOL, animating, sender, id, sender, activationSettings, id, settings, withResult, id, result)
{
    if (!handleURL(url)) {
        CHSuper(6, SpringBoard, _openURLCore, url, display, display, animating, animating, sender, sender, activationSettings, settings, withResult, result);
    }
}

CHOptimizedMethod(6, self, void, SpringBoard, _openURLCore, NSURL *, url, display, id, display, animating, BOOL, animating, sender, id, sender, activationContext, id, context, activationHandler, id, handler)
{
    if (!handleURL(url)) {
        CHSuper(6, SpringBoard, _openURLCore, url, display, display, animating, animating, sender, sender, activationContext, context, activationHandler, handler);
    }
}

CHOptimizedMethod(6, self, void, SpringBoard, _openURLCore, NSURL *, url, display, id, display, animating, BOOL, animating, sender, id, sender, additionalActivationFlags, id, flags, activationHandler, id, handler)
{
    if (!handleURL(url)) {
        CHSuper(6, SpringBoard, _openURLCore, url, display, display, animating, animating, sender, sender, additionalActivationFlags, flags, activationHandler, handler);
    }
}

CHOptimizedMethod(5, self, void, SpringBoard, _openURLCore, NSURL *, url, display, id, display, animating, BOOL, animating, sender, id, sender, additionalActivationFlags, id, flags)
{
    if (!handleURL(url)) {
        CHSuper(5, SpringBoard, _openURLCore, url, display, display, animating, animating, sender, sender, additionalActivationFlags, flags);
    }
}

CHConstructor
{
	@autoreleasepool {
        preferences = [[NSUserDefaults alloc]initWithSuiteName:globalIdentifier];
        CHLoadLateClass(SpringBoard);
        CHHook(6, SpringBoard, _openURLCore, display, animating, sender, activationSettings, withResult);
        CHHook(6, SpringBoard, _openURLCore, display, animating, sender, activationContext, activationHandler);
        CHHook(6, SpringBoard, _openURLCore, display, animating, sender, additionalActivationFlags, activationHandler);
        CHHook(5, SpringBoard, _openURLCore, display, animating, sender, additionalActivationFlags);
    }
}
