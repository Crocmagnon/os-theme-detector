.PHONY: build clean install

TERM := $(shell which fish)

build: dist
	swiftc ./theme-detector.swift -o ./dist/theme-detector
	sed "s#HOME#${HOME}#g;s#TERM#${TERM}#g" info.augendre.os-theme-detector.plist.template > ./dist/info.augendre.os-theme-detector.plist

dist:
	mkdir -p dist

clean:
	rm -rf dist

install: build
	cp ./dist/theme-detector ~/.local/bin/theme-detector
	mkdir -p ~/Library/LaunchAgents
	cp ./dist/info.augendre.os-theme-detector.plist ~/Library/LaunchAgents/
	launchctl load ~/Library/LaunchAgents/info.augendre.os-theme-detector.plist

uninstall:
	launchctl unload ~/Library/LaunchAgents/info.augendre.os-theme-detector.plist
	rm -f ~/Library/LaunchAgents/info.augendre.os-theme-detector.plist ~/.local/bin/theme-detector /tmp/os-theme-detector.lock

start:
	launchctl load ~/Library/LaunchAgents/info.augendre.os-theme-detector.plist

stop:
	launchctl unload ~/Library/LaunchAgents/info.augendre.os-theme-detector.plist

log:
	cat /tmp/themeChangeDetector.log
