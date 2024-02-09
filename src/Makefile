TARGETS := rpn83p.8xk rpn83p.8xp rpn83p.lst

SPASM_DIR := ../../spasm
SPASM_INC := $(SPASM_DIR)/inc
SPASM := $(SPASM_DIR)/spasm
SRCS := $(wildcard *.asm)

# TI Flash app. Use -DDEBUG to activate functions in debug.asm.
rpn83p.8xk: $(SRCS) Makefile
	$(SPASM) -I $(SPASM_INC) -N rpn83p.asm $@
	#$(SPASM) -DDEBUG -I $(SPASM_INC) -N rpn83p.asm $@

# TI assembly program. No longer works because the program is > 8 kiB.
#rpn83p.8xp: $(SRCS) Makefile
#	$(SPASM) -I $(SPASM_INC) -N rpn83p.asm $@

rpn83p.lst: $(SRCS) Makefile
	$(SPASM) -I $(SPASM_INC) -N -T rpn83p.asm rpn83p.8xp

menudef.asm: menudef.txt ../tools/compilemenu.py
	../tools/compilemenu.py -o $@ $<

clean:
	rm -f $(TARGETS)
