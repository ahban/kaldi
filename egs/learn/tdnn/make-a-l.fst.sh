#!/bin/bash
###############################################################################
# file name    : make-a-l.fst.sh
# authors      : Ban Zhihua(2018-2020)
# contact      : sawpara@126.com
# created time : Thu 04 Jun 2020 04:28:15 PM CST
###############################################################################

H=$(pwd)

cd trash

mkdir -p src

# a lexicon
lexicon_file=src/lexicon.txt
echo "a1 a1"       > $lexicon_file
echo "a2 a2"      >> $lexicon_file
echo "a3 a3"      >> $lexicon_file
echo "sil sil"      >> $lexicon_file
echo "你好 a1 a2" >> $lexicon_file
echo "<SPOKEN_NOISE> sil" >> $lexicon_file

extra_questions=src/extra_questions.txt
rm -rf $extra_questions
touch $extra_questions

echo "sil" > ./src/silence_phones.txt
echo "sil" > ./src/optional_silence.txt

nonsilence_phones=src/nonsilence_phones.txt
rm -rf $nonsilence_phones
awk -v sil="sil" '{
for (i=2; i<=NF;i++){
    if ($i!=sil){
        print $i
    }
}
}' $lexicon_file > $nonsilence_phones
sort -u $nonsilence_phones -o $nonsilence_phones


cd $H 

utils/prepare_lang.sh \
    --position_dependent_phones false \
    trash/src \
    "sil" \
    trash/local/lang_phone \
    trash/lang_phone

fstdraw --osymbols=./trash/lang_phone/words.txt \
    ./trash/lang_phone/L.fst > L.dot

fstdraw --osymbols=./trash/lang_phone/words.txt \
    ./trash/lang_phone/L_disambig.fst > L_disambig.dot

dot -Tps L.dot | ps2pdf - L.pdf
dot -Tps L_disambig.dot | ps2pdf - L_disambig.pdf

scp L.pdf L_disambig.pdf sun:~/
