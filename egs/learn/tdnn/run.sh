#!/bin/bash
###############################################################################
# file name    : run.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Thu 05 Mar 2020 06:35:49 PM CST
###############################################################################

. ./cmd.sh
. ./path.sh

H=$(pwd)

thchs=/home/aban/data/thchs30

stage=1

if [ $stage -le 1 ]; then
    local/thchs-30_data_prep.sh $H $thchs/data_thchs30 || exit 1;
fi

