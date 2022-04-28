prefix ?= /usr/local
bindir = $(prefix)/bin

run:
	swift run goose --debug

build:
	swift build -c release --disable-sandbox

debug:
	swift build

install: build
	install ".build/release/goose" "$(bindir)"

uninstall:
	rm -r "$(bindir)/goose"

update:
	swift package update

clean:
	rm -rf .build

.PHONY: build install uninstall clean
