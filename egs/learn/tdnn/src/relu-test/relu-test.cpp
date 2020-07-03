/******************************************************************************
  > file name    : relu-test.cpp
  > author       : Ban Zhihua
  > contact      : sawpara@126.com
  > created time : Wed 10 Jun 2020 11:19:49 AM CST
******************************************************************************/
#include <iostream>
#include <sstream>
using namespace std;

#include "nnet3/nnet-simple-component.h"

int main(){

    kaldi::CuDevice::Instantiate().SelectGpuId("yes");


    int dim = 4;
    int num_rows = 6;
    std::ostringstream ostr;
    ostr << "dim=" << dim << " self-repair-scale=1e-05";

    kaldi::ConfigLine cfg;
    cfg.ParseLine(ostr.str());

    kaldi::nnet3::RectifiedLinearComponent component;
    component.InitFromConfig(&cfg);

    kaldi::CuMatrix<float> x(num_rows, dim);
    kaldi::CuMatrix<float> y(num_rows, dim);
    kaldi::CuMatrix<float> dx(num_rows, dim);
    kaldi::CuMatrix<float> dy(num_rows, dim);
    kaldi::CuMatrix<float> temp;

    x.Set(-2);
    dy.Set(2);
    string debug;
    component.Propagate(NULL, x, &y);
    component.StoreStats(x, y, NULL);
    component.Backprop(debug, NULL, x, y, dy, NULL, &component, &dx);
    cout << dx << endl;

    component.Propagate(NULL, x, &y);
    component.StoreStats(x, y, NULL);
    component.Backprop(debug, NULL, x, y, dy, NULL, &component, &dx);
    cout << dx << endl;

    component.Propagate(NULL, x, &y);
    component.StoreStats(x, y, NULL);
    component.Backprop(debug, NULL, x, y, dy, NULL, &component, &dx);
    cout << dx << endl;

    component.Propagate(NULL, x, &y);
    component.StoreStats(x, y, NULL);
    component.Backprop(debug, NULL, x, y, dy, NULL, &component, &dx);
    cout << dx << endl;


    return 0;
}
