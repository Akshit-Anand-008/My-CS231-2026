VTASKS = task1 task3
VVP = $(patsubst %,%.vvp,$(VTASKS))

AS      := nasm
ASFLAGS := -f elf64 -g
LD      := gcc
LDFLAGS := -no-pie -nostartfiles

RED   = "\\033[31m"
GREEN = "\\033[32m"
RESET = "\\033[0m"

.PHONY: default clean check task1.vcd task2 task2-check task3.vcd 

default:
	@printf "Usage: make [task1|task2(-check)|task3] | make check\n"

# ---- Verilog task: build, autograde, open the waveform ----
$(VTASKS): %: %.vcd
	@code $<

task1.vcd: task1.vvp
	@vvp task1.vvp > task1/output.txt
	@cat task1/output.txt
	@d=`diff task1/expected_output.txt task1/output.txt`; \
	if [ -z "$$d" ]; then printf $(GREEN)"PASS"$(RESET)" -- %s\n"; \
	else printf $(RED)"FAIL"$(RESET)" -- task1\n"; fi
	@printf "  your output:      task1/output.txt\n  expected output:  task1/expected_output.txt\n"

# task3's transcript is split in two at the "Part A/B done" delimiter tb_task3.v
# prints, and each half is graded (and banner-reported) against its own
# expected file -- so Part C (bonus, optional) never affects the Part A/B
# PASS/FAIL verdict, and vice versa.
define big_banner
	d=`diff $(1) $(2)`; \
	if [ -z "$$d" ]; then C="\033[1;42;97m"; W="PASS EXPECTED OUTPUT MATCHES"; \
	else C="\033[1;41;97m"; W="FAIL EXPECTED OUTPUT DOES NOT MATCH, RUN \`diff $(1) $(2)\` TO SEE THE DIFF"; fi; \
	printf "$$C%-100s\033[0m\n" ""; \
	printf "$$C%-100s\033[0m\n" "   $(3): $$W"; \
	printf "$$C%-100s\033[0m\n" ""
endef

task3.vcd: task3.vvp
	@vvp task3.vvp > task3/output_full.txt
	@awk '/^#{20,}$$/{print > "task3/output_A_B.txt"; c=1; next} c{print > "task3/output_C.txt"; next} {print > "task3/output_A_B.txt"}' task3/output_full.txt
	@cat task3/output_full.txt
	@echo
	@$(call big_banner,task3/expected_output_A_B.txt,task3/output_A_B.txt,PART A + B)
	@$(call big_banner,task3/expected_output_C.txt,task3/output_C.txt,PART C (bonus))

.SECONDEXPANSION:
$(VVP): %.vvp: $$(filter-out $$(wildcard $$*/*_solution.v),$$(wildcard $$*/*.v))
	@iverilog -o $@ $^

# ---- Assembly task (task2): reads stdin, writes the result to stdout ----
task2: task2.out
	@echo "task2.out waits on stdin; pipe input like: echo 123 | make task2" >&2
	@./task2.out

task2.out: task2/power_sum.o task2/digit_fn.o
	$(LD) $(LDFLAGS) -o $@ $^

task2/power_sum.o: task2/power_sum.s
	$(AS) $(ASFLAGS) -o $@ $<

task2-check: task2.out
	@for t in task2/tests/*_input.txt; do \
		exp="$${t%_input.txt}_output.txt"; \
		./task2.out < "$$t" > task2/tests/.got; \
		if [ -z "`diff $$exp task2/tests/.got`" ]; then \
			printf $(GREEN)"PASS"$(RESET)" -- %s\n" "$$t"; \
		else \
			printf $(RED)"FAIL"$(RESET)" -- %s (got `cat task2/tests/.got`, want `cat $$exp`)\n" "$$t"; \
		fi; \
	done; \
	rm -f task2/tests/.got

# task2/digit_fn.o is a provided binary artifact: no build rule, never cleaned.

check: task1.vcd task2-check task3

clean:
	@rm -fv task1.vvp task3.vvp task1.vcd task3.vcd \
		task1/output.txt task3/output_full.txt task3/output_A_B.txt task3/output_C.txt \
		task2.out task2/power_sum.o task2/tests/.got
