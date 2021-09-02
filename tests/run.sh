#!/bin/bash

show_help(){
  {
    echo "Usage: $0 [ -g <gzip.sh> ] [ -d <filesdir> ] [ -f <file> ] [ -t <type> ] [ -c <level> ] [ -h ]"
    echo 
    echo "-g <gzip.sh>  Path to the gzip.sh script. Default: '$gzipsh'"
    echo "-d <filesdir> Directory containing the test files. Default: '$filesdir'"
    echo "-f <file>     Only run tests on the given file. Default: all files.
              Use the corpus_name syntax, eg '-f calgary_pic' only runs the tests on 'files/calgary_pic.gz'"
    echo "-t <type>     Use only the specified compression type: 0 = store uncompressed,
              1 = fixed Huffman, 2 = dynamic Huffman. Default: all"
    echo "-c <level>    Compression level: 0 min, ... 9 max. Default: all"
    echo "-h            Show this help."
    echo ""
    echo "EXAMPLES"
    echo
    echo "$0 -t 2"
    echo "$0 -t 1 -c 7"
    echo "$0 -d mytestfiles -t 2 -c 5"
    echo "$0 -f calgary_paper5"
  } >&2
}


declare -A compression_types=([0]=1 [1]=1 [2]=1)
declare -A compression_levels=([1]=1 [2]=1 [3]=1 [4]=1 [5]=1 [6]=1 [7]=1 [8]=1 [9]=1)
declare -a srcfiles=()
gzipsh=../gzip.sh
filesdir=files
compression_type=-1
compression_level=-1
srcfile=

while getopts ":g:d:f:t:c:h" opt; do
  case $opt in
    d)
      filesdir=$OPTARG
      ;;
    g)
      gzipsh=$OPTARG
      ;;
    f)
      srcfile=$OPTARG
      ;;
    t)
      compression_type=$OPTARG
      ;;
    c)
      compression_level=$OPTARG
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

if [ ! -x "$gzipsh" ]; then
  echo "File $gzipsh not found or not executable" >&2
  exit 1
fi

if [ "$compression_type" != "-1" ] && [[ ! $compression_type =~ ^[0-2]$ ]]; then
  echo "Invalid compression type $compression_type" >&2
  exit 1
fi

if [ "$compression_level" != "-1" ] && [[ ! $compression_level =~ ^[1-9]$ ]]; then
  echo "Invalid compression level $compression_level" >&2
  exit 1
fi

if [ ! -d "$filesdir" ]; then
  echo "Invalid directory $filesdir" >&2
  exit 1
fi

if [ "$srcfile" != "" ] && [ ! -f "$filesdir/$srcfile" ]; then
  echo "File $srcfile not found under $filesdir" >&2
  exit 1
fi

if [ $compression_type -ne -1 ]; then
  compression_types=( [$compression_type]=1 )
fi

if [ $compression_level -ne -1 ]; then
  compression_levels=( [$compression_level]=1 )
fi

rand=$RANDOM

echo "START: gzip.sh is $gzipsh, files dir is $filesdir, rand is $rand"

for file in "$filesdir"/*; do

  if [ "$srcfile" != "" ] && [ "$srcfile" != "${file#*/}" ]; then
    continue
  fi

  echo "- Testing $file..."

  bname=${file#*/}
  uncompressed_name=/tmp/${bname}-${rand}
  gzip_name=/tmp/${bname}-gzip-${rand}.gz
  gzipsh_name=/tmp/${bname}-gzipsh-${rand}.gz

  # this is tested regardless
  echo "  ######## gzip compression, gzip.sh decompression"
  gzip -c < "$file" > "${gzip_name}"

  origsize=$(stat -c %s "${file}")
  size=$(stat -c %s "${gzip_name}")
  
  s=$(date +%s)
  $gzipsh -d < "${gzip_name}" > ${uncompressed_name}
  e=$(date +%s)

  if [ $? -ne 0 ]; then
    echo "Error during decompression with gzip.sh"
    exit 1
  fi

  if ! diff -q "$file" "$uncompressed_name" >/dev/null 2>&1; then
    echo "File $file and $uncompressed_name differ"
    exit 1
  fi

  echo "  - $file: original size $origsize, gzip compressed size: $size, duration $(( e - s )) seconds"
  rm "$gzip_name" "$uncompressed_name"

  if [ "${compression_types[0]}" != "" ]; then
    echo "  ######## gzip.sh compression (-t 0), gunzip decompression"
    s=$(date +%s)
    $gzipsh -t 0 < "$file" > "${gzipsh_name}"
    e=$(date +%s)
  
    gunzip < "${gzipsh_name}" > ${uncompressed_name}

    if [ $? -ne 0 ]; then
      echo "Error during decompression with gunzip"
      exit 1
    fi

    if ! diff -q "$file" "$uncompressed_name" >/dev/null 2>&1; then
      echo "File $file and $uncompressed_name differ"
      exit 1
    fi

    size=$(stat -c %s "${gzipsh_name}")
    echo "  - $file: original size $origsize, compressed size (-t 0) $size, duration $(( e - s )) seconds"
    rm "$gzipsh_name" "$uncompressed_name"
  fi
  
  for ctype in 1 2; do

    if [ "${compression_types[$ctype]}" = "" ]; then
      continue
    fi

    for level in {1..9}; do

      if [ "${compression_levels[$level]}" = "" ]; then
        continue
      fi

      echo "  ######## gzip.sh compression (-t $ctype -c $level), gunzip decompression"
      s=$(date +%s)
      $gzipsh -t $ctype -c $level < "$file" > "${gzipsh_name}"
      e=$(date +%s)

      gunzip < "${gzipsh_name}" > ${uncompressed_name}

      if [ $? -ne 0 ]; then
        echo "Error during decompression with gunzip"
        exit 1
      fi

      if ! diff -q "$file" "$uncompressed_name" >/dev/null 2>&1; then
        echo "File $file and $uncompressed_name differ"
        exit 1
      fi

      size=$(stat -c %s "${gzipsh_name}")
      echo "  - $file: original size $origsize, compressed size (-t $ctype -c $level) $size, duration $(( e - s )) seconds"
      rm "$gzipsh_name" "$uncompressed_name"
    done
  done

done
