#!/bin/bash
###############################################################################
# file name    : show-model.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Thu 04 Jun 2020 09:56:45 AM CST
###############################################################################

if [ $# -ne 1 ]; then
    echo "usage $0 <model>"
    exit 1;
fi


model=$1

./steps/nnet3/nnet3_to_dot.sh \
    --info-bin nnet3-info \
    --component-attributes "name,type,input-dim,output-dim" \
    $model ${model}.dot ${model}.pdf
scp $model.pdf sun:~/24-3/

evince $model.pdf


