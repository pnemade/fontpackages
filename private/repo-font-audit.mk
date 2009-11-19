# Directory with files to process
SRCDIR = src
# Work area
TMPDIR = $(wildcard tmp)

this_makefile := $(lastword $(MAKEFILE_LIST))
datadir := $(dir $(this_makefile))

SUBDIRS := $(wildcard */)

ifneq ($(TMPDIR),)
FONT_TARGET_ROOTS := $(subst .rfo.fonts.info,.rfo,$(shell find $(TMPDIR) -name "*\.rfo\.fonts\.info"))

FONT_EXTS := fontlint unicover fc-query fonts
add_font_ext = $(foreach file, $(FONT_TARGET_ROOTS),$(file).$(ext))
FONT_TARGETS := $(foreach ext, $(FONT_EXTS), $(add_font_ext))

CORE_FONT_TARGETS := $(subst .rfo.core-fonts.info,.rfo.core-fonts,$(shell find $(TMPDIR) -name "*\.rfo\.core-fonts\.info"))
endif

ifneq ($(wildcard font-links.txt),)
LINK_TARGETS := processed-font-links.txt
endif

TARGETS := $(FONT_TARGETS) $(CORE_FONT_TARGETS) $(LINK_TARGETS)

ifneq ($(TARGETS),)
TARGETS := $(TARGETS) rpmlint.txt
endif

.PHONY: $(SUBDIRS) all rfo

all : $(SUBDIRS)

$(SUBDIRS) :
	$(MAKE) -C $@ rfo -f $(this_makefile)

ifneq ($(TARGETS),)
rfo : $(TARGETS)
else
rfo : ; @echo "$(shell pwd): nothing to do!"
endif

$(TMPDIR)/%.rfo.fonts : rpm-info.txt \
                        rpmlint.score \
                        $(SRCDIR)/% \
                        $(TMPDIR)/%.rfo.fonts.info \
                        $(TMPDIR)/%.rfo.fontlint \
                        $(TMPDIR)/%.rfo.unicover \
                        $(TMPDIR)/%.rfo.fc-query.report \
                        $(TMPDIR)/%.rfo.fc-query
	$(datadir)/fonts-report $^ > $@
	@echo -n "f"

$(TMPDIR)/%.rfo.unicover : $(SRCDIR)/%
	ttfcoverage $< > $@

$(TMPDIR)/%.rfo.fontlint : $(SRCDIR)/%
	LANG=C fontlint $(CURDIR)/$< > $@ 2>&1 || :

$(TMPDIR)/%.rfo.fc-query $(TMPDIR)/%.rfo.fc-query.report : $(SRCDIR)/%
	$(datadir)/process-fc-query $< $(TMPDIR)/$*.rfo.fc-query > $(TMPDIR)/$*.rfo.fc-query.report

$(TMPDIR)/%.rfo.core-fonts : rpm-info.txt \
                             rpmlint.score \
                             $(SRCDIR)/% \
                             $(TMPDIR)/%.rfo.core-fonts.info
	$(datadir)/core-fonts-report $^ > $@
	@echo -n "X"

rpmlint.txt rpmlint.score :
	rpmlint -i "*.rpm" > rpmlint.txt 2>&1 \
          && touch rpmlint.score || echo "$$?" > rpmlint.score

processed-font-links.txt : rpm-info.txt \
                           rpmlint.score \
                           font-links.txt
	$(datadir)/font-links-report $^ > $@
	@echo -n "l"
