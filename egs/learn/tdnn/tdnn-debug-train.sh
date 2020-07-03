#!/bin/bash
###############################################################################
# file name    : debug-train.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Tue 09 Jun 2020 04:10:54 PM CST
###############################################################################

mb_egs=./trash/debug.mb.chain.egs

if [ ! -f $mb_egs ]; then
    nnet3-chain-copy-egs \
        --frame-shift=0 \
        ark:/home/aban/devel/aban-kaldi/egs/learn/tdnn/exp/tri8b/egs/cegs.2.ark ark:- |\
        nnet3-chain-shuffle-egs --buffer-size=5000 --srand=1 ark:- ark:- |\
        nnet3-chain-merge-egs --minibatch-size=128,64 ark:- ark:$mb_egs 
fi

./build/nnet3-chain-train.d.exe \
    --use-gpu=yes \
    --apply-deriv-weights=False \
    --l2-regularize=0.0 \
    --leaky-hmm-coefficient=0.1 \
    --read-cache=/home/aban/devel/aban-kaldi/egs/learn/tdnn/exp/tri8b/cache.1 \
    --xent-regularize=0.1 \
    --print-interval=10 \
    --momentum=0.0 \
    --max-param-change=2.0 \
    --backstitch-training-scale=0.0 \
    --backstitch-training-interval=1 \
    --l2-regularize-factor=0.5 \
    --optimization.memory-compression-level=2 \
    --srand=1 \
    /home/aban/devel/aban-kaldi/egs/learn/tdnn/exp/tri8b/30.mdl \
    /home/aban/devel/aban-kaldi/egs/learn/tdnn/exp/tri8b/den.fst \
    ark:$mb_egs \
    ./trash/output.raw
