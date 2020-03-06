#!/bin/bash
###############################################################################
# file name    : debug-tdnn-chain.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Fri 06 Mar 2020 04:45:56 PM CST
###############################################################################

. path.sh

num_debug=1

feats=./trash/feats.scp
cmvns=./trash/cmvn.scp
input=./trash/applied_cmvn.ark

head -n $num_debug data/mfcc/test/split10/1/feats.scp > $feats
head -n $num_debug data/mfcc/test/split10/1/cmvn.scp > $cmvns

apply-cmvn \
    --norm-means=true --norm-vars=true \
    --utt2spk=ark:data/mfcc/test/split10/1/utt2spk \
    scp:$cmvns \
    scp:$feats ark:$input

nnet3-latgen-faster\
    --frame-subsampling-factor=3 \
    --frames-per-chunk=140 \
    --extra-left-context=0  \
    --extra-right-context=0 \
    --extra-left-context-initial=0 \
    --extra-right-context-final=0 \
    --minimize=false --max-active=7000 --min-active=200 \
    --beam=15.0 --lattice-beam=8.0 --acoustic-scale=1.0 \
    --allow-partial=true \
    --word-symbol-table=/home/aban/devel/aban-kaldi/egs/learn/tdnn/exp/tri7b_tree/graph/words.txt \
    /home/aban/devel/aban-kaldi/egs/learn/tdnn/exp/tri8b/final.mdl \
    /home/aban/devel/aban-kaldi/egs/learn/tdnn/exp/tri7b_tree/graph/HCLG.fst \
    ark:$input \
    ark:./trash/lattice.ark

#'ark:|lattice-scale --acoustic-scale=10.0 ark:- ark:- | gzip -c >/home/aban/devel/aban-kaldi/egs/learn/tdnn/exp/tri8b/decode_lang/lat.1.gz' 

echo nnet3-latgen-faster --frame-subsampling-factor=3 --frames-per-chunk=140 --extra-left-context=0 --extra-right-context=0 --extra-left-context-initial=0 --extra-right-context-final=0 --minimize=false --max-active=7000 --min-active=200 --beam=15.0 --lattice-beam=8.0 --acoustic-scale=1.0 --allow-partial=true --word-symbol-table=/home/aban/devel/aban-kaldi/egs/learn/tdnn/exp/tri7b_tree/graph/words.txt /home/aban/devel/aban-kaldi/egs/learn/tdnn/exp/tri8b/final.mdl /home/aban/devel/aban-kaldi/egs/learn/tdnn/exp/tri7b_tree/graph/HCLG.fst ark:$input ark:./trash/lattice.ark
