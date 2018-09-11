#!/bin/bash

# Step by Step understand Kaldi using thchs30, By Ban

H=`pwd`  #exp home


# 1. prepare data

#corpus and trans directory
thchs=/home/speech/aban/t

# generate standart files for Kaldi
local/data_pre.sh $H $thchs/

