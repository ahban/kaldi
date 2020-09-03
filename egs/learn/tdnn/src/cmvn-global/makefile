###############################################################################
# copyright    : Ban Zhihua all rights reserved
# contact      : sawpara@126.com
# created time : Tue 09 Jun 2020 04:31:32 PM CST
###############################################################################
# only support one target a time
TARGET := ./compute-global-cmvn.exe

SRCS := \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/cudamatrix/*.cc)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/cudamatrix/*.cu)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/util/*.cc)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/base/*.cc)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/matrix/*.cc)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/feat/*.cc)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/transform/*.cc)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/gmm/*.cc)) \
	$(filter-out %-test.cc, $(wildcard ${HOME}/devel/aban-kaldi/src/tree/*.cc)) \
	$(TARGET:.exe=.cpp)

	#${HOME}/devel/aban-kaldi/src/chainbin/nnet3-chain-train.cc

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
