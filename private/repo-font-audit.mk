# Directory with files to process
SRCDIR = src
# Work area
TMPDIR = tmp

THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
DATADIR := $(dir $(THIS_MAKEFILE))

SUBDIRS := */

TARGET_LISTS := $(wildcard mk.data.targets mk.file.targets)

ifneq ($(TARGET_LISTS),)
TARGETS := $(shell cat $(TARGET_LISTS)) rpmlint.txt
endif

.PHONY: $(SUBDIRS) all rfo

all : $(SUBDIRS)

$(SUBDIRS) :
	$(MAKE) -C $@ rfo -f $(THIS_MAKEFILE)

ifneq ($(TARGETS),)
rfo : $(TARGETS)
else
rfo : ;
	@echo "Nothing to do!"
endif

$(TMPDIR)/%.rfo.fonts : rpm-info.txt \
                        rpmlint.score \
                        $(SRCDIR)/% \
                        $(TMPDIR)/%.rfo.info \
                        $(TMPDIR)/%.rfo.fontlint \
                        $(TMPDIR)/%.rfo.unicover \
                        $(TMPDIR)/%.rfo.fc-query.report \
                        $(TMPDIR)/%.rfo.fc-query
	$(DATADIR)/fonts-report $^ > $@
	@echo -n "f"

$(TMPDIR)/%.rfo.unicover : $(SRCDIR)/%
	ttfcoverage $< > $@

$(TMPDIR)/%.rfo.fontlint : $(SRCDIR)/%
	LANG=C fontlint $(CURDIR)/$< > $@ 2>&1 || :

$(TMPDIR)/%.rfo.fc-query $(TMPDIR)/%.rfo.fc-query.report : $(SRCDIR)/%
	$(DATADIR)/process-fc-query $< $(TMPDIR)/$*.rfo.fc-query > $(TMPDIR)/$*.rfo.fc-query.report

$(TMPDIR)/%.rfo.core-fonts : rpm-info.txt \
                             rpmlint.score \
                             $(SRCDIR)/% \
                             $(TMPDIR)/%.rfo.info
	$(DATADIR)/core-fonts-report $^ > $@
	@echo -n "X"

rpmlint.txt rpmlint.score :
	rpmlint -i "*.rpm" > rpmlint.txt 2>&1 \
          && touch rpmlint.score || echo "$$?" > rpmlint.score

processed-font-links.txt : rpm-info.txt \
                           rpmlint.score \
                           font-links.txt
	$(DATADIR)/font-links-report $^ > $@
	@echo -n "l"
