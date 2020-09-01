VERSION = 0.3.0
CC = xcrun -sdk ${THEOS}/sdks/iPhoneOS13.0.sdk clang -arch arm64 -arch arm64e
LDID = ldid

.PHONY: all clean

all: httpserverd postinst prerm
	mkdir com.michael.httpserver_$(VERSION)_iphoneos-arm
	mkdir com.michael.httpserver_$(VERSION)_iphoneos-arm/DEBIAN
	cp control com.michael.httpserver_$(VERSION)_iphoneos-arm/DEBIAN
	mv postinst prerm com.michael.httpserver_$(VERSION)_iphoneos-arm/DEBIAN
	mkdir com.michael.httpserver_$(VERSION)_iphoneos-arm/Library
	mkdir com.michael.httpserver_$(VERSION)_iphoneos-arm/Library/LaunchDaemons
	cp com.michael.httpserverd.plist com.michael.httpserver_$(VERSION)_iphoneos-arm/Library/LaunchDaemons
	mkdir com.michael.httpserver_$(VERSION)_iphoneos-arm/Library/PreferenceLoader
	mkdir com.michael.httpserver_$(VERSION)_iphoneos-arm/Library/PreferenceLoader/Preferences
	cp HttpServer.plist com.michael.httpserver_$(VERSION)_iphoneos-arm/Library/PreferenceLoader/Preferences
	mkdir com.michael.httpserver_$(VERSION)_iphoneos-arm/usr
	mkdir com.michael.httpserver_$(VERSION)_iphoneos-arm/usr/libexec
	mv httpserverd com.michael.httpserver_$(VERSION)_iphoneos-arm/usr/libexec
	dpkg -b com.michael.httpserver_$(VERSION)_iphoneos-arm

httpserverd: clean
	$(CC) httpserverd.c -framework CoreFoundation -o httpserverd
	strip httpserverd
	$(LDID) -Sentitlements.xml httpserverd

postinst: clean
	$(CC) postinst.c -o postinst
	strip postinst
	$(LDID) -Sentitlements.xml postinst

prerm: clean
	$(CC) prerm.c -o prerm
	strip prerm
	$(LDID) -Sentitlements.xml prerm

clean:
	rm -rf com.michael.httpserver_* httpserverd postinst prerm
