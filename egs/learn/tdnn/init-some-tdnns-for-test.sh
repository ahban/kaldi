#!/bin/bash
###############################################################################
# file name    : init-a-tdnn.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Wed 08 Jul 2020 11:17:05 AM CST
###############################################################################

. path.sh

for f in tdnn-models/{0..2}.sh; do
    if [ -f $f ]; then
        $f 
    fi
done
