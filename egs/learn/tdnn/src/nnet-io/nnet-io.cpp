/******************************************************************************
  > file name    : nnet-io.cpp
  > author       : Ban Zhihua
  > contact      : sawpara@126.com
  > created time : Wed 10 Jun 2020 03:16:43 PM CST
******************************************************************************/
#include <iostream>
using namespace std;

#include "nnet3/nnet-nnet.h"

int main(){
    string filename = "../../exp/tri8b/30.mdl";
    kaldi::nnet3::Nnet net;
    {
        bool binary_in;
        kaldi::Input ki(filename, &binary_in);
        net.Read(ki.Stream(), binary_in);
    }

    bool binary = 1;
    for (int c = 0; c < net.NumComponents(); c++){
        if ("tdnn1.affine" == net.GetComponentName(c)){
            kaldi::Output osf("aff.txt", binary);
            auto &os = osf.Stream();
            net.GetComponent(c)->Write(os, binary);
        }
        if ("lda" == net.GetComponentName(c)){
            kaldi::Output osf("lda.txt", binary);
            auto &os = osf.Stream();
            net.GetComponent(c)->Write(os, binary);
        }
        if ("tdnn1.renorm" == net.GetComponentName(c)){
            kaldi::Output osf("renorm.txt", binary);
            auto &os = osf.Stream();
            net.GetComponent(c)->Write(os, binary);
        }
    }
    return 0;
}
