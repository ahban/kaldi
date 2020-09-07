#!/bin/bash
###############################################################################
# file name    : compute-global-online-cmvn.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Thu 03 Sep 2020 06:39:10 PM CST
###############################################################################

. path.sh || { echo "failed to source path.sh"; exit 1; }

compute-cmvn-stats scp:data/mfcc/train/feats.scp global.ark
