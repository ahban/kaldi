#!/bin/bash
###############################################################################
# file name    : init-a-tdnn.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Wed 08 Jul 2020 11:17:05 AM CST
###############################################################################

dir=./trash/tdnn

xent_regularize=0.1
stage=-1

. path.sh

if [ $stage -le 4 ]; then
    echo "$0: creating neural net configs using the xconfig parser";

    #num_targets=$(tree-info $tree_dir/tree |grep num-pdfs|awk '{print $2}')
    num_targets=2
    learning_rate_factor=$(echo "print (0.5/$xent_regularize)" | python)

    mkdir -p $dir/configs

    cat <<EOF > $dir/configs/network.xconfig

    input dim=3 name=input
    relu-renorm-layer name=tdnn1 input=input dim=3

    ## adding the layers for chain branch
    relu-renorm-layer name=prefinal-chain input=tdnn1 dim=4 target-rms=0.5
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
    relu-renorm-layer name=prefinal-xent input=tdnn1 dim=4 target-rms=0.5
    output-layer name=output-xent dim=$num_targets learning-rate-factor=$learning_rate_factor max-change=1.5

EOF
    steps/nnet3/xconfig_to_configs.py --xconfig-file $dir/configs/network.xconfig --config-dir $dir/configs/
fi
