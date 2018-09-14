#!/bin/bash

# Step by Step understand Kaldi using thchs30, By Ban

H=`pwd`  #exp home

#corpus and trans directory
thchs=/home/speech/aban/t

. cmd.sh
. path.sh

n=10

# 1. prepare data
#
#
# generate standart files for Kaldi
local/data_pre.sh $H $thchs/data_thchs30 || exit 1;


# 2. compute features
#    output: data/mfcc/train/feats.scp
#            data/mfcc/train/cmvn.scp
#            all the features stored into mfcc/{train,dev,test}

rm -rf data/mfcc && mkdir -p data/mfcc &&  cp -R data/{train,dev,test,test_phone} data/mfcc || exit 1;
for x in train dev test; do
   #make mfcc
   #make_mfcc.sh      [options]                  <data-dir>   <log-dir>         <mfcc-dir>
   steps/make_mfcc.sh --nj $n --cmd "$train_cmd" data/mfcc/$x exp/make_mfcc/$x  mfcc/$x     || exit 1;

   #compute cmvn
   #steps/compute_cmvn_stats.sh [options] <data-dir>    <log-dir>         <cmvn-dir> 
   steps/compute_cmvn_stats.sh            data/mfcc/$x  exp/mfcc_cmvn/$x  mfcc/$x    || exit 1;
done
#copy feats.scp and cmvn.scp in mfcc/test direcroty into test_phone direcroty
cp data/mfcc/test/feats.scp data/mfcc/test_phone && cp data/mfcc/test/cmvn.scp data/mfcc/test_phone || exit 1;

# 3. language stuff
#build a large lexicon that invovles words in both the training and decoding.
(
  echo "make word graph ..."
  cd $H; mkdir -p data/{dict,lang,graph} && \
  cp $thchs/resource/dict/{extra_questions.txt,nonsilence_phones.txt,optional_silence.txt,silence_phones.txt} data/dict && \
  cat $thchs/resource/dict/lexicon.txt $thchs/data_thchs30/lm_word/lexicon.txt | \
  grep -v '<s>' | grep -v '</s>' | sort -u > data/dict/lexicon.txt || exit 1;
  utils/prepare_lang.sh --position_dependent_phones false data/dict "<SPOKEN_NOISE>" data/local/lang data/lang || exit 1;
  gzip -c $thchs/data_thchs30/lm_word/word.3gram.lm > data/graph/word.3gram.lm.gz || exit 1;
  utils/format_lm.sh data/lang data/graph/word.3gram.lm.gz $thchs/data_thchs30/lm_word/lexicon.txt data/graph/lang || exit 1;
)

#make_phone_graph
(
  echo "make phone graph ..."
  cd $H; mkdir -p data/{dict_phone,graph_phone,lang_phone} && \
  cp $thchs/resource/dict/{extra_questions.txt,nonsilence_phones.txt,optional_silence.txt,silence_phones.txt} data/dict_phone  && \
  cat $thchs/data_thchs30/lm_phone/lexicon.txt | grep -v '<eps>' | sort -u > data/dict_phone/lexicon.txt  && \
  echo "<SPOKEN_NOISE> sil " >> data/dict_phone/lexicon.txt  || exit 1;
  utils/prepare_lang.sh --position_dependent_phones false data/dict_phone "<SPOKEN_NOISE>" data/local/lang_phone data/lang_phone || exit 1;
  gzip -c $thchs/data_thchs30/lm_phone/phone.3gram.lm > data/graph_phone/phone.3gram.lm.gz  || exit 1;
  utils/format_lm.sh data/lang_phone data/graph_phone/phone.3gram.lm.gz $thchs/data_thchs30/lm_phone/lexicon.txt \
    data/graph_phone/lang  || exit 1;
)

# 4. generate fbanks for NNET3

#if [ $stage -le 0 ]; then
  echo "DNN training: stage 0: feature generation"
  rm -rf data/fbank fbank && mkdir -p data/fbank &&  cp -R data/{train,dev,test,test_phone} data/fbank || exit 1;
  for x in train dev test; do
    echo "producing fbank for $x"
    #fbank generation
    steps/make_fbank.sh --nj $n --cmd "$train_cmd" data/fbank/$x exp/make_fbank/$x fbank/$x || exit 1
    #ompute cmvn
    steps/compute_cmvn_stats.sh data/fbank/$x exp/fbank_cmvn/$x fbank/$x || exit 1
  done

  echo "producing test_fbank_phone"
  cp data/fbank/test/feats.scp data/fbank/test_phone && cp data/fbank/test/cmvn.scp data/fbank/test_phone || exit 1;
#fi


# 5. aligning

# 5.1 training a monophone model. the aligned data is in exp/mono
steps/train_mono.sh --boost-silence 1.25 --nj $n --cmd "$train_cmd" data/mfcc/train data/lang exp/mono || exit 1;
steps/align_si.sh --boost-silence 1.25 --nj $n --cmd "$train_cmd" data/mfcc/train data/lang exp/mono exp/mono_ali || exit 1;

# 5.2 triphone model
steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" 2000 10000 data/mfcc/train data/lang exp/mono_ali exp/tri1 || exit 1; 
steps/align_si.sh --nj $n --cmd "$train_cmd" data/mfcc/train data/lang exp/tri1 exp/tri1_ali || exit 1;

# 5.3 lda_mllt
steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" 2500 15000 data/mfcc/train data/lang exp/tri1_ali exp/tri2b || exit 1;
steps/align_si.sh  --nj $n --cmd "$train_cmd" --use-graphs true data/mfcc/train data/lang exp/tri2b exp/tri2b_ali || exit 1;

# 5.4 sat
steps/train_sat.sh --cmd "$train_cmd" 2500 15000 data/mfcc/train data/lang exp/tri2b_ali exp/tri3b || exit 1;
steps/align_fmllr.sh --nj $n --cmd "$train_cmd" data/mfcc/train data/lang exp/tri3b exp/tri3b_ali || exit 1;

# 5.5 quick
steps/train_quick.sh --cmd "$train_cmd" 4200 40000 data/mfcc/train data/lang exp/tri3b_ali exp/tri4b || exit 1;
steps/align_fmllr.sh --nj $n --cmd "$train_cmd" data/mfcc/train data/lang exp/tri4b exp/tri4b_ali || exit 1;
# please decoding ... 
local/thchs-30_decode.sh --nj 10 "steps/decode_fmllr.sh" exp/tri4b data/mfcc 



#n=8
#local/nnet3/run_tdnn.sh --stage 0 --nj $n exp/tri5b || exit 1;

