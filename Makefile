.PHONY: daala_tools clean
.DEFAULT_GOAL := all

STATIC ?= 0
DEBUG ?= 0
QUIET ?= 1

CFLAGS=-m64 -pedantic -pedantic-errors -std=gnu99 -Werror -Wall -Wextra -Wshadow -Wpointer-arith -Wcast-qual -Wformat=2 -Wstrict-prototypes -Wmissing-prototypes
CC=gcc
TARGETS := psha256
psha256_SOURCES := src/psha256.c
psha256_LDLIBS := -lcrypto
ifeq ($(STATIC),1)
LDFLAGS += -static
endif
## debugging
ifeq ($(DEBUG),1)
CFLAGS += -Og -g
STRIP := echo -n ". Debug mode; not stripping"
else
CFLAGS += -O2
STRIP := strip
endif
## quiet build
ifeq ($(QUIET),1)
QPFX := @
else
QPFX :=
endif
export STATIC DEBUG QUIET

define GEN_TARGET_RULE
$(1): $$($(1)_SOURCES:c=o)
	@echo -n "Building $$@.."
	$(QPFX)$$(CC) $$(CPPFLAGS) $$(CFLAGS) $$($(1)_LDFLAGS) $$(LDFLAGS) -o $$@ $$^ $$($(1)_LDLIBS) $$(LDLIBS)
	$(QPFX)$$(STRIP) $$@
	@echo ". done."
endef
$(foreach targ,$(TARGETS),$(eval $(call GEN_TARGET_RULE,$(targ))))
define GEN_CLEAN_RULE
.PHONY: $(1)_clean
$(1)_clean:
	$(QPFX)echo " [clean] $(1)"
	$(QPFX)rm -f $$($(1)_SOURCES:c=o) $(1)
endef
$(foreach targ,$(TARGETS),$(eval $(call GEN_CLEAN_RULE,$(targ))))

%.o: %.c
	$(QPFX)echo " [cc] $@"
	$(QPFX)$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

all: daala_tools $(TARGETS)

daala_tools:
	+make -C daala_tools

clean: $(TARGETS:=_clean)
	+make -C daala_tools clean
