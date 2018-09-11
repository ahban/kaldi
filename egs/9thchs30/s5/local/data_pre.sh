#!/bin/bash
# directories
# dir is the working directory
dir=$1
corpus_dir=$2

# change to working directory
cd $dir

echo "creating data/{train,dev,test}"
mkdir -p data/{train,dev,test}

# create wav.scp, utt2spk.scp spk2utt.scp, text
(
for x in train dev test; do
  echo "cleaning data/$x"
  cd $dir/data/$x
  rm -rf wav.scp utt2spk spk2utt word.txt phone.txt text
  echo "preparing scps and text in data/$x"
  for nn in `find  $corpus_dir/$x -name "*.wav" | sort -u | xargs -I {} basename {} .wav`; do
      spkid=`echo $nn | awk -F"_" '{print "" $1}'`
      spk_char=`echo $spkid | sed 's/\([A-Z]\).*/\1/'`
      spk_num=`echo $spkid | sed 's/[A-Z]\([0-9]\)/\1/'`
      spkid=$(printf '%s%.2d' "$spk_char" "$spk_num")
      utt_num=`echo $nn | awk -F"_" '{print $2}'`
      uttid=$(printf '%s%.2d_%.3d' "$spk_char" "$spk_num" "$utt_num")
      echo $uttid $corpus_dir/$x/$nn.wav >> wav.scp
      echo $uttid $spkid >> utt2spk
      echo $uttid `sed -n 1p $corpus_dir/data/$nn.wav.trn` >> word.txt
      echo $uttid `sed -n 3p $corpus_dir/data/$nn.wav.trn` >> phone.txt
  done 
  cp word.txt text
  sort wav.scp -o wav.scp
  sort utt2spk -o utt2spk
  sort text -o text
  sort phone.txt -o phone.txt
done
) || exit 1






