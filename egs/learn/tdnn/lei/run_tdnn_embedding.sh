#!/bin/bash

set -e

# configs for 'chain'
stage=-10
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

# End configuration section.
echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

if ! cuda-compiled; then
  cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
fi

work_dir=/home/storage/speech/kaldi/egs/keyword/s5_cm
srcdir=$work_dir/exp_sil/mfcc_pitch/nnet3_tdnn6layers_8b_relu_train_12000
ali_dir=$work_dir/exp_sil/mfcc_pitch/nnet3_tdnn6layers_8b_relu_ali_train_12000_cm
data_dir=$work_dir/data/plp/train_12000_cm

old_lang=$work_dir/data/lang
new_lang=$work_dir/data/lang_chain

tree_dir=$work_dir/exp_sil/mfcc_pitch/chain/tdnn_ali_lats/nnet3_tdnn6layers_8b_relu_tree_train_12000_cm_class1000
lats_dir=$work_dir/exp_sil/mfcc_pitch/chain/tdnn_ali_lats/nnet3_tdnn6layers_8b_relu_lats_train_12000_cm

# step *) Get the alignments as lattices
if [ $stage -le 9 ]; then
  # nj=$(cat ${ali_dir}/num_jobs) || exit 1;
  nj=2
  # gmm using align_si_*** and tdnn using align_***
  local/nnet3/chain/align_lats.sh --nj $nj --cmd "ssh.pl" $data_dir \
    $new_lang $srcdir $lats_dir || exit 1;
  rm $lats_dir/fsts.*.gz # save space
fi

# step *) Get the new lang directory
if [ $stage -le 10 ]; then
  # Create a version of the lang/ directory that has one state per phone in the
  # topo file. [note, it really has two states.. the first one is only repeated
  # once, the second one has zero or more repeats.]
  # rm -rf $new_lang
  # cp -r $old_lang $new_lang
  silphonelist=$(cat $new_lang/phones/silence.csl) || exit 1;
  nonsilphonelist=$(cat $new_lang/phones/nonsilence.csl) || exit 1;
  # Use our special topology... note that later on may have to tune this
  # topology.
  steps/nnet3/chain/gen_topo.py $nonsilphonelist $silphonelist >$new_lang/topo
fi

# step *) Get the tree directory
if [ $stage -le 11 ]; then
  # Build a tree using our new topology. This is the critically different
  # step compared with other recipes.
  steps/nnet3/chain/build_tree.sh --frame-subsampling-factor 3 --stage -1 \
      --leftmost-questions-truncate $leftmost_questions_truncate \
      --context-opts "--context-width=2 --central-position=1" \
      --cmd "ssh.pl" 1000 $data_dir $new_lang $ali_dir $tree_dir
fi

# step *) generate the TDNN configs
dir=exp_sil_cm/plp/chain_class1000_basedTDNN/nnet3_tdnn6layers_9b_relu_offline_train_12000_cm

if [ $stage -le 12 ]; then
  echo "$0: creating neural net configs using the xconfig parser";

  num_targets=$(tree-info $tree_dir/tree |grep num-pdfs|awk '{print $2}')
  learning_rate_factor=$(echo "print 0.5/$xent_regularize" | python)

  mkdir -p $dir/configs
  cat <<EOF > $dir/configs/network.xconfig

  input dim=50 name=input

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

# chain model training
dir=exp_sil_cm/plp/chain_class1000_basedTDNN/nnet3_tdnn6layers_9b_relu_offline_train_12000_cm
egs_dir=exp_sil_cm/plp/chain_class1000_basedTDNN/nnet3_tdnn6layers_9b_relu_offline_train_12000_cm/egs

# # step 8) generate the phone_lm etc. and the most important cegs
nj=`cat $tree_dir/num_jobs` || exit 1;  # number of jobs in alignment dir.
# mkdir -p $dir/log
echo $nj > $dir/num_jobs
cp $tree_dir/tree $dir

echo "$0: creating phone language-model"
run.pl $dir/log/make_phone_lm.log \
chain-est-phone-lm $lm_opts \
 "ark:gunzip -c $tree_dir/ali.*.gz | ali-to-phones $tree_dir/final.mdl ark:- ark:- |" \
 $dir/phone_lm.fst || exit 1


echo "$0: creating denominator FST"
copy-transition-model $tree_dir/final.mdl $dir/0.trans_mdl
run.pl $dir/log/make_den_fst.log \
chain-make-den-fst $dir/tree $dir/0.trans_mdl $dir/phone_lm.fst \
   $dir/den.fst $dir/normalization.fst || exit 1;

. $dir/configs/vars || exit 1;
cmvn_opts="--norm-vars=true"
feat_type="raw"
frame_subsampling_factor=3         # default: 3
alignment_subsampling_factor=3     # default: 3
extra_left_context=0
chunk_width=150
frames_per_iter=1500000
extra_opts=()
extra_opts+=(--cmvn-opts "$cmvn_opts")
extra_opts+=(--feat-type $feat_type)

# we need a bit of extra left-context and right-context to allow for frame
# shifts (we use shifted version of the data for more variety).
extra_opts+=(--left-context $[$model_left_context+$frame_subsampling_factor/2+$extra_left_context])
extra_opts+=(--right-context $[$model_right_context+$frame_subsampling_factor/2])
echo "$0: calling get_egs.sh"
# local/nnet3/chain/get_egs_sliding.sh $egs_opts "${extra_opts[@]}" \
#   --frames-per-iter $frames_per_iter --stage -10 \
#   --cmd "run.pl" --nj 120 \
#   --right-tolerance 5 \
#   --left-tolerance 5 \
#   --frames-per-eg $chunk_width \
#   --frame-subsampling-factor $frame_subsampling_factor \
#   --alignment-subsampling-factor $alignment_subsampling_factor \
#   $data_dir $dir $lats_dir $egs_dir || exit 1;

# offline-cmvn
local/nnet3/chain/get_egs.sh $egs_opts "${extra_opts[@]}" \
  --frames-per-iter $frames_per_iter --stage -10 \
  --cmd "run.pl" --nj 122 \
  --right-tolerance 5 \
  --left-tolerance 5 \
  --frames-per-eg $chunk_width \
  --frame-subsampling-factor $frame_subsampling_factor \
  --alignment-subsampling-factor $alignment_subsampling_factor \
  $data_dir $dir $lats_dir $egs_dir || exit 1;

# step*) training
  steps/nnet3/chain/train.py --stage=-10 \
    --cmd="run.pl" \
    --feat.online-ivector-dir= \
    --feat.cmvn-opts="--norm-means=true --norm-vars=true" \
    --chain.xent-regularize $xent_regularize \
    --chain.leaky-hmm-coefficient=0.1 \
    --chain.l2-regularize=0.00005 \
    --chain.apply-deriv-weights=false \
    --chain.lm-opts="--num-extra-lm-states=2000" \
    --trainer.srand=0 \
    --trainer.max-param-change=2.0 \
    --trainer.num-epochs=6 \
    --trainer.frames-per-iter=1500000 \
    --trainer.optimization.num-jobs-initial=1 \
    --trainer.optimization.num-jobs-final=8 \
    --trainer.optimization.initial-effective-lrate=0.001 \
    --trainer.optimization.final-effective-lrate=0.0001 \
    --trainer.num-chunk-per-minibatch=256 \
    --egs.dir=$egs_dir \
    --egs.chunk-width=$chunk_width \
    --cleanup.remove-egs=false \
    --use-gpu=true \
    --feat-dir=$data_dir \
    --tree-dir=$tree_dir \
    --lat-dir=$lats_dir \
    --dir=$dir  || exit 1;

