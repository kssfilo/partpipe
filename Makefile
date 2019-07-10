.SUFFIXES:

APPNAME=partpipe
VERSION=1.0.0

#=

COMMANDS=help build pack test clean 

#=

DESTDIR=dist
COFFEES=$(wildcard *.coffee)
TARGETNAMES=package.json LICENSE $(patsubst %.coffee,%.js,$(COFFEES)) 
TARGETS=$(patsubst %,$(DESTDIR)/%,$(TARGETNAMES))
ALL=$(TARGETS) $(DESTDIR)/README.md
SDK=node_modules/.gitignore
TOOLS=node_modules/.bin

#=

.PHONY:$(COMMANDS)

build:$(TARGETS)

test:test-main.passed

test.passed:test-main.passed test-classic.passed
	touch $@

test-main.passed:test/.ready $(TARGETS)
	./test.bats
	touch $@

test/.ready:
	cd $(@D);for i in test*.txt;do cat $$i|perl -pe 's/\@PARTPIPE\@=?/@@@@@/g' >c-$$i;done
	touch $@

test-classic.passed:$(TARGETS)
	./test-classic.bats
	touch $@

pack:$(ALL) test.passed|$(DESTDIR)

clean:
	-rm -r $(DESTDIR) node_modules *.passd

help:
	@echo "Targets:$(COMMANDS)"

#=

$(DESTDIR):
	mkdir -p $@

$(DESTDIR)/README.md:README.md $(TARGETS)
	cp README.md $@
	vim $@ -c '/@SEE_NPM_README@/||delete||-1||read!./cli.coffee -h' -c '%s/cli\.coffee/$(APPNAME)/g||x!'

$(DESTDIR)/package.json:package.json|$(DESTDIR)
	cp $< $@
	vim $@ -c '%s/__VERSION__/version/|%s/@VERSION@/$(VERSION)/g||x!'

$(DESTDIR)/%.js:%.coffee $(SDK)|$(DESTDIR)
ifndef NC
	$(TOOLS)/coffee-jshint -o node $< 
endif
	head -n1 $<|grep '^#!'|sed 's/coffee/node/'  >$@ 
	cat $<|$(TOOLS)/coffee -bcs >> $@
ifeq ("$*","cli")
	chmod +x $@
endif


$(DESTDIR)/%:%|$(DESTDIR)
	cp $< $@

$(SDK):package.json
	npm install
	@touch $@

