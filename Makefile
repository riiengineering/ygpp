.POSIX:

AWK = awk

BUILD_DIR = build

prefix = /usr/local
bindir = $(prefix)/bin

INSTALL = install
RM = rm -f

all: $(BUILD_DIR)/ygpp

$(BUILD_DIR)/:
	mkdir $@

$(BUILD_DIR)/ygpp: $(BUILD_DIR)/
	sed -e "1s|^#!.*|#!$$(test -x '$(AWK)' && echo '$(AWK)' || command -v '$(AWK)') -f|" ./ygpp >$@
	@head -n 1 $@ | grep -q '^#!/'

install: $(BUILD_DIR)/ygpp .PHONY
	$(INSTALL) -d '$(DESTDIR)$(bindir)'
	$(INSTALL) -m 0755 $(BUILD_DIR)/ygpp '$(DESTDIR)$(bindir)/ygpp'

uninstall: .PHONY
	$(RM) '$(DESTDIR)$(bindir)/ygpp'

clean: .PHONY
	$(RM) -R $(BUILD_DIR)

test: .PHONY
	sh test/run.sh

.PHONY:
