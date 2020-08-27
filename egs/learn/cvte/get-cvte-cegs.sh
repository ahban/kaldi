#!/bin/bash
###############################################################################
# file name    : get-cvte-cegs.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Thu 27 Aug 2020 09:35:45 AM CST
###############################################################################

# modify from local/chain/run_tdnn.sh 

. path.sh || exit 1;

stage=-1

# inputs
cvte_data=/home/data/aban/data/1w/data
data_dir=${cvte_data}/train_10000
ali_dir=${cvte_data}/../tune/3L-Smbr-gcmvn/alis
num_leaves=8000 # number of pdf, keywords may need a smaller number <- aban


# outputs
lang=data/lang_chain
tree_dir=./exp/3L-Smbr-gcmvn-tree

if [ $stage -le 12 ]; then
    
    echo "$0: creating lang directory $lang with chain-type topology"
    printf "$0: note that L.fst (phones to words) used here is for asr not keywords\n\n"
    # Create a version of the lang/ directory that has one state per phone in the
    # topo file. [note, it really has two states.. the first one is only repeated
    # once, the second one has zero or more repeats.]
    if [ -d $lang ]; then
        if [ $lang/L.fst -nt $cvte_data/lang/L.fst ]; then
            echo "$0: $lang already exists, not overwriting it; continuing"
        else
            echo "$0: $lang already exists and seems to be older than data/lang..."
            echo " ... not sure what to do.  Exiting."
            exit 1;
        fi
    else
        cp -rL $cvte_data/lang $lang
        silphonelist=$(cat $lang/phones/silence.csl) || exit 1;
        nonsilphonelist=$(cat $lang/phones/nonsilence.csl) || exit 1;
        # Use our special topology... note that later on may have to tune this
        # topology.
        steps/nnet3/chain/gen_topo.py $nonsilphonelist $silphonelist >$lang/topo
    fi
    printf "done this stage\n\n"
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

    local/chain/build_tree.sh \
        --frame-subsampling-factor 3 \
        --context-opts "--context-width=2 --central-position=1" \
        --cmd "$train_cmd" $num_leaves ${data_dir} \
        $lang $ali_dir $tree_dir
fi


