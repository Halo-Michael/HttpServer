#include <CoreFoundation/CoreFoundation.h>

int main()
{
    if (getuid() != 0) {
        printf("Run this as root!\n");
        return 1;
    }

    system("launchctl unload /Library/LaunchDaemons/com.michael.httpserverd.plist");

    return 0;
}
