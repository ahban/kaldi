###############################################################################
# copyright    : Ban Zhihua all rights reserved
# contact      : sawpara@126.com
# created time : Tue 09 Jun 2020 04:31:32 PM CST
###############################################################################
# only support one target a time
TARGET := tdnn-init.exe

SRCS := \
	$(TARGET:.exe=.cpp) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/cudamatrix/*.cc)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/cudamatrix/*.cu)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/util/*.cc)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/base/*.cc)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/matrix/*.cc)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/fstext/*.cc)) \
	$(filter-out %-test.cc %-test-utils.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/hmm/*.cc)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/lat/*.cc)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/tree/*.cc)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/chain/*.cc)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/chain/*.cu)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/nnet3/*.cc)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/decoder/*.cc)) 

CPP_FLAGS := -w -I.. -I. -I${HOME}/soft/cub-1.8.0 -DHAVE_CUDA=1 -DHAVE_MKL=1 #-DUSE_BANBAN=1
C_FLAGS   := -w -I.. -I. -I${HOME}/soft/cub-1.8.0 -DHAVE_CUDA=1 -DHAVE_MKL=1 #-DUSE_BANBAN=1
CU_FLAGS  := -w -I.. -I. -I${HOME}/soft/cub-1.8.0 -DHAVE_CUDA=1 -DHAVE_MKL=1 #-DUSE_BANBAN=1
LD_FLAGS  := 

ENABLE_CUDA     := yes
#ENABLE_OPENMP   := yes
#ENABLE_PTHREADS := yes

MKL_PC_STEM     := mkl-lp64-sequential-2017

host = $(shell hostname)

CPP_FLAGS += `pkg-config --cflags kaldi-$(host) openfst`
C_FLAGS   += `pkg-config --cflags kaldi-$(host) openfst`
CU_FLAGS  += `pkg-config --cflags kaldi-$(host) openfst`
LD_FLAGS  += `pkg-config --libs   openfst`



include ./makefile.base
