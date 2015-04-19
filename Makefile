SRCFILES := $(wildcard *.asm)
GENDIR := gen
GENFILES := $(patsubst %.asm, $(GENDIR)/%.asm,$(SRCFILES))

gen-asm: $(GENFILES)

$(GENDIR)/%.asm: %.asm
	@mkdir -p $(GENDIR)
	cpp -w $< | grep -v ^# > $@

clean:
	@rm -rf $(GENDIR)
