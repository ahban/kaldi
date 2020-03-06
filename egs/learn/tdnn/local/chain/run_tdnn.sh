#!/bin/bash
###############################################################################
# file name    : local/chain/run_tdnn.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Fri 06 Mar 2020 09:29:00 AM CST
###############################################################################

set -e -o pipefail

# configs for 'chain'
stage=7
train_stage=-10
nj=8

# training options
num_epochs=4
initial_effective_lrate=0.001
final_effective_lrate=0.0001
leftmost_questions_truncate=-1
max_param_change=2.0
final_layer_normalize_target=0.5
num_jobs_initial=1
num_jobs_final=4
minibatch_size=256
frames_per_eg=150
remove_egs=false
common_egs_dir=
xent_regularize=0.1

srand=0
chunk_width=140,100,160
# End configuration section.


echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

if ! cuda-compiled; then
  cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi 
with CUDA. If you want to use GPUs (and have them), go to src/, and configure 
and make on a machine where "nvcc" is installed.
EOF
fi

#work_dir=/home/storage/speech/kaldi/egs/keyword/s5_cm
work_dir=$(pwd)
old_lang=$work_dir/data/lang
lang=$work_dir/data/lang_chain

data_dir=${work_dir}/data/mfcc/train
gmm_dir=${work_dir}/exp/tri7b
lat_dir=${work_dir}/exp/tri7b_lats
tree_dir=${work_dir}/exp/tri7b_tree
ali_dir=${work_dir}/exp/tri7b_ali
dir=${work_dir}/exp/tri8b

if [ $stage -le 1 ]; then
    echo "$0: creating lang directory $lang with chain-type topology"
    # Create a version of the lang/ directory that has one state per phone in the
    # topo file. [note, it really has two states.. the first one is only repeated
    # once, the second one has zero or more repeats.]
    if [ -d $lang ]; then
        if [ $lang/L.fst -nt data/lang/L.fst ]; then
            echo "$0: $lang already exists, not overwriting it; continuing"
        else
            echo "$0: $lang already exists and seems to be older than data/lang..."
            echo " ... not sure what to do.  Exiting."
            exit 1;
        fi
    else
        cp -r $old_lang $lang
        silphonelist=$(cat $lang/phones/silence.csl) || exit 1;
        nonsilphonelist=$(cat $lang/phones/nonsilence.csl) || exit 1;
        # Use our special topology... note that later on may have to tune this
        # topology.
        steps/nnet3/chain/gen_topo.py $nonsilphonelist $silphonelist >$lang/topo
    fi
fi

if [ $stage -le 2 ]; then
    echo "$0 get alignment as lattices" 

    steps/align_fmllr_lats.sh --nj $nj --cmd "$train_cmd" \
        $data_dir \
        data/lang $gmm_dir $lat_dir
    rm $lat_dir/fsts.*.gz # save space
fi


if [ $stage -le 3 ]; then
    echo "$0 buiding new tree"
    # Build a tree using our new topology.  We know we have alignments for the
    # speed-perturbed data (local/nnet3/run_ivector_common.sh made them), so use
    # those.  The num-leaves is always somewhat less than the num-leaves from
    # the GMM baseline.
    if [ -f $tree_dir/final.mdl ]; then
        echo "$0: $tree_dir/final.mdl already exists, refusing to overwrite it."
        exit 1;
    fi
    steps/nnet3/chain/build_tree.sh \
        --frame-subsampling-factor 3 \
        --context-opts "--context-width=2 --central-position=1" \
        --cmd "$train_cmd" 1000 ${data_dir} \
        $lang $ali_dir $tree_dir
fi

if [ $stage -le 4 ]; then
    echo "$0: creating neural net configs using the xconfig parser";

    num_targets=$(tree-info $tree_dir/tree |grep num-pdfs|awk '{print $2}')
    learning_rate_factor=$(echo "print 0.5/$xent_regularize" | python)

    mkdir -p $dir/configs
    cat <<EOF > $dir/configs/network.xconfig

    input dim=13 name=input

    fixed-affine-layer name=lda input=Append(-2,-1,0,1,2) affine-transform-file=$dir/configs/lda.mat

    # the first splicing is moved before the lda layer, so no splicing here
    relu-renorm-layer name=tdnn1 dim=256
    relu-renorm-layer name=tdnn2 input=Append(-1,2) dim=256
    relu-renorm-layer name=tdnn3 input=Append(-2,1) dim=256
    relu-renorm-layer name=tdnn4 input=Append(-3,3) dim=256
    relu-renorm-layer name=tdnn5 input=Append(-5,1) dim=256

    ## adding the layers for chain branch
    relu-renorm-layer name=prefinal-chain input=tdnn5 dim=256 target-rms=0.5
    output-layer name=output include-log-softmax=false dim=$num_targets max-change=1.5

    # adding the layers for xent branch
    # This block prints the configs for a separate output that will be
    # trained with a cross-entropy objective in the 'chain' models... this
    # has the effect of regularizing the hidden parts of the model.  we use
    # 0.5 / args.xent_regularize as the learning rate factor- the factor of
    # 0.5 / args.xent_regularize is suitable as it means the xent
    # final-layer learns at a rate independent of the regularization
    # constant; and the 0.5 was tuned so as to make the relative progress
    # similar in the xent and regular final layers.
    relu-renorm-layer name=prefinal-xent input=tdnn5 dim=256 target-rms=0.5
    output-layer name=output-xent dim=$num_targets learning-rate-factor=$learning_rate_factor max-change=1.5

