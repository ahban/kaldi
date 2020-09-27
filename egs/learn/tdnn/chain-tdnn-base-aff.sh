#!/bin/bash
###############################################################################
# file name    : debug-tdnn-chain.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Fri 06 Mar 2020 04:45:56 PM CST
###############################################################################

. path.sh
. cmd.sh

export CUDA_VISIBLE_DEVICES=0,1

stage=5
#num_debug=100

#egs_org=./exp/tri8b/egs/cegs.1.ark
#egs_new=./trash/cegs.debug.ark

#if [ $stage -le 1 ]; then
    #nnet3-chain-subset-egs --n=$num_debug ark:$egs_org ark:$egs_new
#fi


srand=0
xent_regularize=0.1
chunk_width=140,100,160
online_cmvn=false
remove_egs=false
data_dir=data/mfcc/train
tree_dir=exp/tri7b_tree
lat_dir=exp/tri7b_lats
dir=exp/tri8b_tdnn_base_aff

log_sub_dir=log-same-minibatch-size
log_sub_dir=log-same-minibatch-size-smaller-lr

if [ $stage -le 4 ]; then
    echo "$0: creating neural net configs using the xconfig parser";

    num_targets=$(tree-info $tree_dir/tree |grep num-pdfs|awk '{print $2}')
    learning_rate_factor=$(echo "print (0.5/$xent_regularize)" | python)

    mkdir -p $dir/configs
    cat <<EOF > $dir/configs/network.xconfig

    input dim=13 name=input

    # fixed-affine-layer name=lda input=Append(-2,-1,0,1,2) affine-transform-file=$dir/configs/lda.mat

    # the first splicing is moved before the lda layer, so no splicing here
    # relu-renorm-layer name=tdnn1 dim=256
    relu-renorm-layer name=tdnn1 input=Append(-2,-1,0,1,2) dim=256
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

sed -i 's|NaturalGradient||g' $dir/configs/final.config 


if [ $stage -le 5 ]; then

    mkdir -p $dir/$log_sub_dir
    rm $dir/log || { echo "faile to remove a linkage, is it a real linkage?"; exit 1; }
    ln -s $log_sub_dir $dir/log

    steps/nnet3/chain/train.py --stage=0 \
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
        --trainer.optimization.num-jobs-initial=2 \
        --trainer.optimization.num-jobs-final=2 \
        --trainer.optimization.initial-effective-lrate=0.0001 \
        --trainer.optimization.final-effective-lrate=0.00001 \
        --trainer.num-chunk-per-minibatch=128,64,32 \
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



utils/mkgraph.sh \
    --self-loop-scale 1.0 \
    data/graph/lang \
    $tree_dir $tree_dir/graph || exit 1;

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

cat $dir/decode_lang/scoring_kaldi/best_wer
