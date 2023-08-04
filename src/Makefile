TARGETS := rpn83p.8xp rpn83p.lst

SPASM_DIR := ../../spasm
SPASM_INC := $(SPASM_DIR)/inc
SPASM := $(SPASM_DIR)/spasm
SRCS := \
	base.asm \
	common.asm \
	const.asm \
	debug.asm \
	display.asm \
	errorcode.asm \
	handlers.asm \
	handlertab.asm \
	input.asm \
	menu.asm \
	menudevdef.asm \
	menuhandlers.asm \
	pstring.asm \
	rpn83p.asm \
	vars.asm

# TI Flash app
rpn83p.8xk: $(SRCS) Makefile
	$(SPASM) -DFLASHAPP -I $(SPASM_INC) -N rpn83p.asm $@

# TI Assembly program
rpn83p.8xp: $(SRCS) Makefile
	$(SPASM) -I $(SPASM_INC) -N rpn83p.asm $@

# Debug version of assembly prpgram.
#rpn83p.8xp: $(SRCS) Makefile
#	$(SPASM) -DDEBUG -I $(SPASM_INC) -N rpn83p.asm $@

rpn83p.lst: $(SRCS) Makefile
	$(SPASM) -I $(SPASM_INC) -N -T rpn83p.asm rpn83p.8xp

menudevdef.asm: menudevdef.txt ../tools/compilemenu.py
	../tools/compilemenu.py -o $@ $<

clean:
	rm -f $(TARGETS)
