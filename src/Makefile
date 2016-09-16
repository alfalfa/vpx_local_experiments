CFLAGS=-m64 -pedantic -pedantic-errors -std=gnu99 -Werror -Wall -Wextra -Wshadow -Wpointer-arith -Wcast-qual -Wformat=2 -Wstrict-prototypes -Wmissing-prototypes
LDLIBS=-lcrypto
CC=gcc

DEBUG ?= 0
ifeq ($(DEBUG),1)
CFLAGS+=-Og -g
else
CFLAGS+=-O2
endif

all: psha256

psha256: psha256.c

clean:
	rm -f psha256 core
