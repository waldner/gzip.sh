#!/bin/bash


declare -a GZIP_input=()
declare -a GZIP_output=()
GZIP_buffer_size=65535

declare -A GZIP_dummy=()

GZIP_byte_ptr=-1
GZIP_bit_ptr=-1
declare -a GZIP_window=()    # indexed modulo 32768
GZIP_window_size=32768
GZIP_total_bytes_read=0
GZIP_total_bytes_written=0
GZIP_byte=0

# window start, end
GZIP_wstart=0
GZIP_wend=-1

declare -A GZIP_keys=()
declare -A GZIP_prevs=()

declare -a GZIP_parsed_litlen=()
declare -a GZIP_parsed_dist=()

declare -A GZIP_min_heap=()
declare -a GZIP_code_lengths=()

# to compute dynamic huffman codes
declare -A GZIP_litlen_freqs=()
declare -A GZIP_dist_freqs=()

declare -A GZIP_fixed_llcodes_inverse=()
declare -A GZIP_fixed_dcodes_inverse=()
declare -A GZIP_fixed_llcodes=()
declare -A GZIP_fixed_dcodes=()

declare -A GZIP_dynamic_llcodes_inverse=()
declare -A GZIP_dynamic_dcodes_inverse=()
declare -A GZIP_dynamic_llcodes=()
declare -A GZIP_dynamic_dcodes=()

# for huffman output
declare -a GZIP_dist_codes=()
declare -a GZIP_dist_extra_bits=()
declare -a GZIP_dist_extra_vals=()

declare -a GZIP_len_codes=()
declare -a GZIP_len_extra_bits=()
declare -a GZIP_len_extra_vals=()


declare -a GZIP_bytes=()
declare -a GZIP_bits=()

# the choice of symbols is arbitrary, the important thing is
# that we encode things in just one char to do RLE more easily
declare -A GZIP_rle_symbols=(
  [0]=0 [1]=1 [2]=2 [3]=3 [4]=4 [5]=5 [6]=6 [7]=7 [8]=8 [9]=9 [10]="a"
  [11]="b" [12]="c" [13]="d" [14]="e" [15]="f" [16]="g" [17]="h" [18]="i"
)
declare -A GZIP_rle_symbols_inv=( 
  [0]=0 [1]=1 [2]=2 [3]=3 [4]=4 [5]=5 [6]=6 [7]=7 [8]=8 [9]=9 ["a"]=10
  ["b"]=11 ["c"]=12 ["d"]=13 ["e"]=14 ["f"]=15 ["g"]=16 ["h"]=17 ["i"]=18
)

declare -a GZIP_crc_lookup=(
  0 1996959894 3993919788 2567524794 124634137 1886057615 3915621685 2657392035
  249268274 2044508324 3772115230 2547177864 162941995 2125561021 3887607047 2428444049
  498536548 1789927666 4089016648 2227061214 450548861 1843258603 4107580753 2211677639
  325883990 1684777152 4251122042 2321926636 335633487 1661365465 4195302755 2366115317
  997073096 1281953886 3579855332 2724688242 1006888145 1258607687 3524101629 2768942443
  901097722 1119000684 3686517206 2898065728 853044451 1172266101 3705015759 2882616665
  651767980 1373503546 3369554304 3218104598 565507253 1454621731 3485111705 3099436303
  671266974 1594198024 3322730930 2970347812 795835527 1483230225 3244367275 3060149565
  1994146192 31158534 2563907772 4023717930 1907459465 112637215 2680153253 3904427059
  2013776290 251722036 2517215374 3775830040 2137656763 141376813 2439277719 3865271297
  1802195444 476864866 2238001368 4066508878 1812370925 453092731 2181625025 4111451223
  1706088902 314042704 2344532202 4240017532 1658658271 366619977 2362670323 4224994405
  1303535960 984961486 2747007092 3569037538 1256170817 1037604311 2765210733 3554079995
  1131014506 879679996 2909243462 3663771856 1141124467 855842277 2852801631 3708648649
  1342533948 654459306 3188396048 3373015174 1466479909 544179635 3110523913 3462522015
  1591671054 702138776 2966460450 3352799412 1504918807 783551873 3082640443 3233442989
  3988292384 2596254646 62317068 1957810842 3939845945 2647816111 81470997 1943803523
  3814918930 2489596804 225274430 2053790376 3826175755 2466906013 167816743 2097651377
  4027552580 2265490386 503444072 1762050814 4150417245 2154129355 426522225 1852507879
  4275313526 2312317920 282753626 1742555852 4189708143 2394877945 397917763 1622183637
  3604390888 2714866558 953729732 1340076626 3518719985 2797360999 1068828381 1219638859
  3624741850 2936675148 906185462 1090812512 3747672003 2825379669 829329135 1181335161
  3412177804 3160834842 628085408 1382605366 3423369109 3138078467 570562233 1426400815
  3317316542 2998733608 733239954 1555261956 3268935591 3050360625 752459403 1541320221
  2607071920 3965973030 1969922972 40735498 2617837225 3943577151 1913087877 83908371
  2512341634 3803740692 2075208622 213261112 2463272603 3855990285 2094854071 198958881
  2262029012 4057260610 1759359992 534414190 2176718541 4139329115 1873836001 414664567
  2282248934 4279200368 1711684554 285281116 2405801727 4167216745 1634467795 376229701
  2685067896 3608007406 1308918612 956543938 2808555105 3495958263 1231636301 1047427035
  2932959818 3654703836 1088359270 936918000 2847714899 3736837829 1202900863 817233897
  3183342108 3401237130 1404277552 615818150 3134207493 3453421203 1423857449 601450431
  3009837614 3294710456 1567103746 711928724 3020668471 3272380065 1510334235 755167117
)

declare -a GZIP_length_factors=( 11 13 15 17 19 23 27
                            31 35 43 51 59 67 83
                            99 115 131 163 195 227 )
declare -a GZIP_distance_factors=( 4 6 8 12 16 24 32 48
                              64 96 128 192 256 384
                              512 768 1024 1536 2048
                              3072 4096 6144 8192
                              12288 16384 24576 )


GZIP_log(){
  printf '%s\n' "$1" >&2
}

GZIP_die(){
  GZIP_log "$1"
  exit 1
}

GZIP_init_crc32(){
  # Initialize CRC-32 to starting value
  GZIP_crc32=4294967295   # all ones
}

GZIP_update_crc32(){
  local index char=$1
  index=$(( (GZIP_crc32 ^ char) & 255 ))
  GZIP_crc32=$(( (GZIP_crc32 >> 8) ^ GZIP_crc_lookup[index] ))
}

GZIP_finalize_crc32(){
  # invert all bits
  GZIP_crc32=$(( GZIP_crc32 ^ 4294967295 ))
}

GZIP_add_to_heap(){

  local symbol=$1
  local -n __freqs=$2
  local parent parent_index parent_elem tmp cur_pos

  # add at the end then bubble up if needed
  ((GZIP_heap_end++))
  GZIP_min_heap[$GZIP_heap_end]=$symbol

  if [ $GZIP_heap_end -gt 0 ]; then
    cur_pos=$GZIP_heap_end
    while true; do
      parent_index=$(( (cur_pos - 1) / 2 ))
      parent_elem=${GZIP_min_heap[$parent_index]}
      if [ ${__freqs[$parent_elem]} -gt ${__freqs[$symbol]} ]; then
        # swap
        tmp=${GZIP_min_heap[$parent_index]}
        GZIP_min_heap[$parent_index]=${GZIP_min_heap[$cur_pos]}
        GZIP_min_heap[$cur_pos]=$tmp
        cur_pos=$parent_index
      else
        break
      fi
    done
  fi
}

