TARGETS := cursorinfo.8xp cursorinfo.8xk

SPASM_DIR := ../../../spasm
SPASM_INC := $(SPASM_DIR)/inc
SPASM := $(SPASM_DIR)/spasm

all: $(TARGETS)

cursorinfo.8xk: cursorinfo.asm
	$(SPASM) -DFLASHAPP -I $(SPASM_INC) -N $< $@

cursorinfo.8xp: cursorinfo.asm
	$(SPASM) -I $(SPASM_INC) -N $< $@

clean:
	rm -f $(TARGETS)
