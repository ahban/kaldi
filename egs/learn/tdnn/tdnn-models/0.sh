#!/bin/bash
###############################################################################
# file name    : 0.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Thu 23 Jul 2020 11:37:23 AM CST
###############################################################################
 . ../path.sh

dir=./trash/tdnn
dst_dir=/home/aban/devel/ca/src/nn-tests/tdnn-models
xent_regularize=0.1
stage=-1

model_name=$(dirname $0)/$(basename $0 .sh).raw
model_txt=$(dirname $0)/$(basename $0 .sh).txt
echo $model_name


cp $(dirname $0)/lda.mat $dir/configs/lda.mat

if [ $stage -le 4 ]; then
    echo "$0: creating neural net configs using the xconfig parser";

    #num_targets=$(tree-info $tree_dir/tree |grep num-pdfs|awk '{print $2}')
    num_targets=880
    learning_rate_factor=$(echo "print (0.5/$xent_regularize)" | python)

    mkdir -p $dir/configs

#    cat <<EOF > $dir/configs/lda.mat
#    [
#    0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.5 
#    0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.5 
#    0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.5 
#    0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.5 
#    0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.5 
#    0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.5 
#    0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.5 
#    0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.5 
#    0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.5]
#EOF


    cat <<EOF > $dir/configs/network.xconfig

    input dim=13 name=input
    fixed-affine-layer name=lda input=Append(-2,-1,0,1,2) affine-transform-file=$dir/configs/lda.mat
    relu-renorm-layer name=tdnn1 input=Append(-2,1) dim=26
    relu-renorm-layer name=tdnn2 input=Append(-1,2) dim=26

    ## adding the layers for chain branch
    relu-renorm-layer name=prefinal-chain input=tdnn2 dim=26 target-rms=0.5
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
    relu-renorm-layer name=prefinal-xent input=tdnn2 dim=26 target-rms=0.5
    output-layer name=output-xent dim=$num_targets learning-rate-factor=$learning_rate_factor max-change=1.5

EOF
    steps/nnet3/xconfig_to_configs.py --xconfig-file $dir/configs/network.xconfig --config-dir $dir/configs/
fi

sed  "s| param-stddev=0.0 bias-stddev=0.0||" $dir/configs/final.config > \
    $dir/configs/final.nosalce0.config

nnet3-init $dir/configs/final.nosalce0.config $model_name 
nnet3-copy --binary=false $model_name $model_txt


ssh sun "mkdir -p $dst_dir"
mkdir -p $dst_dir
scp $model_name $model_txt aban@sun:$dst_dir
cp $model_name $model_txt $dst_dir 
