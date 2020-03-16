../../../src/chainbin/nnet3-chain-compute-prob \
    --computation.debug=true \
    --l2-regularize=0.0 \
    --leaky-hmm-coefficient=0.1 \
    --xent-regularize=0.1 \
    exp/tri8b_debug/0.debug.mdl.txt \
    exp/tri8b_debug/den.fst \
    "ark,bg:nnet3-chain-copy-egs  ark:exp/tri8b_debug/egs/valid_diagnostic.cegs ark:-| nnet3-chain-merge-egs --minibatch-size=1:64 ark:- ark:- |"
