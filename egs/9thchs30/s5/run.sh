#!/bin/bash

# Step by Step understand Kaldi using thchs30, By Ban

H=`pwd`  #exp home

thchs=/home/speech/aban/t

. cmd.sh
. path.sh

# 1. prepare data
##  
##  #corpus and trans directory
##  
##  # generate standart files for Kaldi
##  local/data_pre.sh $H $thchs/data_thchs30 || exit 1;


# 2. compute features
rm -rf data/mfcc && mkdir -p data/mfcc &&  cp -R data/{train,dev,test,test_phone} data/mfcc || exit 1;

n=10
for x in train dev test; do
   #make mfcc
   steps/make_mfcc.sh --nj $n --cmd "$train_cmd" data/mfcc/$x exp/make_mfcc/$x mfcc/$x || exit 1;
   #compute cmvn
   steps/compute_cmvn_stats.sh data/mfcc/$x exp/mfcc_cmvn/$x mfcc/$x || exit 1;
done

