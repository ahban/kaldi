#!/bin/bash
###############################################################################
# file name    : sub-cegs.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Wed 12 Aug 2020 09:51:20 AM CST
###############################################################################

. path.sh

nnet3-chain-subset-egs --randomize-order=false --n=5 ark:./exp/tri8b/egs/cegs.1.ark ark:./trash/s51.cegs
nnet3-chain-subset-egs --randomize-order=false --n=5 ark:./exp/tri8b/egs/cegs.2.ark ark:./trash/s52.cegs

scp ./trash/s51.cegs sun:~/devel/ca/src/o3rd-tests/
scp ./trash/s52.cegs sun:~/devel/ca/src/o3rd-tests/

cp ./trash/s51.cegs ~/devel/ca/src/o3rd-tests/
cp ./trash/s52.cegs ~/devel/ca/src/o3rd-tests/
