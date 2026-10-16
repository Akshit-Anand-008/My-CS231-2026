.SUFFIXES:

# make task1 [trace=soplex] [long=1]
#   builds ChampSim with your task1/cache.h, cache.cc and main.cc and runs it on one trace.
# make taskN [trace=soplex] [long=1]     (every task folder with one policy .cc, e.g. task2, task3)
#   copies taskN/<policy>.cc into Champsim/replacement/<policy>/, builds
#   Champsim/bin/<policy> with that policy at the L2C, and runs it on one trace.
# make lru            same with ChampSim's own lru at the L2C (reference for task2)
# make check          runs every task on its check traces and compares with the reference

CHAMPSIM  := Champsim
# Traces: $CS231_TRACE_DIR if set, else /opt/CS231_Traces (lab machines).
# A trace is found by name: trace=soplex picks the first file matching *soplex*.xz.
TRACE_DIR ?= $(or $(CS231_TRACE_DIR),/opt/CS231_Traces)
trace_file = $(or $(firstword $(wildcard $(TRACE_DIR)/*$1*.xz)),$(error no trace matching *$1*.xz in $(TRACE_DIR)))
TRACES    := soplex bwaves mcf gcc
trace     ?= soplex

# Quick run for build and sanity checks. long=1 gives the numbers quoted in the PDF.
ifdef long
WARMUP := 20000000
SIM    := 25000000
else
WARMUP := 1000000
SIM    := 10000000
endif

# Length of one run in `make check`.
CHECK_WARMUP := 1000000
CHECK_SIM    := 5000000

# A policy task is any folder (other than task1) with one policy source. The policy name is
# the file name; it is also the folder under Champsim/replacement/ and the binary in bin/.
policy = $(basename $(notdir $(filter-out %_solution.cc,$(wildcard $1/*.cc))))

POLICY_TASKS := $(patsubst %/,%,$(sort $(filter-out task1/,$(dir $(wildcard */*.cc)))))
TASKS        := task1 $(POLICY_TASKS)

# Task 1 edits ChampSim itself, so it is built in a private copy that is made
# again from Champsim/ on every build. The other tasks never see these edits.
T1 := .task1_champsim

# solution_makefile sets this to _solution and builds the *_solution files instead.
SUFFIX ?=

RED   := "\\033[31m"
GREEN := "\\033[32m"
RESET := "\\033[0m"

STATS := '^CPU 0 cumulative IPC|^cpu0_L2C (TOTAL|LOAD|RFO|WRITEBACK) '

# ipc_mpki <simulated instructions>: reads ChampSim's output, prints "IPC L2C-MPKI".
# MPKI = L2C TOTAL misses / (simulated instructions / 1000), with the count we asked for.
ipc_mpki = awk -v n=$1 '/^CPU 0 cumulative IPC/ {i = $$5} /^cpu0_L2C TOTAL/ {m = $$NF} END {printf "%s %.4f\n", i, m / (n / 1000)}'
TRACK := '^cpu0_L2C (TOTAL|LOAD|READ HITS PER WAY|MOST MISSES IN ONE SET)'

.PHONY: default $(TASKS) lru check clean $(addprefix check-,$(TASKS))

default:
	@printf "Usage: make [%s|lru|check] [trace=soplex|bwaves|mcf|gcc] [long=1]\n" "$$(echo $(TASKS) | tr ' ' '|')"

# build <policy> <source .cc>: install the source as that policy, set it at the L2C, compile
define build
	@mkdir -p $(CHAMPSIM)/replacement/$1
	@if [ -n "$2" ]; then cp $2 $(CHAMPSIM)/replacement/$1/$1.cc; fi
	@python3 -c "import json; c = json.load(open('$(CHAMPSIM)/champsim_config.json')); \
		c['executable_name'] = 'bin/$1'; c['L2C']['replacement'] = '$1'; \
		json.dump(c, open('$(CHAMPSIM)/$1.json', 'w'), indent=4)"
	@printf "Building $(CHAMPSIM)/bin/$1 (L2C replacement = $1)\n"
	@cd $(CHAMPSIM) && ./config.sh $1.json > /dev/null 2>&1 && $(MAKE) --no-print-directory -s > /dev/null
endef

# build_task1: fresh copy of Champsim/ with the three task1 files in it, default config
define build_task1
	@rm -rf $(T1) && cp -r $(CHAMPSIM) $(T1) && rm -rf $(T1)/bin $(T1)/obj
	@find $(T1) \( -name '*.o' -o -name '*.d' \) -delete
	@cp task1/cache$(SUFFIX).h $(T1)/inc/cache.h
	@cp task1/cache$(SUFFIX).cc $(T1)/src/cache.cc
	@cp task1/main$(SUFFIX).cc $(T1)/src/main.cc
	@printf "Building $(T1)/bin/champsim with task1/cache.h, cache.cc, main.cc\n"
	@cd $(T1) && ./config.sh champsim_config.json > /dev/null 2>&1 && $(MAKE) --no-print-directory -s -j4 > /dev/null
endef

# run <binary> <trace> <warmup> <sim> <grep pattern>
define run
	@printf "$1 --warmup_instructions $3 --simulation_instructions $4 $(call trace_file,$2)\n"
	@$1 --warmup_instructions $3 --simulation_instructions $4 --hide_heartbeat $(call trace_file,$2) | grep -E $5
endef

task1:
	$(build_task1)
	$(call run,$(T1)/bin/champsim,$(trace),$(WARMUP),$(SIM),$(TRACK))

