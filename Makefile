PREFIX  ?= /usr/local
BINDIR  ?= $(PREFIX)/bin
SCRIPT  := app-recorder

.PHONY: all install uninstall lint check test clean

all: lint test

install:
	install -Dm755 $(SCRIPT) $(DESTDIR)$(BINDIR)/$(SCRIPT)
	@echo "Installed $(SCRIPT) to $(DESTDIR)$(BINDIR)/$(SCRIPT)"

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/$(SCRIPT)
	@echo "Removed $(DESTDIR)$(BINDIR)/$(SCRIPT)"

lint: check
check:
	shellcheck $(SCRIPT) tests/run-tests.sh
	shfmt -d $(SCRIPT) || true

test:
	./tests/run-tests.sh

clean:
	rm -f ./tests/tmp/*
