# Directory with files to process
SRCDIR = src
# Work area
TMPDIR = tmp
# Utilities directory
BINDIR = 

$(TMPDIR)/%.rfo.fonts : rpm-info.txt \
                        rpmlint.score \
                        $(SRCDIR)/% \
                        $(TMPDIR)/%.rfo.info \
                        $(TMPDIR)/%.rfo.fontlint \
                        $(TMPDIR)/%.rfo.unicover \
                        $(TMPDIR)/%.rfo.fc-query.report \
                        $(TMPDIR)/%.rfo.fc-query
	$(BINDIR)/fonts-report $^ > $@

$(TMPDIR)/%.rfo.unicover : $(SRCDIR)/%
	ttfcoverage $< > $@

$(TMPDIR)/%.rfo.fontlint : $(SRCDIR)/%
	LANG=C fontlint $(CURDIR)/$< > $@ 2>&1 || :

$(TMPDIR)/%.rfo.fc-query $(TMPDIR)/%.rfo.fc-query.report : $(SRCDIR)/%
	$(BINDIR)/process-fc-query $< $(TMPDIR)/$*.rfo.fc-query > $(TMPDIR)/$*.rfo.fc-query.report

$(TMPDIR)/%.rfo.core-fonts : rpm-info.txt \
                             rpmlint.score \
                             $(SRCDIR)/% \
                             $(TMPDIR)/%.rfo.info
	$(BINDIR)/core-fonts-report $^ > $@

rpmlint.txt rpmlint.score :
	rpmlint -i "*.rpm" > rpmlint.txt 2>&1 \
          && touch rpmlint.score || echo "$$?" > rpmlint.score

processed-font-links.txt : rpm-info.txt \
                           rpmlint.score \
                           font-links.txt
	$(BINDIR)/font-links-report $^ > $@