EOF
    steps/nnet3/xconfig_to_configs.py --xconfig-file $dir/configs/network.xconfig --config-dir $dir/configs/
fi


online_cmvn=false
if [ $stage -le 5 ]; then
  if [[ $(hostname -f) == *.clsp.jhu.edu ]] && [ ! -d $dir/egs/storage ]; then
    utils/create_split_dir.pl \
     /export/b0{3,4,5,6}/$USER/kaldi-data/egs/wsj-$(date +'%m_%d_%H_%M')/s5/$dir/egs/storage $dir/egs/storage
  fi

  steps/nnet3/chain/train.py --stage=-2 \
    --cmd="$decode_cmd" \
    --feat.online-ivector-dir=$train_ivector_dir \
    --feat.cmvn-opts="--norm-means=true --norm-vars=true" \
    --chain.xent-regularize $xent_regularize \
    --chain.leaky-hmm-coefficient=0.1 \
    --chain.l2-regularize=0.0 \
    --chain.apply-deriv-weights=false \
    --chain.lm-opts="--num-extra-lm-states=2000" \
    --trainer.add-option="--optimization.memory-compression-level=2" \
    --trainer.srand=$srand \
    --trainer.max-param-change=2.0 \
    --trainer.num-epochs=10 \
    --trainer.frames-per-iter=2000000 \
    --trainer.optimization.num-jobs-initial=4 \
    --trainer.optimization.num-jobs-final=4 \
    --trainer.optimization.initial-effective-lrate=0.0005 \
    --trainer.optimization.final-effective-lrate=0.00005 \
    --trainer.num-chunk-per-minibatch=128,64 \
    --trainer.optimization.momentum=0.0 \
    --egs.chunk-width=$chunk_width \
    --egs.chunk-left-context=0 \
    --egs.chunk-right-context=0 \
    --egs.dir="$common_egs_dir" \
    --egs.opts="--frames-overlap-per-eg 0 --online-cmvn $online_cmvn" \
    --cleanup.remove-egs=$remove_egs \
    --use-gpu=true \
    --reporting.email="$reporting_email" \
    --feat-dir=$data_dir \
    --tree-dir=$tree_dir \
    --lat-dir=$lat_dir \
    --dir=$dir  || exit 1;
fi

if [ $stage -le 6 ]; then
  # The reason we are using data/lang here, instead of $lang, is just to
  # emphasize that it's not actually important to give mkgraph.sh the
  # lang directory with the matched topology (since it gets the
  # topology file from the model).  So you could give it a different
  # lang directory, one that contained a wordlist and LM of your choice,
  # as long as phones.txt was compatible.

  #utils/lang/check_phones_compatible.sh \
  #  data/lang_test_tgpr/phones.txt $lang/phones.txt
  #utils/mkgraph.sh \
  #  --self-loop-scale 1.0 data/lang_test_tgpr \
  #  $tree_dir $tree_dir/graph_tgpr || exit 1;

  #utils/lang/check_phones_compatible.sh \
  #  data/lang_test_bd_tgpr/phones.txt $lang/phones.txt
  #utils/mkgraph.sh \
  #  --self-loop-scale 1.0 data/lang_test_bd_tgpr \
  #  $tree_dir $tree_dir/graph_bd_tgpr || exit 1;
 
  utils/mkgraph.sh \
      --self-loop-scale 1.0 \
      data/graph/lang \
      $tree_dir $tree_dir/graph || exit 1;

  utils/mkgraph.sh \
      --self-loop-scale 1.0 \
      data/graph_phone/lang \
      $tree_dir $tree_dir/graph_phone || exit 1;
fi

if [ $stage -le 7 ]; then
    frames_per_chunk=$(echo $chunk_width | cut -d, -f1)
    nspk=$(wc -l <data/mfcc/test/spk2utt)
    steps/nnet3/decode.sh \
        --acwt 1.0 --post-decode-acwt 10.0 \
        --extra-left-context 0 --extra-right-context 0 \
        --extra-left-context-initial 0 \
        --extra-right-context-final 0 \
        --frames-per-chunk $frames_per_chunk \
        --nj $nspk --cmd "$decode_cmd"  --num-threads 4 \
        --online-ivector-dir "" \
        $tree_dir/graph data/mfcc/test ${dir}/decode_lang || exit 1
fi

if [ $stage -le 8 ]; then
    frames_per_chunk=$(echo $chunk_width | cut -d, -f1)
    nspk=$(wc -l <data/mfcc/test/spk2utt)
    steps/nnet3/decode.sh \
        --acwt 1.0 --post-decode-acwt 10.0 \
        --extra-left-context 0 --extra-right-context 0 \
        --extra-left-context-initial 0 \
        --extra-right-context-final 0 \
        --frames-per-chunk $frames_per_chunk \
        --nj $nspk --cmd "$decode_cmd"  --num-threads 4 \
        --online-ivector-dir "" \
        $tree_dir/graph_phone data/mfcc/test_phone ${dir}/decode_phone || exit 1
fi

