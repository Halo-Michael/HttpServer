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

bool modifyPlist(NSString *filename, void (^function)(id))
{
    NSData *data = [NSData dataWithContentsOfFile:filename];
    if (data == nil) {
        return false;
    }
    NSPropertyListFormat format = 0;
    id plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:&format error:nil];
    if (plist == nil) {
        return false;
    }
    if (function) {
        function(plist);
    }
    NSData *newData = [NSPropertyListSerialization dataWithPropertyList:plist format:format options:0 error:nil];
    if (newData == nil) {
        return false;
    }
    if (![data isEqual:newData]) {
        if (![newData writeToFile:filename atomically:YES]) {
            return false;
        }
    }
    return true;
}

static void restartServer(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    exit(0);
}

void *serverd() {
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.michael.httpserver.plist"];
    int status = chdir([settings[@"path"] UTF8String]);
    if (status == 0) {
        if (settings[@"port"] != nil) {
            if (is_number([settings[@"port"] UTF8String])) {
                system([[NSString stringWithFormat:@"python3 -m http.server %@", settings[@"port"]] UTF8String]);
            } else {
                modifyPlist(@"/private/var/mobile/Library/Preferences/com.michael.httpserver.plist", ^(id plist) {
                    plist[@"port"] = nil;
                });
                system("python3 -m http.server 80");
            }
        } else {
            system("python3 -m http.server 80");
        }
    }
    return NULL;
}

int main() {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, restartServer, CFSTR("com.michael.httpserver/restart"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.michael.httpserver.plist"];
    if (settings[@"enabled"]) {
        pthread_t ntid;
        pthread_create(&ntid, NULL, serverd, NULL);
    }
    CFRunLoopRun();
    return 0;
}
