#!/bin/bash
###############################################################################
# file name    : fst-test1.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Thu 04 Jun 2020 10:49:10 AM CST
###############################################################################

#A couple of test examples:

cd trash

#  pushd ~/tmpdir
# (1) with no disambig syms.
( echo "0 1 1 1"; echo "1 2 2 2"; echo "2 3 3 3"; echo "3 0" ) | fstcompile | fstcomposecontext ilabels.sym > tmp.fst
( echo "<eps> 0"; echo "a 1"; echo "b 2"; echo "c 3" ) > phones.txt
fstmakecontextsyms phones.txt ilabels.sym > context.txt
fstprint --isymbols=context.txt --osymbols=phones.txt tmp.fst
# and the result is:

#WARNING (fstcomposecontext[5.4]:main():fstcomposecontext.cc:130) Disambiguation symbols list is empty; this likely indicates an error in data preparation.
#0	1	<eps>	a
#1	2	<eps>/a/b	b
#2	3	a/b/c	c
#3	4	b/c/<eps>	<eps>
#4
#
#
#  # (2) with disambig syms:
#  ( echo 4; echo 5) > disambig.list
#  ( echo "<eps> 0"; echo "a 1"; echo "b 2"; echo "c 3"; echo "#0 4"; echo "#1 5") > phones.txt
#  ( echo "0 1 1 1"; echo "1 2 2 2"; echo " 2 3 4 4"; echo "3 4 3 3"; echo "4 5 5 5"; echo "5 0" ) | fstcompile > in.fst
#  fstcomposecontext --read-disambig-syms=disambig.list ilabels.sym in.fst tmp.fst
#  fstmakecontextsyms phones.txt ilabels.sym > context.txt
#  cp phones.txt phones_disambig.txt;  ( echo "#0 4"; echo "#1 5" ) >> phones_disambig.txt
#  fstprint --isymbols=context.txt --osymbols=phones_disambig.txt tmp.fst
#
#0	1	#-1	a
#1	2	<eps>/a/b	b
#2	3	#0	#0
#3	4	a/b/c	c
#4	5	#1	#1
#5	6	b/c/<eps>	<eps>
