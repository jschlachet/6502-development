# top level makefile
#
#

SUBDIRS = rom

.PHONY: subdirs $(SUBDIRS)

subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@
clean:
	(cd rom; make clean)