# run_policy <binary>: like run, plus a computed L2C MPKI line
define run_policy
	@printf "$1 --warmup_instructions $(WARMUP) --simulation_instructions $(SIM) $(call trace_file,$(trace))\n"
	@$1 --warmup_instructions $(WARMUP) --simulation_instructions $(SIM) --hide_heartbeat $(call trace_file,$(trace)) \
		| awk -v n=$(SIM) '/$(subst ',,$(STATS))/ {print} /^cpu0_L2C TOTAL/ {m = $$NF} END {printf "cpu0_L2C MPKI: %.4f\n", m / (n / 1000)}'
endef

$(POLICY_TASKS):
	$(call build,$(call policy,$@),$@/$(call policy,$@)$(SUFFIX).cc)
	$(call run_policy,$(CHAMPSIM)/bin/$(call policy,$@))

lru:
	$(call build,lru,)
	$(call run_policy,$(CHAMPSIM)/bin/lru)

# Each task: build once, run the four traces in parallel, compare with the reference.
# Tasks run one after another (they share Champsim/Makefile); do not use make -j.
check: $(addprefix check-,$(TASKS))

# IPC and L2C MPKI must equal the reference exactly: ChampSim is deterministic, so a correct
# policy gives the same numbers as ours. TOL is the allowed fraction (0 = exact).
TOL := 0

# Traces used by `make check`, per task. A trace is left out where an unchanged template
# gives the same result as the solution (task1: bwaves has no L2C read hits; task3: on bwaves
# and gcc, ip_based behaves like the template's "always evict way 0").
# `make check check_traces="..."` overrides the list for every task.
check_traces_task1 := soplex mcf gcc
check_traces_task3 := soplex mcf
traces_for = $(or $(check_traces),$(check_traces_$1),$(TRACES))

# pass_fail <label> <trace> <got> <want>: exact match
pass_fail = if [ -n "$3" ] && [ "$3" = "$4" ]; then printf "[%s] %-7s | "$(GREEN)"PASS"$(RESET)"\n" "$1" $2; \
	else printf "[%s] %-7s | "$(RED)"FAIL"$(RESET)"\n    got:      %s\n    expected: %s\n" "$1" $2 "$3" "$4"; fi

# within <got> <want>: true if got is within TOL of want
within = awk -v g="$1" -v w="$2" -v t=$(TOL) 'BEGIN { d = g - w; if (d < 0) d = -d; exit !(g != "" && w != "" && d <= t * w) }'

# result_check <task> <trace> <ipc> <mpki> <ref ipc> <ref mpki>: both within TOL
result_check = if $(call within,$3,$5) && $(call within,$4,$6); \
	then printf "[%s] %-7s IPC %s (reference %s), L2C MPKI %s (reference %s) | "$(GREEN)"PASS"$(RESET)"\n" "$1" $2 "$3" "$5" "$4" "$6"; \
	else printf "[%s] %-7s | "$(RED)"FAIL"$(RESET)" (differs from the reference)\n    got:      IPC %s, L2C MPKI %s\n    expected: IPC %s, L2C MPKI %s\n" "$1" $2 "$3" "$4" "$5" "$6"; fi

# task1: READ HITS PER WAY must match task1/expected_output.txt exactly.
# MOST MISSES IN ONE SET is optional: checked only if your program prints it.
# need_traces <task>: stop with a clear error if one of its traces is missing
need_traces = @: $(foreach tr,$(call traces_for,$1),$(call trace_file,$(tr)))

check-task1:
	$(call need_traces,task1)
	$(build_task1)
	@for tr in $(call traces_for,task1); do \
		( out=$$($(T1)/bin/champsim --warmup_instructions $(CHECK_WARMUP) --simulation_instructions $(CHECK_SIM) \
			--hide_heartbeat $$(ls $(TRACE_DIR)/*$$tr*.xz | head -1)); \
		  for key in 'READ HITS PER WAY' 'MOST MISSES IN ONE SET'; do \
			got=$$(echo "$$out" | grep "^cpu0_L2C $$key:"); \
			want=$$(grep "^$$tr: cpu0_L2C $$key:" task1/expected_output.txt 2>/dev/null | sed "s/^$$tr: //"); \
			if [ "$$key" = 'READ HITS PER WAY' ]; then $(call pass_fail,task1,$$tr,$$got,$$want); \
			elif [ -z "$$got" ]; then printf "[task1 optional] %-7s | not attempted\n" $$tr; \
			else $(call pass_fail,task1 optional,$$tr,$$got,$$want); fi; \
		  done ) & \
	done; wait

# policy tasks: IPC and L2C MPKI must both match taskN/expected_output.txt (within TOL)
$(addprefix check-,$(POLICY_TASKS)): check-%:
	$(call need_traces,$*)
	$(call build,$(call policy,$*),$*/$(call policy,$*)$(SUFFIX).cc)
	@for tr in $(call traces_for,$*); do \
		( set -- $$($(CHAMPSIM)/bin/$(call policy,$*) --warmup_instructions $(CHECK_WARMUP) --simulation_instructions $(CHECK_SIM) \
			--hide_heartbeat $$(ls $(TRACE_DIR)/*$$tr*.xz | head -1) | $(call ipc_mpki,$(CHECK_SIM))); \
		  got_ipc=$$1; got_mpki=$$2; \
		  set -- $$(awk -v tr=$$tr '$$1 == tr {print $$2, $$3}' $*/expected_output.txt 2>/dev/null); \
		  $(call result_check,$*,$$tr,$$got_ipc,$$got_mpki,$$1,$$2) ) & \
	done; wait

clean:
	@rm -rfv $(foreach t,$(POLICY_TASKS),$(foreach p,$(call policy,$t),$(CHAMPSIM)/replacement/$p $(CHAMPSIM)/$p.json)) \
		$(CHAMPSIM)/lru.json $(CHAMPSIM)/bin $(CHAMPSIM)/obj $(T1)
	@find $(CHAMPSIM) \( -name '*.o' -o -name '*.d' \) -delete -print
