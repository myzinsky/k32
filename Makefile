FILE=riscv
TARGET=synth_ice40 -dsp
OPT=opt

.DEFAULT_GOAL := all

init: 
	ghdl -a core.vhd
	ghdl -e core
	ghdl -a riscv.vhd
	ghdl -e riscv
	ghdl -a testbench.vhd
	ghdl -e testbench

simulation: init
	ghdl -r testbench --wave=$(FILE).ghw

synthesis: $(FILE).vhd init
	yosys '-mghdl' -p 'ghdl $(FILE); read_verilog reset.v clock.v; $(TARGET); $(OPT); write_json $(FILE).json; show;'

visualize:
	sed -i -e 's/inout/output/g' $(FILE).json
	netlistsvg $(FILE).json -o $(FILE).svg
	svgo $(FILE).svg
	rsvg-convert -f pdf -o $(FILE).pdf $(FILE).svg

pr: synthesis
	DYLD_FRAMEWORK_PATH=/Users/myzinsky/Zeugs/Qt/5.14.2/clang_64/lib nextpnr-ice40 \
						--up5k \
					   	--package sg48 \
						--asc $(FILE).asc \
						--pcf upduino_v1.pcf \
						--json $(FILE).json \
						--routed-svg $(FILE)-routed.svg
	rsvg-convert -f pdf -o $(FILE)-routed.pdf $(FILE)-routed.svg &
	rsvg-convert -f png -o $(FILE)-routed.png $(FILE)-routed.svg &
	icepack $(FILE).asc $(FILE).bin

flash:
	iceprog -e 128 # Force a reset
	iceprog $(FILE).bin

sram:
	iceprog -S $(FILE).bin

software:
	perl sw/assembler.pl sw/fibonacci.asm

clean:
	rm -f $(FILE).ghw work-obj93.cf \
	   	$(FILE).json* \
		$(FILE).pdf \
		$(FILE).svg \
		$(FILE).asc \
		$(FILE).bin \
		$(FILE)-routed.svg \
		$(FILE)-routed.pdf \
		$(FILE)-routed.png \
		sw/fibonacci.asm.bin \
		sw/fibonacci.asm.vhd

all: synthesis pr sram

