#!/bin/bash

show_help(){
 {
    echo "Usage: $0 [ -d <filesdir> ] [ -h ]"
    echo 
    echo "-d <filesdir> Directory where to put the downloaded files. Default: '$filesdir'"
    echo "-h            Show this help."
  } >&2

}

filesdir=files

while getopts ":d:h" opt; do
  case $opt in
    d)
      filesdir=$OPTARG
      ;;
    h)
      show_help
      exit
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done


mkdir -p "$filesdir" || { echo "Cannot create directory $filesdir"; exit 1; }

echo "Downloading to: $filesdir"

for corpus in cantrbry artificl large misc calgary; do

  echo "Downloading corpus $corpus..."

  cname=${corpus}.tar.gz

  dir=$(mktemp -d)
  wget -q -O "$dir/$cname" "http://corpus.canterbury.ac.nz/resources/${cname}"

  tar -C "$dir" -xf "$dir/$cname" && rm "$dir/$cname"

  for f in "$dir"/*; do
    bname=${f##*/}
    mv "$f" "${filesdir}/${corpus}_${bname}"
  done
  rm -rf "$dir" 

done
