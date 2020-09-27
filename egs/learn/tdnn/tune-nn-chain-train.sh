#!/bin/bash
###############################################################################
#  file name    : ./nn-chain-train.sh
#  authors      : Ban Zhihua(2018-2020)
#  contact      : sawpara@126.com
#  created time : Tue 15 Sep 2020 06:35:34 PM CST
###############################################################################

export CUDA_VISIBLE_DEVICES=4,5

data_dir=/home/aban/devel/aban-kaldi/egs/learn/tdnn/exp/tri8b_tdnn_base

decode=false

# exp1
name="1-tune"
lr_cfg='learning-rate-schedule-kaldi learning-rate-init=1e-4 learning-rate-final=1e-5'
mb_opt='momentum-sgd max-change=2 momentum=0.75'
it_opt='model-average'

# exp2
name="2-tune"
lr_cfg='learning-rate-schedule-kaldi learning-rate-init=1e-4 learning-rate-final=1e-5'
mb_opt='momentum-sgd max-change=2 momentum=0.65'
it_opt='model-average'

# exp3
name="3-tune"
lr_cfg='learning-rate-schedule-kaldi learning-rate-init=1e-4 learning-rate-final=1e-5'
mb_opt='momentum-sgd max-change=2 momentum=0.55'
it_opt='model-average'

# exp4
name="4-tune"
lr_cfg='learning-rate-schedule-kaldi learning-rate-init=1e-4 learning-rate-final=1e-5'
mb_opt='momentum-sgd max-change=2 momentum=0.45'
it_opt='model-average'


# exp5
name="5-tune"
lr_cfg='learning-rate-schedule-kaldi learning-rate-init=5e-4 learning-rate-final=5e-5'
#mb_opt='momentum-sgd max-change=2 momentum=0'
mb_opt='adam max-change=2'
it_opt='model-average-history'
num_epoches=10


# exp6
name="6-tune"
lr_cfg='learning-rate-schedule-kaldi learning-rate-init=5e-4 learning-rate-final=5e-5'
#mb_opt='momentum-sgd max-change=2 momentum=0'
mb_opt='adam max-change=2'
it_opt='model-average-history'
num_epoches=12

# exp7
name="7-tune"
lr_cfg='learning-rate-schedule-kaldi learning-rate-init=5e-4 learning-rate-final=5e-5'
mb_opt='adam max-change=2'
it_opt='model-average-history'
num_epoches=14

# exp8
name="8-tune"
lr_cfg='learning-rate-schedule-kaldi learning-rate-init=1e-3 learning-rate-final=1e-4'
mb_opt='adam max-change=2'
it_opt='model-average-history'
num_epoches=10

# exp9
name="9-tune"
lr_cfg='learning-rate-schedule-kaldi learning-rate-init=1e-3 learning-rate-final=2e-4'
mb_opt='adam max-change=2'
it_opt='model-average-history'
num_epoches=10

# exp10
name="10-tune"
lr_cfg='learning-rate-schedule-kaldi learning-rate-init=1e-3 learning-rate-final=2e-4'
mb_opt='adam max-change=2'
it_opt='model-average-history'
num_epoches=12

# exp11
name="11-tune"
lr_cfg='learning-rate-schedule-kaldi learning-rate-init=1e-3 learning-rate-final=2e-4'
mb_opt='adam max-change=2'
it_opt='model-average-history'
num_epoches=12

# exp12
name="12-tune"
lr_cfg='learning-rate-schedule-kaldi learning-rate-init=1e-3 learning-rate-final=2e-4'
mb_opt='adam max-change=2'
it_opt='model-average-history'
num_epoches=10



# exp13
name="13-tune"
mb_cfg="100=128"
lr_cfg='learning-rate-schedule-kaldi learning-rate-init=5e-4 learning-rate-final=5e-5'
mb_opt='momentum-sgd max-change=2 momentum=0'
it_opt='model-average'
num_mbs_per_iter=100
num_epoches=10


# exp14
name="14-tune"
mb_cfg="100=128"
lr_cfg='learning-rate-schedule-kaldi learning-rate-init=5e-4 learning-rate-final=5e-5'
mb_opt='momentum-sgd max-change=2 momentum=0'
it_opt='model-average'
num_mbs_per_iter=110
num_epoches=10

# exp15
name="15-tune"
mb_cfg="100=128"
lr_cfg='learning-rate-schedule-kaldi learning-rate-init=1e-4 learning-rate-final=1e-5'
mb_opt='momentum-sgd max-change=2 momentum=0'
it_opt='model-average'
num_mbs_per_iter=110
num_epoches=10

# exp16
#name="16-tune"
#mb_cfg="100=128"
#lr_cfg='learning-rate-schedule-kaldi learning-rate-init=1e-4 learning-rate-final=1e-5'
#mb_opt='momentum-sgd max-change=2 momentum=0.65'
#it_opt='model-average'
#num_mbs_per_iter=110
#num_epoches=10

# exp17
#name="17-tune"
#mb_cfg="100=128"
#lr_cfg='learning-rate-schedule-kaldi learning-rate-init=1e-4 learning-rate-final=1e-5'
#mb_opt='momentum-sgd max-change=2 momentum=0.55'
#it_opt='model-average'
#num_mbs_per_iter=110
#num_epoches=10


#  exp18
name="18-tune"
mb_cfg="100=128"
lr_cfg='learning-rate-schedule-kaldi learning-rate-init=1e-4 learning-rate-final=1e-5'
mb_opt='momentum-sgd max-change=2 momentum=0.45'
it_opt='model-average'
num_mbs_per_iter=110
num_epoches=10


output="$data_dir/$name-output"

if [ ! -d $output ]; then
    mkdir -p $output

    /home/aban/devel/ca/src/nn-tests/nn-chain-train.r.exe \
        --log $output/log.txt \
        --verbose 0 \
        --data.example.file-with-max-buffer  $data_dir/examples.max  \
        --data.example.info-file             $data_dir/examples.info \
        --data.example.num-frame-shifts      3   \
        --data.monitor.interval              0   \
        --data.rings.producers-mb-num        4   \
        --data.rings.num-default-db-buffers  4   \
        --data.rings.num-default-mb-shape-buffers 10 \
        \
        --train.common.raw-net           $data_dir/0.raw     \
        --train.common.transition-model  $data_dir/0.mdl     \
        --train.common.denominitor       $data_dir/den.fst   \
        --train.common.sub-approximate-frames-to-train 0     \
        --train.common.num-epoches                     $num_epoches    \
        --train.common.num-minibatches-per-iteration   $num_mbs_per_iter  \
        --train.common.slave-gpus                      '1;0' \
        --train.learning-rate-configure   "$lr_cfg" \
        --train.minibatch.configure       "$mb_opt" \
        --train.iteration.optimizer       "$it_opt" \
        --train.obj.xent-regularize       0.1 \
        --train.obj.leaky-hmm-coefficient 0.1 \
        --train.obj.l2-regularize         0.0 \
        --train.output-dir $output \
        --train.common.minibatch-configure "$mb_cfg"

    decode=true
fi

if [ -d $output ]; then
    model_full_name=`ls -rt $output/*.mdl | grep -E '/[0-9]+.*mdl$' | tail -1`
    model_only_name=$(basename $model_full_name)
fi

decode=true

if [ -d $output -a "$decode" = 'true' ]; then
    . cmd.sh

    frames_per_chunk=140
    nspk=$(wc -l <data/mfcc/test/spk2utt)
    tree_dir=exp/tri7b_tree
    local/nnet3/decode.sh \
        --acwt 1.0 --post-decode-acwt 10.0 \
        --extra-left-context 0 --extra-right-context 0 \
        --extra-left-context-initial 0 \
        --extra-right-context-final 0 \
        --frames-per-chunk $frames_per_chunk \
        --nj $nspk --cmd "$decode_cmd" \
        --num-threads 4 \
        --model "$model_full_name" \
        --srcdir  $data_dir \
        --online-ivector-dir "" \
        $tree_dir/graph data/mfcc/test $output/decode_lang-$model_only_name || exit 1
fi

wer=`grep -E "%WER" $output/decode_lang-$model_only_name/scoring_kaldi/best_wer | awk '{print $2}'`
grep -E "ep.*it.*mmi.*avg.*ce.*avg.*$" $output/log.txt | awk -F'[=/ h()]' '{print $2,$10,$25,$NF}' > $output/$name-$wer.txt
cat $output/$name-$wer.txt
cat $output/decode_lang-$model_only_name/scoring_kaldi/best_wer
scp $output/$name-$wer.txt sun:~/24-3/