# extract minimum element
GZIP_get_from_heap(){

  local -n __freqs=$1
  local parent_index parent_elem tmp cur_pos
  local c1_index c2_index c1_elem c2_elem min_index

  GZIP_min_heap_value=${GZIP_min_heap[0]}

  # put last element at top
  GZIP_min_heap[0]=${GZIP_min_heap[$GZIP_heap_end]}
  ((GZIP_heap_end--))

  # heapify
  if [ $GZIP_heap_end -gt 0 ]; then
    cur_pos=0
    while true; do

      c1_index=$(( 2 * cur_pos + 1 ))
      c2_index=$(( c1_index + 1 ))

      c1_elem=${GZIP_min_heap[$c1_index]}
      c2_elem=${GZIP_min_heap[$c2_index]}

      if { [ $c1_index -le $GZIP_heap_end ] && [ ${__freqs[${GZIP_min_heap[$cur_pos]}]} -gt ${__freqs[$c1_elem]} ]; } || \
         { [ $c2_index -le $GZIP_heap_end ] && [ ${__freqs[${GZIP_min_heap[$cur_pos]}]} -gt ${__freqs[$c2_elem]} ]; }; then

        # swap with the smallest child
        if [ $c2_index -gt $GZIP_heap_end ]; then
          min_index=$c1_index
        elif [ $c1_index -gt $GZIP_heap_end ]; then
          min_index=$c2_index
        else
          min_index=$(( __freqs[$c1_elem] < __freqs[$c2_elem] ? c1_index : c2_index ))
        fi

        tmp=${GZIP_min_heap[$cur_pos]}
        GZIP_min_heap[$cur_pos]=${GZIP_min_heap[$min_index]}
        GZIP_min_heap[$min_index]=$tmp
        cur_pos=$min_index
      else
        break
      fi
    done
  fi

}



# Textbook algorithm
GZIP_compute_dynamic_tree(){

  local -n _freqs=$1
  local nsymbols=$2
  local length_limit=$3
  local -n dst_fwd=$4
  local -n dst_inv=$5

  local i max_sum sum symbol internal_node v1 v2

  # create min-heap
  GZIP_min_heap=()
  GZIP_heap_end=-1

  for symbol in "${!_freqs[@]}"; do
    GZIP_add_to_heap "$symbol" _freqs
  done

  local -A parents=()
  # internal nodes have values that cannot occur in the data (>= 1000)
  internal_node=999

  if [ $GZIP_heap_end -gt -1 ]; then 
    while true; do
  
      GZIP_get_from_heap _freqs
      v1=$GZIP_min_heap_value

      if [ $GZIP_heap_end -eq -1 ]; then
        parents[$v1]=-1
        break
      fi
      GZIP_get_from_heap _freqs
      v2=$GZIP_min_heap_value
   
      # create internal node with the two extracted minimum values as children
      ((internal_node++))
    
      parents[$v1]=$internal_node
      parents[$v2]=$internal_node
    
      # this is needed so add_to_heap can properly heapify
      _freqs[$internal_node]=$(( _freqs[$v1] + _freqs[$v2] ))
    
      GZIP_add_to_heap $internal_node _freqs
    
    done
  fi

  local len ptr
  GZIP_code_lengths=()

  # now walk up parents and get length for each code
  for symbol in "${!_freqs[@]}"; do
  
    # ignore internal nodes
    if [ $symbol -ge 1000 ]; then
      continue
    fi
  
    # walk up the chain
    len=0
    ptr=$symbol
    while true; do
      ptr=${parents[$ptr]}
      if [ $ptr -eq -1 ]; then
        break
      fi
      ((len++))
    done
    # special case
    if [ $len -eq 0 ]; then
      len=1
    fi
    GZIP_code_lengths[$symbol]=$len
  done

  # there might be corner cases where the length of some codeword
  # exceeds the maximum permitted for the tree, so we should check
  # and fix the lengths if necessary before proceeding.

  # The fix exploits what's known as the "Kraft-McMillan inequality"
  # https://en.wikipedia.org/wiki/Kraft%E2%80%93McMillan_inequality
  # but without actually doing the fractionary calculations for
  # obvious reasons
  # All credit goes to this page:
  # https://create.stephan-brumme.com/length-limited-prefix-codes/
  # for explaining all the fine details.

  max_sum=$(( 2 ** length_limit ))
  sum=0
  for ((i = 0; i < nsymbols; i++)); do
    if [ "${GZIP_code_lengths[$i]}" != "" ]; then
      if [ ${GZIP_code_lengths[$i]} -gt $length_limit ]; then
        GZIP_code_lengths[$i]=$length_limit
      fi
      # normalize each element and sum
      sum=$(( sum + (max_sum / (2 ** GZIP_code_lengths[i])) ))
    fi
  done
  
  if [ $sum -gt $max_sum ]; then
    # we need to fix lengths. This uses MiniZ's method from the above page.
    i=0
    while true; do
  
      # choose a maximum length code and another (shorter) code
      maxlen_code_index=-1
      shorter_code_index=-1
      shorter_len=-1
  
      for ((i=0; i < nsymbols; i++)); do
  
        if [ $maxlen_code_index -ne -1 ] && [ $shorter_code_index -ne -1 ] && [ ${GZIP_code_lengths[$shorter_code_index]} -eq $(( length_limit - 1 )) ]; then
          break
        fi
  
        if [ "${GZIP_code_lengths[$i]}" = "" ]; then
          continue
        fi
  
        if [ $maxlen_code_index -eq -1 ] && [ ${GZIP_code_lengths[$i]} -eq $length_limit ]; then
          maxlen_code_index=$i
          continue
        fi
  
        if [ ${GZIP_code_lengths[$i]} -lt $length_limit ] && [ ${GZIP_code_lengths[$i]} -gt $shorter_len ]; then
          shorter_len=${GZIP_code_lengths[$i]}
          shorter_code_index=$i
          continue
        fi
      done
  
      # we now have two elements, lengthen the shorter one by one and give the first one the same length
 
      # lengthen the second one and update sum
      sum=$(( sum - (max_sum / (2 ** GZIP_code_lengths[$shorter_code_index])) + (max_sum / (2 ** (GZIP_code_lengths[$shorter_code_index]+1) )) ))
      ((GZIP_code_lengths[$shorter_code_index]++))

      # give the first element the same length and update sum
      sum=$(( sum - (max_sum / (2 ** GZIP_code_lengths[$maxlen_code_index])) + (max_sum / (2 ** GZIP_code_lengths[$shorter_code_index])) ))
      GZIP_code_lengths[$maxlen_code_index]=${GZIP_code_lengths[$shorter_code_index]}

      # stop as soon as we get within the limit 
      if [ $sum -le $max_sum ]; then
        break
      fi
        
    done
  fi

  # with lengths, we can finally build the huffman tree
  GZIP_build_huffman_tree GZIP_code_lengths $nsymbols 0 dst_fwd dst_inv
}




