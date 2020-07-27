/******************************************************************************
  > file name    : fake-chain-mb.cpp
  > author       : Ban Zhihua
  > contact      : sawpara@126.com
  > created time : Thu 23 Jul 2020 03:53:27 PM CST
******************************************************************************/
#include <iostream>
#include <string>
using namespace std;

#include "base/kaldi-common.h"
#include "util/common-utils.h"
#include "nnet3/nnet-chain-training.h"
#include "cudamatrix/cu-allocator.h"
#include "nnet3/nnet-chain-example.h"

using namespace kaldi;
using namespace kaldi::nnet3;
using namespace kaldi::chain;

int main(int argc, char** argv){

        const char *usage ="usage";

    int32 srand_seed = 0;
    bool binary_write = true;
    std::string use_gpu = "yes";
    NnetChainTrainingOptions opts;

    opts.chain_config.xent_regularize = 0.5;
    opts.nnet_config.compute_config.debug = false;

    ParseOptions po(usage);
    po.Register("srand", &srand_seed, "Seed for random number generator ");
    po.Register("binary", &binary_write, "Write output in binary mode");
    po.Register("use-gpu", &use_gpu,
            "yes|no|optional|wait, only has effect if compiled with CUDA");

    opts.Register(&po);
    #if HAVE_CUDA==1
    CuDevice::RegisterDeviceOptions(&po);
    #endif
    RegisterCuAllocatorOptions(&po);

    po.Read(argc, argv);


    string den_fst_rxfilename = "../../exp/tri8b/den.fst";
    fst::StdVectorFst den_fst;
    ReadFstKaldi(den_fst_rxfilename, &den_fst);

    //string nnet_rxfilename = "../../tdnn-models/2.raw";
    //string nnet_rxfilename = "../../tdnn-models/3.raw";
    string nnet_rxfilename = "../../tdnn-models/4.raw";
    Nnet nnet;
    ReadKaldiObject(nnet_rxfilename, &nnet);

    NnetChainTrainer trainer(opts, den_fst, &nnet);


    string examples_rspecifier = "ark:../../trash/debug.mb.chain.egs"; 
    string examples_wspecifier = "ark,t:../../trash/fake.debug.mb.chain.egs";
    kaldi::nnet3::SequentialNnetChainExampleReader example_reader(examples_rspecifier);
    kaldi::nnet3::NnetChainExampleWriter example_writer(examples_wspecifier);
    srand(0);
    for (; !example_reader.Done(); example_reader.Next()){
        auto &eg = example_reader.Value();
        for (auto &input : eg.inputs){
            kaldi::Matrix<kaldi::BaseFloat> feats;
            input.features.GetMatrix(&feats);
            int min_val = std::numeric_limits<int>::max();
            for (auto &i : input.indexes){
                if (min_val > i.t){
                    min_val = i.t;
                }
            }
            int k = 0;
            for (auto &i : input.indexes){
                kaldi::BaseFloat val = i.t-min_val;
                feats.Row(k).Set(val);
                k++;
            }
            input.features = feats;
        }

        for (auto &output : eg.outputs){
            for (auto &o : output.indexes){
                o.t += 2;
            }
        }

        cout << rand() << endl;
        trainer.Train(eg);

        example_writer.Write("heihei", eg);
    }
    return 0;
}
