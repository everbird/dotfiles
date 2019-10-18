#. Dotfile Manager -={

#. INSTRUCTIONS -={
#.   TBD
#. }=-

all: personal

#. Internal vars
STOW := stowsh/stowsh

default_packages := zsh tmux
personal_packages := $(default_packages) git
work_packages := $(default_packages) git-work

# Autocompletion
personal: install-personal
work: install-work

# Dynamic install/uninstall -= {

install-%:
	@echo "Installing profile: $*"
	${STOW} -vv -t ~ ${$*_packages}

uninstall-%:
	@echo "Uninstalling profile: $*"
	${STOW} -vv -D -t ~ ${$*_packages}

#. }=-

list:
	find ~ -name ".*" -maxdepth 1 -ls | column -t

link-list:
	find ~ -maxdepth 1 -type l -ls | column -t
llist: link-list

clean:
	find . -name "*~" -o -name "*.swp" -o -name "*.swo" | xargs rm -rf

#. }=-