# GENERAL INPUT FROM STDIN; USED BY DEFLATE AND INFLATE
# Uses GZIP_buffer_size to know how many bytes to read
# Sets: GZIP_input[] with actual bytes, GZIP_bytes_read
# with number of read bytes, GZIP_total_bytes_read for the
# grand total (used for the trailer)
GZIP_read_input(){

  local data length bytes status i
  local fd=$1

  bytes=0

  local to_read=$GZIP_buffer_size

  GZIP_eof=0

  while true; do

    IFS= read -u $fd -d '' -r -n $to_read data
    status=$?

    length=${#data}

    for ((i=0; i < length; i++)); do
      printf -v "GZIP_input[bytes+i]" "%d" "'${data:i:1}"
    done

    # if we read less than we wanted, and it's not EOF, it means we also have
    # a delimiter (NUL)
    if [ $length -lt $to_read ] && [ $status -eq 0 ]; then
      GZIP_input[bytes+length]=0
      ((length++))
      #echo "Read NUL"
    fi

    ((bytes+=length))
    if [ $bytes -ge $GZIP_buffer_size ]; then
      break
    fi
    if [ $status -ne 0 ]; then
      GZIP_eof=1
      break
    fi
    ((to_read-=length))
  done

  GZIP_bytes_read=$bytes
  ((GZIP_total_bytes_read+=bytes))

}

# Get some bytes from GZIP_input[]
# USED ONLY FOR DECOMPRESSION to read header/trailer
# and when decompressing literal bytes (block type 00)
# If you call this function directly, it's the
# caller's responsibility to ensure there are
# no pending bits to read before

# Arguments: number of bytes to read (default 1)
# Puts bytes read into GZIP_bytes[]
# Also, as a convenience for the caller, puts decoded byte values
# into GZIP_decoded_byteval
# This works because we read at most 4 bytes at a time
# Updates: GZIP_byte_ptr (index into GZIP_input[])

GZIP_get_bytes(){

  local count=$1 i

  if [ "$count" = "" ]; then
    count=1
  fi

  GZIP_decoded_byteval=0
  for ((i = 0; i < count; i++)); do

    if [ $GZIP_byte_ptr -eq -1 ]; then
      local fd=0
      GZIP_read_input $fd    # input into GZIP_input
    fi

    ((GZIP_byte_ptr++))
    GZIP_bytes[i]=${GZIP_input[$GZIP_byte_ptr]}
    GZIP_decoded_byteval=$(( GZIP_decoded_byteval + (GZIP_bytes[i] << 8*i) ))
    if [ $GZIP_byte_ptr -ge $(( GZIP_bytes_read - 1)) ]; then
      GZIP_byte_ptr=-1
    fi

  done

}

# get some input bits
# Read bits from GZIP_bits, when empty read another
# byte with GZIP_get_bytes
# Store read bits into GZIP_bits (indexed by GZIP_bit_ptr)
# Updates: GZIP_bit_ptr
# Sets GZIP_decoded_bitval as a convenience

GZIP_get_bits(){

  local count=$1 i

  if [ "$count" = "" ]; then
    count=1
  fi

  GZIP_decoded_bitval=0
  for ((i = 0; i < count; i++)); do

    if [ $GZIP_bit_ptr -eq -1 ]; then
      GZIP_get_bytes
    fi

    ((GZIP_bit_ptr++))
    GZIP_bits[i]=$(( ( GZIP_bytes[0] & (1 << GZIP_bit_ptr) ) >> GZIP_bit_ptr ))
    GZIP_decoded_bitval=$(( GZIP_decoded_bitval + (GZIP_bits[i] << i) ))

    if [ $GZIP_bit_ptr -ge 7 ]; then
      GZIP_bit_ptr=-1
    fi

  done

}

# read bit-by-bit until a valid code according to the
# Huffman codes in $arr is found
GZIP_read_one_code(){

  local -n _codes=$1
  local b=
  local count=0

  while true; do

    GZIP_get_bits
    b="${b}${GZIP_bits[0]}"
 
    if [ "${_codes[$b]}" != "" ]; then
      break
    fi
    ((count++))
    # if we read too much without finding a code, something is wrong
    if [ $count -gt 16 ]; then
      GZIP_die "Read $count bits without finding a valid code"
    fi
  done

  GZIP_decoded_value=${_codes[$b]}
}


# converts a value to a bitstring
# Sets: GZIP_bitstring
# Arguments: value, length
GZIP_to_bitstring(){

  local v=$1 len=$2 i
  GZIP_bitstring=
  for (( i = len-1; i >= 0; i--)); do
    GZIP_bitstring="${GZIP_bitstring}$(( (v & (1 << i)) >> i ))"
  done

}

GZIP_to_bitstring_rev(){
  local v=$1 len=$2 i
  GZIP_bitstring=
  for (( i = 0; i < len; i++)); do
    GZIP_bitstring="${GZIP_bitstring}$(( (v & (1 << i)) >> i ))"
  done

}


# header is byte-oriented
# Used for decompression
GZIP_parse_header(){

  local b1 b2 compression_method flgs ftext
  local fhcrc fextra timestamp
  local fname fcomment xlen len si1 si2
  local extra_flags os i val vx

  # get magic number
  GZIP_get_bytes 2

  b1=${GZIP_bytes[0]}
  b2=${GZIP_bytes[1]}
  
  if [ $b1 -ne 31 ] || [ $b2 -ne 139 ]; then
    GZIP_die "No gzip signature, terminating"
  fi

  GZIP_get_bytes
  compression_method=${GZIP_bytes[0]}   # always 8

  if [ $compression_method -ne 8 ]; then
    GZIP_die "No deflate compression method byte (8), terminating"
  fi

  GZIP_get_bytes
  flgs=${GZIP_bytes[0]}

  ftext=$(( flgs & 1 ))
  fhcrc=$(( flgs & 2 ))
  fextra=$(( flgs & 4 ))
  fname=$(( flgs & 8 ))
  fcomment=$(( flgs & 16 ))

  GZIP_get_bytes 4
  timestamp=$GZIP_decoded_byteval

  GZIP_get_bytes 
  extra_flags=${GZIP_bytes[0]}
  GZIP_get_bytes
  os=${GZIP_bytes[0]}

  # 0 - FAT filesystem (MS-DOS, OS/2, NT/Win32)
  # 1 - Amiga
  # 2 - VMS (or OpenVMS)
  # 3 - Unix
  # 4 - VM/CMS
  # 5 - Atari TOS
  # 6 - HPFS filesystem (OS/2, NT)
  # 7 - Macintosh
  # 8 - Z-System
  # 9 - CP/M
  # 10 - TOPS-20
  # 11 - NTFS filesystem (NT)
  # 12 - QDOS
  # 13 - Acorn RISCOS
  # 255 - unknown

  if [ $fextra -ne 0 ]; then
    GZIP_get_bytes 2
    xlen=$GZIP_decoded_byteval

    GZIP_get_bytes $xlen
    count=$xlen
    while true; do
      si1=${GZIP_bytes[0]}
      si2=${GZIP_bytes[1]}
      len=$(( GZIP_bytes[2] + (GZIP_bytes[3] << 8) ))

      val=
      vx=
      for ((i = 0; i < len; i++)); do
        printf -v vx '%s%x' '\x' "${GZIP_bytes[4+i]}" 
        printf -v val "%s${vx}" "$val"
      done

      count=$(( count + len + 4 ))

      if [ $count -ge $xlen ]; then
        break
      fi
    done
    
  fi

  if [ $fname -ne 0 ]; then
    # read until null
    val=
    while true; do
      GZIP_get_bytes

      if [ ${GZIP_bytes[0]} -eq 0 ]; then
        break
      fi

      # unused anyway
      printf -v vx '%s%x' '\x' "${GZIP_bytes[0]}" 
      printf -v val "%s${vx}" "$val"

    done
  fi

  if [ $fcomment -ne 0 ]; then
    # read until null
    val=
    while true; do
      GZIP_get_bytes

      if [ ${GZIP_bytes[0]} -eq 0 ]; then
        break
      fi

      # unused
      printf -v vx '%s%x' '\x' "${GZIP_bytes[4+1]}" 
      printf -v val "%s${vx}" "$val"

    done
  fi

  if [ $fhcrc -ne 0 ]; then
    # read 2 bytes
    GZIP_get_bytes 2

  fi

}

GZIP_parse_trailer(){

  local crc length computed_length

  GZIP_get_bytes 4
  crc=$GZIP_decoded_byteval

  if [ $crc -ne $GZIP_crc32 ]; then
    GZIP_log "WARNING: different CRC (got: $crc, computed: $GZIP_crc32)"
  fi

  # length 
  GZIP_get_bytes 4
  length=$GZIP_decoded_byteval
  computed_length=$(( GZIP_total_bytes_written % (2 ** 32) ))
  if [ $length -ne $computed_length ]; then
    GZIP_log "WARNING: different size (got: $length, computed: $computed_length)"
  fi
}


# Given a source array containing the encoding lengths of symbols,
# builds a Huffman tree in canonical form inside dst_fwd and dst_inv
# (forward ie symbol->bitstring and inverse ie bitstring->symbol)
GZIP_build_huffman_tree(){
  local -n __lengths=$1
  local ncodes=$2
  local offset=$3
  local -n _dst_fwd=$4
  local -n _dst_inv=$5

  local i l maxl code v
  local -A length_counts=()
  local -A firsts=()

  for ((i = 0; i <= ncodes; i++)); do
    length_counts[$i]=0
  done

  # count how many codes there are for each length
  # and calculate max code length
  maxl=0

  for ((i = 0; i <= ncodes; i++)); do
    l=${__lengths[$((i+offset))]:-0}
    if [ $l -gt $maxl ]; then
      maxl=$l
    fi
    if [ $l -gt 0 ]; then
      ((length_counts[$l]++))
    fi
  done

  firsts[0]=0
  code=0

  # calculate first value for each length
  for (( l = 1; l <= maxl; l++ )); do
    code=$(( (code + length_counts[$((l-1))]) << 1 ))
    if [ ${length_counts[$l]} -gt 0 ]; then
      firsts[$l]=$code
    fi
  done

  # starting with src, calculate codes
  for ((i = 0; i <= ncodes; i++)); do
    v=${__lengths[$((i+offset))]}
    if [ "$v" != "" ] && [ "$v" != "0" ]; then
      # code length: $v
      # value: ${firsts[$v]} (then incremented)
      GZIP_to_bitstring ${firsts[$v]} $v
      _dst_inv["${GZIP_bitstring}"]=$i
      _dst_fwd[$i]=${GZIP_bitstring}
      ((firsts[$v]++))
    fi
  done

}


### Real decompress routine
GZIP_inflate(){

  local compression block last_block

  GZIP_parse_header

  GZIP_init_crc32
  block=-1

  while true; do
  
    ((block++))

    GZIP_get_bits
    last_block=${GZIP_bits[0]}
 
    GZIP_get_bits 2
    compression=$GZIP_decoded_bitval

    # 0: no compression
    # 1: fixed huffman codes
    # 2: dynamic huffman code
    # 3: error
  
    if [ $compression -eq 0 ]; then
      GZIP_inflate_uncompressed
    elif [ $compression -eq 1 ]; then
      GZIP_inflate_huffman 0
    elif [ $compression -eq 2 ]; then
      GZIP_inflate_huffman 1
    else
      GZIP_die "Invalid compression value for block $block: $compression"
    fi    

    if [ $last_block -eq 1 ]; then
      break
    fi

  done

  GZIP_finalize_crc32
  GZIP_parse_trailer
}

# decompress a block stored with no compression (type 0)
GZIP_inflate_uncompressed(){

  local length clength i v

  # skip irrelevant bits
  GZIP_get_bits 5

  # get length
  GZIP_get_bytes 2
  length=$GZIP_decoded_byteval

  # get one's complement of length
  GZIP_get_bytes 2
  clength=$GZIP_decoded_byteval    # unused

  for ((i = 0; i < length; i++)); do
    GZIP_get_bytes
    GZIP_output_byte ${GZIP_bytes[0]}
  done

}


# decompress a block compressed with dynamic or fixed huffman codes
GZIP_inflate_huffman(){
  
  local value i v
  local end index start_index
  local hlit hdist
  local dynamic=$1      # 1 if dynamic

  local -n llcodes
  local -n dcodes

  if [ $dynamic -eq 1 ]; then
    # read and rebuild the dynamic Huffman codes

    GZIP_dynamic_llcodes=()
    GZIP_dynamic_llcodes_inverse=()
    GZIP_dynamic_dcodes=()
    GZIP_dynamic_dcodes_inverse=()

    local -A lengths=()
    GZIP_get_s1codes lengths hlit hdist

    GZIP_get_s2codes lengths GZIP_dynamic_llcodes_inverse GZIP_dynamic_dcodes_inverse $hlit $hdist

    llcodes=GZIP_dynamic_llcodes_inverse
    dcodes=GZIP_dynamic_dcodes_inverse

  else
    llcodes=GZIP_fixed_llcodes_inverse
    dcodes=GZIP_fixed_dcodes_inverse
  fi

  # now we can read the actual LZSS-compressed/Huffman-encoded data
  while true; do
  
    end=0
  
    GZIP_read_one_code llcodes
    value=${GZIP_decoded_value}
 
    if [ ${value} -lt 256 ]; then

      # literal, output as is
      GZIP_output_byte $value
      GZIP_add_to_window $value
  
    elif [ ${value} -eq 256 ]; then
      # stop
      end=1
    else
      # backpointer
      local length distance

      GZIP_decode_backpointer $value length distance dcodes
  
      # we have length and distance, read and output data from window
      start_index=$(( GZIP_wend - distance ))

      for ((i = 0; i < length; i++)); do
        index=$(( (start_index + i) % GZIP_window_size ))
        GZIP_output_byte ${GZIP_window[$index]}
        GZIP_add_to_window ${GZIP_window[$index]}
      done
  
    fi
  
    if [ $end -eq 1 ]; then
      break
    fi
   
  done
  
}

# Output one byte of stdout
# Used when decompressing
GZIP_output_byte(){

  local byte=$1
  local no_update=$2
  local v

  if [ "$no_update" = "" ]; then
    no_update=0
  fi

  printf -v v "%o" ${byte}
  printf "\\$v"
  if [ $no_update -eq 0 ]; then
    GZIP_update_crc32 ${byte} 
    ((GZIP_total_bytes_written++)) 
  fi
}



GZIP_get_s1codes(){

  local -n _lengths=$1
  local -n _hlit=$2
  local -n _hdist=$3
  local -A s1codes=()
  local hclen
  local i value count nzeros repeats prev

  # HLIT, number of literal/length codes
  GZIP_get_bits 5
  _hlit=$GZIP_decoded_bitval
    
  # HDIST, number of distance codes
  GZIP_get_bits 5
  _hdist=$GZIP_decoded_bitval
  
  # HCLEN, number of code length codes
  GZIP_get_bits 4
  hclen=$GZIP_decoded_bitval
  
  #GZIP_log "DECOMPRESS: HLIT: $_hlit, HDIST: $_hdist, HCLEN: $hclen"
  
  local -a s=(16 17 18 0 8 7 9 6 10 5 11 4 12 3 13 2 14 1 15)
  
  # we now need $hclen + 4 3-bit numbers
  for (( i = 0; i < hclen + 4; i++ )); do
    GZIP_get_bits 3
    _lengths[${s[$i]}]=$GZIP_decoded_bitval
  done
  
  GZIP_build_huffman_tree _lengths 18 0 GZIP_dummy s1codes
  
  # now with s1codes we can read the actual huffman tree for the compressed data
  count=0
  _lengths=()
  while true; do
  
    GZIP_read_one_code s1codes
    value=${GZIP_decoded_value}
  
    # special cases
    if [ ${value} -eq 17 ]; then
      # a run of zeros; how many is in next 3 bits + 3
      GZIP_get_bits 3
      nzeros=$(( GZIP_decoded_bitval + 3 ))
      for ((i = 0; i < nzeros; i++)); do
        _lengths[$count]=0
        ((count++))
      done
  
    elif [ ${value} -eq 18 ]; then
      # a run of zeros; how many is in next 7 bits + 11
      GZIP_get_bits 7
      nzeros=$(( GZIP_decoded_bitval + 11 ))
      for ((i = 0; i < nzeros; i++)); do
        _lengths[$count]=0
        ((count++))
      done
  
    elif [ ${value} -eq 16 ]; then
  
      # repeat previous character n times; how many is in next 2 bits + 3
      GZIP_get_bits 2
      repeats=$(( GZIP_decoded_bitval + 3))
      prev=${_lengths[$((count-1))]}
      for ((i = 0; i < repeats; i++)); do
        _lengths[$count]=$prev
        ((count++))
      done
    else
      # normal case
      _lengths[$count]=${value}
      ((count++))
    fi
  
    if [ $count -gt $(( 257 + _hlit + _hdist )) ]; then
      break
    fi
   
  done

  # we need "_lengths" from this phase, that's why
  # it's a nameref, so the caller sees it
 
}
 
GZIP_get_s2codes(){

  local -n _lengths=$1
  local -n _llcodes=$2
  local -n _dcodes=$3
  local hlit=$4
  local hdist=$5

  # now we can calculate the s2 huffman tables
  
  # first 257 + $hlit are one table, last $hdist another
  # use 256 + hlit since the function does "<="
  
  GZIP_build_huffman_tree _lengths $(( 256 + hlit )) 0 GZIP_dummy _llcodes
  GZIP_build_huffman_tree _lengths $hdist $(( 257 + hlit )) GZIP_dummy _dcodes

}
 
GZIP_decode_backpointer(){

  local value=$1
  local -n _length=$2
  local -n _distance=$3
  local -n _dcodes=$4

  local n_extra_bits

  # read LENGTH first
  if [ ${value} -le 264 ]; then
    _length=$(( value - 254 ))
  elif [ ${value} -le 284 ]; then
    n_extra_bits=$(( (value - 261) / 4 ))
    GZIP_get_bits $n_extra_bits
    _length=$(( GZIP_decoded_bitval + GZIP_length_factors[ value - 265 ] ))
  else
    _length=258   # maximum len 
  fi
  
  # then read DISTANCE 
  GZIP_read_one_code _dcodes
  _distance=${GZIP_decoded_value}
  
  if [ $_distance -gt 3 ]; then
    n_extra_bits=$(( (_distance - 2) / 2 ))
    GZIP_get_bits $n_extra_bits
    _distance=$(( GZIP_decoded_bitval + GZIP_distance_factors[ distance - 4 ] ))
  fi
}


GZIP_write_header(){

  # signature
  GZIP_output_byte 31 1
  GZIP_output_byte 139 1
  # compression method deflate
  GZIP_output_byte 8 1
  # flags
  GZIP_output_byte 0 1
  
  # timestamp
  printf -v timestamp '%(%s)T' -1
  GZIP_output_byte $(( timestamp & 0xff )) 1
  GZIP_output_byte $(( (timestamp & (0xff << 8)) >> 8)) 1
  GZIP_output_byte $(( (timestamp & (0xff << 16)) >> 16)) 1
  GZIP_output_byte $(( (timestamp & (0xff << 24)) >> 24)) 1

  # TODO: can we always put 0 here safely?
  GZIP_output_byte 0 1   # extra flags (2 == maximum compresison, 4 == fastest algorithm)
  GZIP_output_byte 3 1   # OS: unix
}


GZIP_write_trailer(){

  local size

  # CRC: 4 bytes
  GZIP_output_byte $(( GZIP_crc32 & 0xff )) 1
  GZIP_output_byte $(( (GZIP_crc32 & (0xff << 8)) >> 8 )) 1
  GZIP_output_byte $(( (GZIP_crc32 & (0xff << 16)) >> 16 )) 1
  GZIP_output_byte $(( (GZIP_crc32 & (0xff << 24)) >> 24 )) 1

  # size: 4 bytes
  size=$(( GZIP_total_bytes_read % (2 ** 32) ))
  GZIP_output_byte $(( size & 0xff )) 1
  GZIP_output_byte $(( (size & (0xff << 8)) >> 8 )) 1
  GZIP_output_byte $(( (size & (0xff << 16)) >> 16 )) 1
  GZIP_output_byte $(( (size & (0xff << 24)) >> 24 )) 1
}


GZIP_deflate_uncompressed(){

  # pad to byte
  GZIP_put_bit 00000
  
  # length (2 + 2 of one's complement)
  len=$GZIP_bytes_read
  GZIP_output_byte $(( len & 0xff )) 1
  GZIP_output_byte $(( (len & 0xff00) >> 8 )) 1
  
  GZIP_output_byte $(( ~(len & 0xff) & 0xff )) 1
  GZIP_output_byte $(( (~(len & 0xff00) & 0xff00) >> 8)) 1
  
  # write data verbatim
  for ((i = 0; i < GZIP_bytes_read; i++)); do
    GZIP_output_byte ${GZIP_input[$i]} 1
    GZIP_update_crc32 ${GZIP_input[$i]}
  done
  
}

# input: always a bitstring
GZIP_put_bit(){

  local bitstring=$1
  local i
  for ((i = ${#bitstring} - 1; i >= 0; i--)); do
    ((GZIP_bit_ptr++))
    GZIP_byte=$(( GZIP_byte | (${bitstring:$i:1} << GZIP_bit_ptr) ))
    if [ $GZIP_bit_ptr -ge 7 ]; then
      GZIP_bit_ptr=-1
      GZIP_output_byte $GZIP_byte 1
      GZIP_byte=0
    fi
  done
}

# input: always a bitstring
# used for huffman codes only
GZIP_put_bit_inv(){

  local bitstring=$1
  local i
  for ((i = 0; i < ${#bitstring}; i++)); do
    ((GZIP_bit_ptr++))
    GZIP_byte=$(( GZIP_byte | (${bitstring:$i:1} << GZIP_bit_ptr) ))
    if [ $GZIP_bit_ptr -ge 7 ]; then
      GZIP_bit_ptr=-1
      GZIP_output_byte $GZIP_byte 1
      GZIP_byte=0
    fi
  done
}


# compress
GZIP_deflate(){

  local compression_type=$1
  local compression_level=$2
  local block last

  GZIP_init_crc32
  
  GZIP_write_header

  block=-1

  while true; do
  
    ((block++))    # TODO unused

    GZIP_read_input 0

    last=0
    if [ $GZIP_eof -eq 1 ]; then
      last=1
    fi

    GZIP_put_bit $last     # last block

    # 0: no compression 
    # 1: fixed huffman codes
    # 2: dynamic huffman code
    # 3: error
  
    if [ $compression_type -eq 0 ]; then
      GZIP_put_bit 00         # 00: no compression
      GZIP_deflate_uncompressed
    elif [ $compression_type -eq 1 ]; then
      GZIP_put_bit 01         # 01: fixed huffman tables
      GZIP_deflate_huffman_fixed $compression_level
    else
      GZIP_put_bit 10         # 10: dynamic huffman tables
      GZIP_deflate_huffman_dynamic $compression_level
    fi    

    if [ $last -eq 1 ]; then
      break
    fi

  done

  # padding
  if [ $GZIP_bit_ptr -ge 0 ]; then
    local b=00000000
    GZIP_put_bit ${b:0:$(( 7 - GZIP_bit_ptr ))}
  fi

  GZIP_finalize_crc32
  GZIP_write_trailer
}

# output a literal directly to Huffman codes
GZIP_output_literal(){
  local literal=$1
  local -n _lltree=$2
  GZIP_put_bit_inv ${_lltree[$literal]}
}

# output a literal in parsed (intermediate) form
GZIP_output_parsed_literal(){
  local literal=$1
  local j
  ((GZIP_litlen_freqs[$literal]++))
  ((GZIP_parsed_pos++))
  GZIP_parsed_litlen[$GZIP_parsed_pos]="$literal"
}

# output a backpointer directly to Huffman codes
GZIP_output_backpointer(){
  local len=$1 dist=$2
  local -n _lltree=$3
  local -n _dtree=$4
  local code j dist

  # first output length, that is, Huffman code for length
  GZIP_length_symbol=${GZIP_len_codes[$len]}
  GZIP_put_bit_inv ${_lltree[$GZIP_length_symbol]}

  # then extra bits for length (if any)
  GZIP_put_bit ${GZIP_len_extra_vals[$len]}


  # then output distance, that is, Huffman code for distance
  GZIP_dist_symbol=${GZIP_dist_codes[$dist]}
  GZIP_put_bit_inv ${_dtree[$GZIP_dist_symbol]}

  # then extra bits for distance (if any)
  GZIP_put_bit ${GZIP_dist_extra_vals[$dist]}

}

# output a backpointer to parsed (intermediate) form
GZIP_output_parsed_backpointer(){
  local len=$1 dist=$2
  local len_code dist_code

  # first output length, that is, Huffman code for length
  len_code=${GZIP_len_codes[$len]}

  # then output distance code
  dist_code=${GZIP_dist_codes[$dist]}

  # collect frequency for backpointer len + distance
  ((GZIP_litlen_freqs[$len_code]++))
  ((GZIP_dist_freqs[$dist_code]++))

  ((GZIP_parsed_pos++))
  GZIP_parsed_litlen[$GZIP_parsed_pos]=$len
  GZIP_parsed_dist[$GZIP_parsed_pos]=$dist

  # GZIP_parsed_dist is sparse, only has elements for backpointers
}


GZIP_do_l2_rle(){

  local -n _code_lengths=$1
  local -n _freqs=$2
  local -n _parsed=$3
  local -n _extra=$4
  local i j index rle_index parse_index
  local cont c elem

  local -a code_lengths_rle=()
  rle_index=-1
 
  # code_lengths_rle is an intermediate array where each element is a run of equal symbols
  # we use it next to do rle
  for ((i = 0; i < ${#_code_lengths[@]}; i++)); do
    _code_lengths[$i]=${_code_lengths[$i]:-0}
    if ([ $i -gt 0 ] && [ ${_code_lengths[$i]} -ne ${_code_lengths[$((i-1))]} ]) || [ $i -eq 0 ]; then
      # create a new run
      ((rle_index++))
    fi
    # append the current symbol to the current run
    code_lengths_rle[$rle_index]="${code_lengths_rle[$rle_index]}${GZIP_rle_symbols[${_code_lengths[$i]}]}"
  done

  # do RLE *and* build frequencies
  index=-1
  parse_index=-1
  while [ $index -lt $rle_index ]; do
    ((index++))
    elem=${code_lengths_rle[$index]}

    # process $elem as needed

    while true; do

      cont=0
      c=${elem:0:1}
      if [ ${#elem} -ge 3 ] && [ "$c" = "0" ]; then
        # if it's a zero, output 17 or 18 until needed
        if [ ${#elem} -le 10 ]; then
          ((parse_index++))
          _parsed[$parse_index]=${GZIP_rle_symbols[17]}
          GZIP_to_bitstring $(( ${#elem} - 3 )) 3
          _extra[$parse_index]=$GZIP_bitstring
          ((_freqs[17]++))
        else
          ((parse_index++))
          if [ ${#elem} -gt 138 ]; then
            _parsed[$parse_index]=${GZIP_rle_symbols[18]}
            GZIP_to_bitstring $(( 138 - 11 )) 7
            _extra[$parse_index]=$GZIP_bitstring
            elem=${elem:138:$(( ${#elem} - 138 ))}
            cont=1
            ((_freqs[18]++))
          else
            _parsed[$parse_index]=${GZIP_rle_symbols[18]}
            GZIP_to_bitstring $(( ${#elem} - 11 )) 7
            _extra[$parse_index]=$GZIP_bitstring
            ((_freqs[18]++))
          fi
        fi
      elif [ ${#elem} -ge 4 ]; then
        ((parse_index++))
        # output 16
        _parsed[$parse_index]=$c
        _freqs["${GZIP_rle_symbols_inv[$c]}"]=$(( ${_freqs["${GZIP_rle_symbols_inv[$c]}"]} + 1))
        elem=${elem:1:$(( ${#elem} - 1 ))}
        while [ ${#elem} -ge 3 ]; do
          ((parse_index++))
          ((_freqs[16]++))
          # output 16 (plus bits) until less than 3 remain
          if [ ${#elem} -gt 6 ]; then
            _parsed[$parse_index]=${GZIP_rle_symbols[16]}
            _extra[$parse_index]=11    # 3 in binary
            elem=${elem:6:$(( ${#elem} - 6 ))}
          else
            _parsed[$parse_index]=${GZIP_rle_symbols[16]}
            GZIP_to_bitstring $(( ${#elem} - 3 )) 2
            _extra[$parse_index]=$GZIP_bitstring
            elem=
          fi
        done
        
        if [ ${#elem} -gt 0 ]; then
          cont=1
        fi

      else
        # run of < 3 (possibly just one)
        for ((j = 0; j < ${#elem}; j++)); do
          c=${elem:$j:1}
          ((parse_index++))
          _parsed[$parse_index]=$c
          _freqs["${GZIP_rle_symbols_inv[$c]}"]=$(( ${_freqs["${GZIP_rle_symbols_inv[$c]}"]} + 1))
        done
      fi

      if [ $cont -eq 0 ]; then
        break
      fi
    done
  done
}


GZIP_deflate_huffman_fixed(){

  local compression_level=$1

  # parse input according to greedy algorithm
  # direct Huffman output
  GZIP_parse_input GZIP_output_literal GZIP_output_backpointer GZIP_fixed_llcodes GZIP_fixed_dcodes $compression_level
}

GZIP_deflate_huffman_dynamic(){

  local compression_level=$1
  local i j sym

  # after parsing, this will be how many items we have in GZIP_parsed_litlen
  GZIP_parsed_pos=-1

  # parse input according to greedy algorithm
  # intermediate output to GZIP_parsed_litlen + GZIP_parsed_dist
  GZIP_parse_input GZIP_output_parsed_literal GZIP_output_parsed_backpointer GZIP_dummy GZIP_dummy $compression_level

  # now we have frequencies for litlen and distances, build "main" huffman trees
  ((GZIP_litlen_freqs[256]++))

  GZIP_dynamic_llcodes=()
  GZIP_dynamic_llcodes_inverse=()
  GZIP_dynamic_dcodes=()
  GZIP_dynamic_dcodes_inverse=()

  ################ litlen
  GZIP_compute_dynamic_tree GZIP_litlen_freqs 286 15 GZIP_dynamic_llcodes GZIP_dynamic_llcodes_inverse

  local hlit=0

  # find hlit by walking code lengths array backwards
  for ((i = 285; i >= 0; i--)); do
    GZIP_code_lengths[$i]=${GZIP_code_lengths[$i]:-0}
    if [ "${GZIP_code_lengths[$i]}" != "0" ] && [ $hlit -eq 0 ]; then
      hlit=$((i + 1))
    fi
  done

  local -a code_lengths=( "${GZIP_code_lengths[@]:0:$hlit}" )

  ############### dist
  GZIP_compute_dynamic_tree GZIP_dist_freqs 30 15 GZIP_dynamic_dcodes GZIP_dynamic_dcodes_inverse

  local hdist=0

  # find hdist by walking code lengths array backwards
  for ((i = 29; i >= 0; i--)); do
    GZIP_code_lengths[$i]=${GZIP_code_lengths[$i]:-0}
    if [ "${GZIP_code_lengths[$i]}" != "0" ] && [ $hdist -eq 0 ]; then
      hdist=$((i + 1))
    fi
  done

  code_lengths=( "${code_lengths[@]}" "${GZIP_code_lengths[@]:0:$hdist}" )
  if [ $hdist -eq 0 ]; then
    # special case
    hdist=1
    code_lengths+=( 0 )
  fi

  # now do RLE with code_lengths

  local -A l2freqs=()
  local -a l2_lld_parsed=()
  local -a l2_lld_extra=()

  GZIP_do_l2_rle code_lengths l2freqs l2_lld_parsed l2_lld_extra

  declare -A l1codes=() l1codes_inverse=()

  ###############
  
  # with l2freqs, we can now compute l1 codes
  GZIP_compute_dynamic_tree l2freqs 19 7 l1codes l1codes_inverse

  # now we should take the code LENGTHS of l1codes and codify them as a sequence of 3-bit values, using the order
  # in the following loop (reversed), but leave out all trailing zeros, so ve start from the end

  local -a l1out=()
  local outi=19
  local do=0
  local val
  local hclen=-1
  for val in 15 1 14 2 13 3 12 4 11 5 10 6 9 7 8 0 18 17 16; do
    ((outi--))
    # skip as many unused values as possible
    if [ $do -eq 0 ] && [ ${#l1codes[$val]} -eq 0 ]; then
      continue
    fi
    do=1
    if [ $hclen -eq -1 ]; then
      hclen=$((outi + 1))
    fi
    GZIP_to_bitstring ${#l1codes[$val]} 3
    l1out[$outi]=$GZIP_bitstring
  done


  # actually write the DEFLATE block.
  # here, everything comes together

  #GZIP_log "HLIT: $hlit, HDIST: $hdist, HCLEN: $hclen"

  # HLIT, number of literal/length codes
  GZIP_to_bitstring $(( hlit - 257 )) 5
  GZIP_put_bit $GZIP_bitstring

  # HDIST, number of distance codes
  GZIP_to_bitstring $(( hdist -1)) 5
  GZIP_put_bit $GZIP_bitstring

  # HCLEN, number of code length codes
  GZIP_to_bitstring $(( hclen - 4 )) 4
  GZIP_put_bit $GZIP_bitstring

  # first, output "l1out"
  for ((i = 0; i < hclen; i++)); do
    GZIP_put_bit ${l1out[$i]}
  done

  # now output l2parsed/l2extra
  # codified according to l1codes
  for ((i = 0; i < ${#l2_lld_parsed[@]}; i++)); do
    GZIP_put_bit_inv "${l1codes["${GZIP_rle_symbols_inv["${l2_lld_parsed["$i"]}"]}"]}"
    GZIP_put_bit "${l2_lld_extra[$i]}"    # already bitstring
  done

  # now output GZIP_parsed_litlen (+ GZIP_parsed_dist if needed)
  # codified according to GZIP_dynamic_llcodes (+ GZIP_dynamic_dcodes if needed)

  for ((i = 0; i <= GZIP_parsed_pos; i++)); do

    sym=${GZIP_parsed_litlen[$i]}

    # stupid method to know whether it's literal or distance
    # exploits GZIP_parsed_dist[]'s sparseness
    if [ "${GZIP_parsed_dist[$i]}" = "" ]; then
      # literal
      GZIP_put_bit_inv "${GZIP_dynamic_llcodes[$sym]}"
    else
      # len + dist
      GZIP_length_symbol=${GZIP_len_codes[$sym]}
      GZIP_put_bit_inv "${GZIP_dynamic_llcodes[$GZIP_length_symbol]}"

      # then extra bits for length (if any)
      GZIP_put_bit "${GZIP_len_extra_vals[$sym]}"

      # then output distance, that is, Huffman code for distance
      dist=${GZIP_parsed_dist[$i]}

      GZIP_dist_symbol=${GZIP_dist_codes[$dist]}
      GZIP_put_bit_inv "${GZIP_dynamic_dcodes[$GZIP_dist_symbol]}"

      # then extra bits for distance (if any)
      GZIP_put_bit "${GZIP_dist_extra_vals[$dist]}"
    fi
  done

}

# Naive algorithm to find longest match at positions $pos and $parsepos
# Set GZIP_matchlen
GZIP_find_match(){

  # $pos is inside window, $parsepos is position inside input buffer

  local pos=$1 parsepos=$2
  local i comparer

  local pp=$parsepos
  ((pos+=GZIP_minlen))
  ((parsepos+=GZIP_minlen))

  local mlen=$GZIP_minlen

  while true; do
    if [ $pos -gt $GZIP_wend ]; then
      # overflowing into input
      comparer=${GZIP_input[$((pos - GZIP_wend - 1 + pp))]}
    else
      comparer=${GZIP_window[$(( pos % GZIP_window_size))]}
    fi

    if [ $parsepos -lt $GZIP_bytes_read ] && [ $mlen -lt 258 ] && [ $comparer -eq ${GZIP_input[$parsepos]} ]; then
      ((mlen++))
      ((pos++))
      ((parsepos++))
    else
      break
    fi

  done

  GZIP_matchlen=$mlen

}

GZIP_add_to_window(){

  local c=$1

  ((GZIP_wend++))
  GZIP_window[$(( GZIP_wend % GZIP_window_size ))]=${c}

  if [ $GZIP_wend -ge $GZIP_window_size ]; then
    GZIP_wstart=$(( GZIP_wend - GZIP_window_size + 1))
  fi

}

# Read input and decide whether to output a literal or a length,distance backpointer
GZIP_parse_input(){

  local literal_output_function=$1
  local backpointer_output_function=$2

  local -n lltree=$3
  local -n dtree=$4

  local compression_level=$5

  local parsepos=0 i
  local seen key pos bestlen bestpos p

  GZIP_parsed_litlen=()
  GZIP_parsed_dist=()

  GZIP_litlen_freqs=()
  GZIP_dist_freqs=()
 

  # input is in GZIP_input, $GZIP_bytes_read bytes

  while true; do

    #GZIP_log "parsepos $parsepos, bytes read $GZIP_bytes_read"
    #GZIP_log "enough back is ${GZIP_enough_back[$compression_level]}, enough len is ${GZIP_enough_len[$compression_level]}"

    if [ $parsepos -gt $(( GZIP_bytes_read - GZIP_minlen )) ]; then
      # end of input, output what's left as literals
      # we do not create keys for these characters (although we could)
      while [ $parsepos -lt $GZIP_bytes_read ]; do
        GZIP_update_crc32 ${GZIP_input[$parsepos]}
        $literal_output_function ${GZIP_input[$parsepos]} lltree
        GZIP_add_to_window ${GZIP_input[$parsepos]}
        ((parsepos++))
      done
      break
    fi

    key=
    for ((i=0; i < GZIP_minlen; i++)); do
      printf -v key '%s%02x' "$key" "${GZIP_input[$(( parsepos + i ))]}"
    done

    #printf -v key '%02x' "${GZIP_input[@]:$parsepos:$GZIP_minlen}"

    seen=0
    if [ "${GZIP_keys[$key]}" != "" ] && [ ${GZIP_keys[$key]} -ge $GZIP_wstart ]; then
      # we already saw this, look for longest match beginning inside the window
      seen=1

      pos=${GZIP_keys[$key]}   # this is inside the window

      GZIP_matchlen=-1

      bestlen=$GZIP_minlen
      bestpos=$pos

      local back_count=0

      while true; do

        if [ $pos -lt $GZIP_wstart ] || [ $pos -eq -1 ]; then
          break
        fi

        GZIP_find_match $pos $parsepos

        if [ $GZIP_matchlen -gt $bestlen ]; then
          bestlen=$GZIP_matchlen
          bestpos=$pos   # inside the window

          if [ $bestlen -eq 258 ] || [ $bestlen -ge $(( GZIP_bytes_read - parsepos )) ]; then
            # can't do better
            break
          fi

        fi

        ((back_count++))
        # control compression level
        if [ $back_count -ge ${GZIP_enough_back[$compression_level]} ] || [ $bestlen -ge ${GZIP_enough_len[$compression_level]} ]; then
          break
        fi
 
        pos=${GZIP_prevs[$pos]}
      done

    fi

    # move window borders and parsepos to account for the match (or single char)
    if [ $seen -eq 1 ]; then
      # we surely have a backpointer and len >= $GZIP_minlen
      # output [len+distance]

      $backpointer_output_function $bestlen $(( GZIP_wend + 1 - bestpos )) lltree dtree

      p=$parsepos

      for ((; parsepos < p + bestlen; parsepos++)); do
        GZIP_update_crc32 ${GZIP_input[$parsepos]}
        GZIP_add_to_window ${GZIP_input[$parsepos]}

        # computing $key as follows is 10x faster than taking the array "slice"
        # (commented below), go figure
        key=
        for ((i=0; i < GZIP_minlen; i++)); do
          if [ $(( parsepos + i )) -lt ${GZIP_bytes_read} ]; then
            printf -v key '%s%02x' "$key" "${GZIP_input[$(( parsepos + i ))]}"
          fi
        done

        # SLOW!
        #printf -v key '%02x' "${GZIP_input[@]:$parsepos:$GZIP_minlen}"

        if [ ${#key} -ge $((GZIP_minlen * 2)) ]; then
          if [ "${GZIP_keys[$key]}" = "" ]; then
            GZIP_prevs[$GZIP_wend]=-1
          else
            GZIP_prevs[$GZIP_wend]=${GZIP_keys[$key]}
          fi
          GZIP_keys[$key]=$GZIP_wend
        fi
      done

    else
      # output single literal char
      GZIP_update_crc32 ${GZIP_input[$parsepos]}
      GZIP_add_to_window ${GZIP_input[$parsepos]}
      GZIP_prevs[$GZIP_wend]=-1
      GZIP_keys[$key]=$GZIP_wend
      $literal_output_function ${GZIP_input[$parsepos]} lltree
      ((parsepos++))
    fi

  done

  $literal_output_function 256 lltree

}


# for (de)compression type 1
GZIP_build_fixed_huffman_trees(){

  local -A lengths=()
  local i

  # lengths
  for ((i = 0; i < 288; i++)); do
    if [ $i -le 143 ]; then
      lengths[$i]=8
    elif [ $i -le 255 ]; then
      lengths[$i]=9
    elif [ $i -le 279 ]; then
      lengths[$i]=7
    else
      lengths[$i]=8
    fi
  done

  GZIP_build_huffman_tree lengths 287 0 GZIP_fixed_llcodes GZIP_fixed_llcodes_inverse

  # distances
  lengths=()
  for ((i = 0; i < 32; i++)); do
      lengths[$i]=5
  done
  GZIP_build_huffman_tree lengths 31 0 GZIP_fixed_dcodes GZIP_fixed_dcodes_inverse

}

# Encoding for length -> code + extra_bits and distance -> code + extra_bits
# Precompute values for later use when compressing
GZIP_compute_len_dist_mappings(){

  local len c d l code dist extra_val extra_bits nlens

  # lengths
  for ((len = 3; len <= 10; len++)); do
    GZIP_len_codes[$len]=$(( len + 254 ))
    GZIP_len_extra_bits[$len]=0
  done
  
  len=11
  code=265
  for ((extra_bits = 1; extra_bits <= 5; extra_bits++)); do
  
    # for each value of extra_bits, there are 2 ** $(( extra_bits + 2 )) lengths
    nlens=$(( 2 ** (extra_bits + 2) ))
  
    # each group has four codes
    c=$code
    for ((; code < c + 4; code++)); do
      l=$len
      extra_val=0
      for ((; len < l + (nlens / 4); len++)); do
        GZIP_len_codes[$len]=$code
        GZIP_len_extra_bits[$len]=$extra_bits
        GZIP_to_bitstring $extra_val $extra_bits
        GZIP_len_extra_vals[$len]=$GZIP_bitstring
        ((extra_val++))
      done 
    done
  done
  
  # 258 is special
  GZIP_len_codes[258]=285
  GZIP_len_extra_bits[258]=0
  unset GZIP_len_extra_vals[258]
  
  # distances
  for ((dist = 1; dist <= 4; dist++)); do
    GZIP_dist_codes[$dist]=$(( dist - 1 ))
    GZIP_dist_extra_bits[$dist]=0
  done
  dist=5
  code=4
  
  for ((extra_bits = 1; extra_bits <= 13; extra_bits++)); do
  
    # for each value of extra_bits, there are 2 ** $(( extra_bits + 1 )) distances
    ndists=$(( 2 ** (extra_bits + 1) ))
  
    # each group has two codes
    c=$code
    for ((; code < c + 2; code++)); do
      d=$dist
      extra_val=0
      for ((; dist < d + (ndists / 2); dist++)); do
        GZIP_dist_codes[$dist]=$code
        GZIP_dist_extra_bits[$dist]=$extra_bits
        GZIP_to_bitstring $extra_val $extra_bits
        GZIP_dist_extra_vals[$dist]=$GZIP_bitstring
        ((extra_val++))
      done 
    done
  done
}

GZIP_show_help(){
  {
    echo "Usage: $0 [ -d ] [ -t <type> ] [ -c <level> ] [ -m <minlen> ] [ -h ]"
    echo 
    echo "-d          Decompress rather than compress."
    echo "-t <type>   (compression only) Compression type: 0 = store uncompressed, 1 = fixed Huffman, 2 = dynamic Huffman (default)"
    echo "-c <level>  (compression only) Compression level: 0 min, ... 9 max. Default: 5"
    echo "-m <minlen> (compression only) Minimum match length. Default: 3"
    echo "-h          Show this help."
    echo ""
    echo "When decompressing, -t, -c and -m are ignored. When compressing, if -t 0, -c is ignored, and if -c 0, -t 0 (store uncompressed) is forced."
    echo ""
    echo "EXAMPLES"
    echo
    echo "$0 -d < file1.txt.gz > file1.txt"
    echo "$0 -t 1 < file2.jpg > file2.jpg.gz"
    echo "$0 -c 9 < file2.jpg > file2.jpg.gz"
  } >&2
}


########################## BEGIN

LC_ALL=C

# default values
compress=1     # compress by default

compression_type=2   # dynamic huffman codes
compression_level=-1
GZIP_minlen=-1

while getopts ":t:c:m:dh" opt; do
  case $opt in
    d)
      compress=0
      ;;
    t)
      compression_type=$OPTARG
      ;;
    c)
      compression_level=$OPTARG
      ;;
    m)
      GZIP_minlen=$OPTARG
      ;;
    h)
      GZIP_show_help
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

if [ $GZIP_minlen -eq -1 ]; then
  GZIP_minlen=3
else
  if [[ ! $GZIP_minlen =~ ^[3-9]$ ]]; then
    GZIP_die "Invalid minimum length (expected 3..9)"
  fi
  if [ $compress -ne 1 ]; then
    GZIP_log "Warning: ignoring minlen when decompressing"
  fi
fi

if [[ ! $compression_type =~ ^[0-2]$ ]]; then
  GZIP_die "Invalid compression type $compression_type (must be one of 0, 1, 2)"
fi

if [ $compress -eq 1 ]; then
  if [ $compression_level -eq -1 ]; then
    compression_level=5
  fi
  if [[ ! $compression_level =~ ^[0-9]$ ]]; then
    GZIP_die "Invalid compression level $compression_level (must be 0-9)"
  fi

  if [ $compression_level -eq 0 ] && [ $compression_type -ne 0 ]; then
    GZIP_log "Warning, compression level 0 requested, forcing stored compression type"
    compression_type=0
  fi
else
  if [ $compression_level -ne -1 ]; then
    GZIP_log "Warning, compression level ignored when decompressing"
  fi
fi

if [ $compress -eq 1 ] && [ -t 1 ]; then
  GZIP_die "Won't write raw bytes to terminal, if you really want to do it pipe to cat"
fi

# defaults for various compression levels
# Chosen because they "seem right" (ie compressed sizes really go down),
# without any additional consideration. Might very well be suboptimal.
declare -a GZIP_enough_back=( [1]=10 30 50 70 90 110 130 150 170 )
declare -a GZIP_enough_len=( [1]=5 10 15 30 50 100 150 200 250 )

GZIP_build_fixed_huffman_trees

if [ $compress -eq 1 ]; then
  # precompute crap
  GZIP_compute_len_dist_mappings
  GZIP_deflate $compression_type $compression_level
else
  GZIP_inflate
fi
