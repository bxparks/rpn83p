TARGETS := prime.8xp validate.8xp

SPASM_DIR := ../../../spasm
SPASM_INC := $(SPASM_DIR)/inc
SPASM := $(SPASM_DIR)/spasm
SPASM_FLAGS := -A -N -I $(SPASM_INC) \
	-DMOD_DEIX_BY_BC_NONRESTORING_CHUNK8_REGA_UNROLLED

all: $(TARGETS)

prime.8xp: prime.asm modu32u16.asm Makefile
	$(SPASM) $(SPASM_FLAGS) $< $@

validate.8xp: validate.asm modu32u16.asm print.asm Makefile
	$(SPASM) $(SPASM_FLAGS) $< $@

clean:
	rm -f $(TARGETS)
