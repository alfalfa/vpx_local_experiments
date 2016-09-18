all:
	git submodule update --init
	+make -C daala_tools
	+make -C src

clean:
	+make -C daala_tools clean
	+make -C src clean
