#!/bin/bash
###############################################################################
# file name    : frame-shift-test.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Mon 01 Jun 2020 11:38:15 AM CST
###############################################################################

. path.sh || { echo "not exist path.sh"; exit 1; }

#nnet3-chain-subset-egs --randomize-order=false --n=100 ark:./exp/tri8b/egs/cegs.1.ark ark:./trash/1.cegs.ark
#nnet3-chain-copy-egs --frame-shift=0 ark:./trash/1.cegs.ark ark:- | nnet3-chain-merge-egs --minibatch-size=4 ark:- ark,t:./trash/mb.1.txt

nnet3-chain-subset-egs --randomize-order=false --n=5 ark:./exp/tri8b/egs/cegs.1.ark ark,t:./trash/2.cegs.ark.txt
nnet3-chain-copy-egs --frame-shift=0 ark:./trash/2.cegs.ark.txt ark:- | nnet3-chain-merge-egs --minibatch-size=4 ark:- ark,t:./trash/mb.2.txt


