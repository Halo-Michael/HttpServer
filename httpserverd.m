#import <Foundation/Foundation.h>
#include <pthread.h>

bool is_number(const char *num)
{
    if (strcmp(num, "0") == 0) {
        return true;
    }
    const char *p = num;
    if (*p < '1' || *p > '9') {
        return false;
    } else {
        p++;
    }
    while (*p) {
        if(*p < '0' || *p > '9') {
            return false;
        } else {
            p++;
        }
    }
    return true;
}

static void restartServer(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    exit(0);
}

void *serverd() {
    CFStringRef appID = CFSTR("com.michael.httpserver");
    CFArrayRef keyList = CFPreferencesCopyKeyList(appID, CFSTR("mobile"), kCFPreferencesAnyHost);
    NSDictionary *settings = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, appID, CFSTR("mobile"), kCFPreferencesAnyHost));
    NSString *filePath = settings[@"path"];
    NSError *error = nil;
    NSMutableDictionary *fileInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error]];
    if (error) {
        return NULL;
    }
    if ([fileInfo[@"NSFileType"] isEqualToString:@"NSFileTypeSymbolicLink"]) {
        char realPath[2048];
        realpath([filePath UTF8String], realPath);
        if (strlen(realPath) == 0) {
            return NULL;
        }
        filePath = [NSString stringWithFormat:@"%s", realPath];
        fileInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error]];
        if (error) {
            return NULL;
        }
    }
    if (![fileInfo[@"NSFileType"] isEqualToString:@"NSFileTypeDirectory"]) {
        return NULL;
    }
    int status = chdir([filePath UTF8String]);
    if (status == 0) {
        while (true) {
            if (settings[@"port"] != nil) {
                if (is_number([settings[@"port"] UTF8String])) {
                    system([[NSString stringWithFormat:@"python3 -m http.server %@", settings[@"port"]] UTF8String]);
                } else {
                    CFPreferencesSetValue(CFSTR("port"), nil, CFSTR("com.michael.httpserver"), CFSTR("mobile"), kCFPreferencesAnyHost);
                    system("python3 -m http.server 80");
                }
            } else {
                system("python3 -m http.server 80");
            }
        }
    }
    return NULL;
}

int main() {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, restartServer, CFSTR("com.michael.httpserver/restart"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

    CFStringRef appID = CFSTR("com.michael.httpserver");
    CFArrayRef keyList = CFPreferencesCopyKeyList(appID, CFSTR("mobile"), kCFPreferencesAnyHost);
    if([(__bridge NSArray *)keyList containsObject:@"enabled"]) {
        NSDictionary *settings = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, appID, CFSTR("mobile"), kCFPreferencesAnyHost));
        if ([settings[@"enabled"] boolValue] && settings[@"path"] != nil && ![settings[@"path"] isEqual:@""]) {
            pthread_t ntid;
            pthread_create(&ntid, NULL, serverd, NULL);
        }
    }
    CFRunLoopRun();
    return 0;
}
