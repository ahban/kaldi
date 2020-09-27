#!/bin/bash
###############################################################################
#  file name    : decode-test.sh
#  authors      : Ban Zhihua(2018-2020)
#  contact      : sawpara@126.com
#  created time : Fri 25 Sep 2020 10:01:42 AM CST
###############################################################################




output=exp/decode

decode=true

srcdir=./exp/tri8b_tdnn_base

if [ "$decode" = 'true' ]; then
    decode_cmd="ssh.pl"

    model_full_name=./exp/tri8b_tdnn_base/15-tune-output/69-epoch-9-iteration-6.mdl
    model_only_name=$(basename $model_full_name)

    frames_per_chunk=140
    nspk=$(wc -l <data/mfcc/test/spk2utt)
    tree_dir=exp/tri7b_tree
    local/nnet3/aban-decode.sh \
        --acwt 1.0 --post-decode-acwt 10.0 \
        --extra-left-context 0 --extra-right-context 0 \
        --extra-left-context-initial 0 \
        --extra-right-context-final 0 \
        --frames-per-chunk $frames_per_chunk \
        --nj $nspk --cmd "$decode_cmd" \
        --num-threads 4 \
        --model "$model_full_name" \
        --srcdir  $srcdir \
        --online-ivector-dir "" \
        $tree_dir/graph \
        data/mfcc/test \
        $output/decode_lang-$model_only_name-ssh || exit 1
fi


#if [ "$decode" = 'true' ]; then
#    decode_cmd="run.pl"
#
#    model_full_name=./exp/tri8b_tdnn_base/15-tune-output/69-epoch-9-iteration-6.mdl
#    model_only_name=$(basename $model_full_name)
#
#    frames_per_chunk=140
#    nspk=$(wc -l <data/mfcc/test/spk2utt)
#    tree_dir=exp/tri7b_tree
#    local/nnet3/decode.sh --stage 2 \
#        --acwt 1.0 --post-decode-acwt 10.0 \
#        --extra-left-context 0 --extra-right-context 0 \
#        --extra-left-context-initial 0 \
#        --extra-right-context-final 0 \
#        --frames-per-chunk $frames_per_chunk \
#        --nj $nspk --cmd "$decode_cmd" \
#        --num-threads 4 \
#        --model "$model_full_name" \
#        --srcdir  $srcdir \
#        --online-ivector-dir "" \
#        $tree_dir/graph \
#        data/mfcc/test \
#        $output/decode_lang-$model_only_name || exit 1
#fi

