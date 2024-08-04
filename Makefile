.PHONY: all
all: downloads

#export MAMBA_ROOT_PREFIX=/some/prefix
#eval "$(./bin/micromamba shell hook -s posix)"

downloads:
	mkdir -p downloads
	cd downloads; curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba

