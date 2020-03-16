#!/bin/bash
###############################################################################
# file name    : debug-tdnn-chain.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Fri 06 Mar 2020 04:45:56 PM CST
###############################################################################

. path.sh
. cmd.sh

stage=4
num_debug=100

egs_org=./exp/tri8b/egs/cegs.1.ark
egs_new=./trash/cegs.debug.ark

if [ $stage -le 1 ]; then
    nnet3-chain-subset-egs --n=$num_debug ark:$egs_org ark:$egs_new
fi


srand=0
xent_regularize=0.1
chunk_width=140,100,160
online_cmvn=false
remove_egs=false
data_dir=data/mfcc/train
tree_dir=exp/tri7b_tree
lat_dir=exp/tri7b_lats
dir=exp/tri8b_debug


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


if [ $stage -le 5 ]; then
    steps/nnet3/chain/aban-train.py --stage=-10 \
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

