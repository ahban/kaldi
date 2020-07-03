#!/bin/bash
###############################################################################
# file name    : hmm-fst.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Thu 04 Jun 2020 10:59:39 AM CST
###############################################################################

cd trash

( echo 4; echo 5) > disambig.list
#( echo "0 1 1 1"; echo "1 2 2 2"; echo " 2 3 4 4"; echo "3 4 3 3"; echo "4 5 5 5"; echo "5 0" ) | fstcompile > in.fst
( echo "0 1 1 1"; echo "1 2 2 2"; echo "2 0" ) | fstcompile > in.fst

N=2
P=1
fstcomposecontext --context-size=$N --central-position=$P  --read-disambig-syms=disambig.list ilabels.sym in.fst tmp.fst

fstprint --isymbols=./phones.txt  in.fst
echo "================================"
fstprint tmp.fst 
