#include <CoreFoundation/CoreFoundation.h>
#include <pthread.h>
#include <sys/stat.h>

CFStringRef appID = CFSTR("com.michael.httpserver");

bool is_number(const char *num) {
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

char *CFStringCopyUTF8String(CFStringRef aString) {
    if (aString == NULL) {
        return NULL;
    }
    CFIndex maxSize = CFStringGetMaximumSizeForEncoding(CFStringGetLength(aString), kCFStringEncodingUTF8) + 1;
    char *buffer = (char *)malloc(maxSize);
    memset(buffer, 0, maxSize);
    if (CFStringGetCString(aString, buffer, maxSize, kCFStringEncodingUTF8)) {
        return buffer;
    }
    free(buffer);
    return NULL;
}

static void restartServer(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    exit(0);
}

void *serverd() {
    char *path = CFStringCopyUTF8String(CFPreferencesCopyValue(CFSTR("path"), appID, CFSTR("mobile"), kCFPreferencesAnyHost));
    char *realPath;
    struct stat filestat;
    if (lstat(path, &filestat) < 0) {
        free(path);
        return NULL;
    }
    if (S_ISLNK(filestat.st_mode)) {
        realPath = (char *)malloc(PATH_MAX);
        memset(realPath, 0, PATH_MAX);
        realpath(path, realPath);
        free(path);
        realPath = (char *)realloc(realPath, sizeof(char) * (strlen(realPath) + 1));
    } else {
        realPath = path;
    }
    if (lstat(realPath, &filestat) < 0) {
        free(realPath);
        return NULL;
    }
    if (!S_ISDIR(filestat.st_mode)) {
        free(realPath);
        return NULL;
    }
    int status = chdir(realPath);
    free(realPath);
    if (status == 0) {
        while (true) {
            CFArrayRef keyList = CFPreferencesCopyKeyList(appID, CFSTR("mobile"), kCFPreferencesAnyHost);
            if (keyList != NULL) {
                if (CFArrayContainsValue(keyList, CFRangeMake(0, CFArrayGetCount(keyList)), CFSTR("port"))) {
                    char *port = CFStringCopyUTF8String(CFPreferencesCopyValue(CFSTR("port"), appID, CFSTR("mobile"), kCFPreferencesAnyHost));
                    if (is_number(port)) {
                        CFRelease(keyList);
                        char *command = (char *)malloc(sizeof(char) * (strlen(port) + 24));
                        memset(command, 0, sizeof(char) * (strlen(port) + 24));
                        sprintf(command, "python3 -m http.server %s", port);
                        free(port);
                        system(command);
                        free(command);
                        continue;
                    } else {
                        free(port);
                        CFPreferencesSetValue(CFSTR("port"), NULL, appID, CFSTR("mobile"), kCFPreferencesAnyHost);
                    }
                }
                CFRelease(keyList);
            }
            system("python3 -m http.server 80");
        }
    }
    return NULL;
}

int main() {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, restartServer, CFSTR("com.michael.httpserver/restart"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    CFArrayRef keyList = CFPreferencesCopyKeyList(appID, CFSTR("mobile"), kCFPreferencesAnyHost);
    if (keyList != NULL) {
        if (CFArrayContainsValue(keyList, CFRangeMake(0, CFArrayGetCount(keyList)), CFSTR("enabled")) && CFBooleanGetValue(CFPreferencesCopyValue(CFSTR("enabled"), appID, CFSTR("mobile"), kCFPreferencesAnyHost)) && CFArrayContainsValue(keyList, CFRangeMake(0, CFArrayGetCount(keyList)), CFSTR("path")) && CFStringGetLength(CFPreferencesCopyValue(CFSTR("path"), appID, CFSTR("mobile"), kCFPreferencesAnyHost)) != 0) {
            pthread_t ntid;
            pthread_create(&ntid, NULL, serverd, NULL);
        }
        CFRelease(keyList);
    }
    CFRunLoopRun();
    return 0;
}
