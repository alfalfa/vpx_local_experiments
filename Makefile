all:
	git submodule update --init
	+make -C daala_tools

clean:
	+make -C daala_tools clean
