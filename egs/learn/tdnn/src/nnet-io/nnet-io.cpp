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
    return 0;
}
