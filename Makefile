.PHONY: all link install bootstrap status unlink clean

all: bootstrap link

link:
	@bash ./install.sh link

install: all

bootstrap:
	@bash ./install.sh bootstrap

status:
	@bash ./install.sh status

unlink:
	@bash ./install.sh unlink

clean:
	find . -name "*~" -o -name "*.swp" -o -name "*.swo" | xargs rm -rf
