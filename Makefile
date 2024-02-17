# This Makefile uses the GNU standard make targets
# https://www.gnu.org/prep/standards/html_node/Standard-Targets.html
.POSIX:
.PHONY:
.SUFFIXES: .tar .tar.gz .tar.bz2 .tar.xz .tar.zst .tar.Z

PACKAGE = ygpp
VERSION = 0.1
DIST_COMPRESS = .gz

BUILD_DIR = build

prefix = /usr/local
bindir = $(prefix)/bin

AWK = awk
INSTALL = install
RM = rm -f
SH = sh

all: $(BUILD_DIR)/ygpp

$(BUILD_DIR)/:
	mkdir $@

$(BUILD_DIR)/ygpp: ygpp $(BUILD_DIR)/
	sed -e "1s|^#!.*|#!$$(test -x '$(AWK)' && echo '$(AWK)' || command -v '$(AWK)') -f|" ./ygpp >$@
	@head -n 1 $@ | grep -q '^#!/'

installdirs: .PHONY
	$(INSTALL) -d '$(DESTDIR)$(bindir)'

install: $(BUILD_DIR)/ygpp installdirs .PHONY
	$(INSTALL) -m 0755 $(BUILD_DIR)/ygpp '$(DESTDIR)$(bindir)/ygpp'

uninstall: .PHONY
	$(RM) '$(DESTDIR)$(bindir)/ygpp'

clean: .PHONY
	$(RM) -R $(BUILD_DIR)

distclean: clean

GZIP_ENV = --best
.tar.tar.gz:
	GZIP='$(GZIP_ENV)' gzip -f $<
.tar.tar.bz2:
	bzip2 -z -f $<
.tar.tar.xz:
	xz -z -f $<
.tar.tar.zst:
	zstd -z -f $<
.tar.tar.Z:
	compress -f $<

$(PACKAGE)-$(VERSION).tar: .PHONY
	@echo creating $@...
	@tar cvf $@ Makefile ygpp LICENSE README.md
	@tar rvf $@ test/run.sh
	@find test \( -name 'input' -o -name 'expect.*[a-z]' -o -path '*/inc/*[a-z0-9]' \) -exec tar rvf $@ {} +

DIST_FILENAME = $(PACKAGE)-$(VERSION).tar
dist: $(DIST_FILENAME)$(DIST_COMPRESS)
dist-gzip: $(DIST_FILENAME).gz
dist-bzip2: $(DIST_FILENAME).bz2
dist-xz: $(DIST_FILENAME).xz
dist-zstd: $(DIST_FILENAME).zst
dist-tarZ: $(DIST_FILENAME).Z

check: .PHONY
	$(SH) test/run.sh

