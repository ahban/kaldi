#!/bin/bash
###############################################################################
# file name    : GetModlePdf.sh
# authors      : Ban Zhihua(2018-2019)
# contact      : sawpara@126.com
# created time : Wed 20 Feb 2019 05:24:24 PM CST
###############################################################################

if [ $# -ne 2 ]; then
    echo "Usage $0 <model name> <pdf name>"
    exit 1;
fi


mdl=$1
pdf=$2


steps/nnet3/nnet3_to_dot.sh --component-attributes \
    "name,type,input-dim,output-dim" $mdl ./trash/temp.dot $pdf

scp $pdf sun:~/24-3


