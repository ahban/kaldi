/******************************************************************************
  > file name    : fake-ce.cpp
  > authors      : Ban Zhihua(2018-2020)
  > contact      : sawpara@126.com
  > created time : Wed 29 Jul 2020 05:42:32 PM CST
******************************************************************************/

#include <iostream>
using namespace std;


#include "base/kaldi-common.h"
#include "util/common-utils.h"
#include "nnet3/nnet-training.h"
#include "cudamatrix/cu-allocator.h"

int main(int argc, char *argv[]) {
  try {
    using namespace kaldi;
    using namespace kaldi::nnet3;
    typedef kaldi::int32 int32;
    typedef kaldi::int64 int64;

    const char *usage =
        "Train nnet3 neural network parameters with backprop and stochastic\n"
        "gradient descent.  Minibatches are to be created by nnet3-merge-egs in\n"
        "the input pipeline.  This training program is single-threaded (best to\n"
        "use it with a GPU); see nnet3-train-parallel for multi-threaded training\n"
        "that is better suited to CPUs.\n"
        "\n"
        "Usage:  nnet3-train [options] <raw-model-in> <training-examples-in> <raw-model-out>\n"
        "\n"
        "e.g.:\n"
        "nnet3-train 1.raw 'ark:nnet3-merge-egs 1.egs ark:-|' 2.raw\n";

    int32 srand_seed = 0;
    bool binary_write = true;
    std::string use_gpu = "yes";
    NnetTrainerOptions train_config;

    ParseOptions po(usage);
    po.Register("srand", &srand_seed, "Seed for random number generator ");
    po.Register("binary", &binary_write, "Write output in binary mode");
    po.Register("use-gpu", &use_gpu,
                "yes|no|optional|wait, only has effect if compiled with CUDA");

    train_config.Register(&po);
    RegisterCuAllocatorOptions(&po);

    po.Read(argc, argv);

    srand(srand_seed);

    //if (po.NumArgs() != 3) {
      //po.PrintUsage();
      //exit(1);
    //}

#if HAVE_CUDA==1
    CuDevice::Instantiate().SelectGpuId(use_gpu);
#endif

    std::string nnet_rxfilename     = "../../models/8.raw";
    //std::string nnet_rxfilename     = "../../models/9.raw";
    //std::string nnet_rxfilename     = "../../models/10.raw";
    //std::string nnet_rxfilename     = "../../models/11.raw";
    std::string examples_rspecifier = "ark:../../trash/ce.mb.txt";
    std::string nnet_wxfilename     = "./write-net.raw";

    Nnet nnet;
    ReadKaldiObject(nnet_rxfilename, &nnet);

    NnetTrainer trainer(train_config, &nnet);

    SequentialNnetExampleReader example_reader(examples_rspecifier);

    for (; !example_reader.Done(); example_reader.Next()){
        auto &eg = example_reader.Value();
        for (auto &input : eg.io){
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
            if (input.name == "output"){
                std::sort(input.indexes.begin(), input.indexes.end());
            }
        }

        trainer.Train(eg);
    }
   

    bool ok = trainer.PrintTotalStats();

#if HAVE_CUDA==1
    CuDevice::Instantiate().PrintProfile();
#endif
    WriteKaldiObject(nnet, nnet_wxfilename, binary_write);
    KALDI_LOG << "Wrote model to " << nnet_wxfilename;
    return (ok ? 0 : 1);
  } catch(const std::exception &e) {
    std::cerr << e.what() << '\n';
    return -1;
  }
}
