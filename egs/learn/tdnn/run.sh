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
n=8
thchs=/home/aban/data/thchs30

stage=14


if [ $stage -le 1 ]; then
    local/thchs-30_data_prep.sh $H $thchs/data_thchs30 || exit 1;
fi

if [ $stage -le 2 ]; then
    rm -rf data/mfcc && mkdir -p data/mfcc &&  \
        cp -R data/{train,dev,test,test_phone} data/mfcc || exit 1;

    for x in train dev test; do
        #make  mfcc
        steps/make_mfcc.sh --nj $n --cmd "$train_cmd" \
            data/mfcc/$x exp/make_mfcc/$x mfcc/$x || exit 1;

        #compute cmvn
        steps/compute_cmvn_stats.sh \
            data/mfcc/$x exp/mfcc_cmvn/$x mfcc/$x || exit 1;
    done
    #copy feats and cmvn to test.ph, avoid duplicated mfcc & cmvn
    cp data/mfcc/test/feats.scp data/mfcc/test_phone && \
        cp data/mfcc/test/cmvn.scp data/mfcc/test_phone || exit 1;
fi

if [ $stage -le 3 ]; then
    steps/train_mono.sh \
        --boost-silence 1.25 \
        --nj $n \
        --cmd "$train_cmd" \
        data/mfcc/train \
        data/lang \
        exp/mono || exit 1;
fi

if [ $stage -le 4 ]; then
    local/thchs-30_decode.sh \
        --mono true \
        --nj $n \
        "steps/decode.sh" \
        exp/mono \
        data/mfcc
fi

if [ $stage -le 5 ]; then
    steps/align_si.sh \
        --boost-silence 1.25 \
        --nj $n --cmd "$train_cmd" \
        data/mfcc/train data/lang \
        exp/mono exp/mono_ali || exit 1;
fi

if [ $stage -le 6 ]; then
    steps/train_deltas.sh \
        --boost-silence 1.25 \
        --cmd "$train_cmd" 2000 6000 \
        data/mfcc/train \
        data/lang \
        exp/mono_ali exp/tri1 || exit 1;
fi

if [ $stage -le 7 ]; then

    steps/align_si.sh \
        --nj $n --cmd "$train_cmd" \
        data/mfcc/train data/lang \
        exp/tri1 exp/tri1_ali || exit 1;

    steps/train_deltas.sh \
        --boost-silence 1.25 \
        --cmd "$train_cmd" 2000 6000 \
        data/mfcc/train \
        data/lang \
        exp/tri1_ali exp/tri2 || exit 1;
fi


if [ $stage -le 8 ]; then

    steps/align_si.sh \
        --nj $n --cmd "$train_cmd" \
        data/mfcc/train data/lang \
        exp/tri2 exp/tri2_ali || exit 1;

    steps/train_lda_mllt.sh \
        --cmd "$train_cmd" \
        --splice-opts      \
        "--left-context=3 --right-context=3" \
        2500 15000 \
        data/mfcc/train data/lang \
        exp/tri2_ali exp/tri3b || exit 1;

fi

if [ $stage -le 9 ]; then

    steps/align_si.sh \
        --nj $n --cmd "$train_cmd" \
        data/mfcc/train data/lang \
        exp/tri3b exp/tri3b_ali || exit 1;

    steps/train_lda_mllt.sh \
        --cmd "$train_cmd" \
        --splice-opts      \
        "--left-context=3 --right-context=3" \
        2000 10000 \
        data/mfcc/train data/lang \
        exp/tri3b_ali exp/tri4b || exit 1;

fi

if [ $stage -le 10 ]; then

    steps/align_si.sh \
        --nj $n --cmd "$train_cmd" \
        data/mfcc/train data/lang \
        exp/tri4b exp/tri4b_ali || exit 1;

    steps/train_sat.sh \
        --cmd "$train_cmd" \
        1000 15000 \
        data/mfcc/train data/lang \
        exp/tri4b_ali exp/tri5b || exit 1;

fi

if [ $stage -le 11 ]; then

    steps/align_fmllr.sh \
        --nj $n --cmd "$train_cmd" \
        data/mfcc/train data/lang \
        exp/tri5b exp/tri5b_ali || exit 1;

    steps/train_sat.sh \
        --cmd "$train_cmd" \
        1000 15000 \
        data/mfcc/train data/lang \
        exp/tri5b_ali exp/tri6b || exit 1;

fi


if [ $stage -le 12 ]; then

    steps/align_fmllr.sh \
        --nj $n --cmd "$train_cmd" \
        data/mfcc/train data/lang \
        exp/tri6b exp/tri6b_ali || exit 1;


    steps/train_quick.sh \
        --cmd "$train_cmd" \
        800 20000 data/mfcc/train data/lang \
        exp/tri6b_ali exp/tri7b || exit 1;

fi

if [ $stage -le 13 ]; then
    local/thchs-30_decode.sh \
        --nj $n "steps/decode_fmllr.sh" exp/tri7b data/mfcc 
fi


if [ $stage -le 14 ]; then
    steps/align_fmllr.sh \
        --nj $n --cmd "$train_cmd" \
        data/mfcc/train data/lang \
        exp/tri7b exp/tri7b_ali || exit 1;
fi



