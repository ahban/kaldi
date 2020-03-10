#!/bin/bash
###############################################################################
# file name    : debug-tdnn-chain.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Fri 06 Mar 2020 04:45:56 PM CST
###############################################################################

. path.sh

num_debug=100

egs_org=./exp/tri8b/egs/cegs.1.ark
egs_new=./trash/cegs.debug.ark

nnet3-chain-subset-egs --n=$num_debug ark:$egs_org ark:$egs_new



