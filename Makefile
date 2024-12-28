.PHONY: build clean install

build: dist
	swiftc ./theme-detector.swift -o ./dist/theme-detector

dist:
	mkdir -p dist

clean:
	rm -r dist

install: build
	cp ./dist/theme-detector ${HOME}/.local/bin/theme-detector
	mkdir -p ~/Library/LaunchAgents
	cp ./info.augendre.os-theme-detector.plist ${HOME}/Library/LaunchAgents/
	launchctl load ${HOME}/Library/LaunchAgents/info.augendre.os-theme-detector.plist
