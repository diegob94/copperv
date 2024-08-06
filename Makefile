.PHONY: all
all: sim_cpu

.PHONY: create_env create_explicit_env
create_env:
	micromamba create -f env.yml -y
	micromamba env export -n coppervenv --explicit > explicit_env.txt

create_explicit_env:
	micromamba create -n coppervenv -f explicit_env.txt

.PHONY: sim_cpu
sim_cpu:
	$(MAKE) -C ./sim/cpu
