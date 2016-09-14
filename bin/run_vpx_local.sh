#!/bin/bash

DFL_RUNVALS=(0 4 7 11 14 18 21 25 28 32 35 39 42 46 49 53 56 60 63)
DFL_MEMDIR=/dev/shm
DFL_RES=1k
DFL_RUN=0
DFL_MULTI=0
DFL_BUCKET=excamera-us-east-1
DFL_S3DIR=sintel-serial
DFL_INSTNUM=0

if [ "$1" = "-h" ]; then
    echo "Usage: $0"
    echo "Environment variables:"
    echo "  QVALS='0 1 2 3'         runs with cq=0, 1, 2, 3 (default: '"${DFL_RUNVALS[@]}"')"
    echo "  MEMDIR=/path/to/shm     path to temp space (default: '"$DFL_MEMDIR"')"
    echo "  RES=<1k | 4k>           run 1k or 4k (default: '"$DFL_RES"')"
    echo "  RUN=n                   add a run number tag (default: '"$DFL_RUN"')"
    echo "  MULTI=<0 | 1>           run vpxenc multi-threaded (default: '"$DFL_MULTI"')"
    echo "  BUCKET=mybucket         s3 bucket for uploads (default: '"$DFL_BUCKET"')"
    echo "  S3DIR=mykey             s3 dirname for uploads (default: '"$DFL_S3DIR"')"
    echo "  INSTNUM=num             instnum for xterm title (default: '"$DFL_INSTNUM"')"
    exit 0
fi

NTHREADS=$(($(nproc)-1))
BASEDIR=$(readlink -f "$(dirname "$0")")

function showinfo {
    echo "INFO: "$1"="$2
}

function setwithdefault {
    eval CMDLINEVAL=\${$1}
    if [ -z "$CMDLINEVAL" ]; then
        eval $1=\${DFL_$1}
    else
        eval $1=$CMDLINEVAL
    fi
    eval showinfo $1 \$$1
}

### process QVALS into an array
if [ ! -z "$QVALS" ]; then
    read -a RUNVALS <<< $QVALS
fi
if [ ${#RUNVALS[@]} = 0 ]; then
    RUNVALS=("${DFL_RUNVALS[@]}")
fi
showinfo "QVALS" "$(echo ${RUNVALS[@]})"

### set values from the environment
for i in MEMDIR RES RUN MULTI BUCKET S3DIR INSTNUM; do
    setwithdefault $i
done

### make sure we can write to MEMDIR
if touch "$MEMDIR"/testfile_ &>/dev/null ; then
    rm "$MEMDIR"/testfile_
else
    echo "ERROR: Cannot write to MEMDIR=$MEMDIR"
    exit 1
fi

### set xterm title
if [ "$MULTI" != 0 ]; then
    MSTR="multi"
else
    MSTR="single"
fi
echo -en "\033]0;"$(printf "%02d" $INSTNUM)"-sintel-${RES}-(${RUNVALS[@]})-${MSTR}-${RUN}\a"

### make sure we can find all the executables
if ! which vpxenc &>/dev/null ; then
    echo "ERROR: cannot find \`vpxenc\`"
    exit 1
fi
if [ ! -x "$BASEDIR"/../daala_tools/dump_ssim ]; then
    echo "You need to build the daala_tools submodule first!"
    exit 1
fi

### number of threads and token parts depends on the MULTI variable
if [ "$MULTI" = 0 ]; then
    NTH=1
    TPT=0
else
    NTH=$NTHREADS
    TPT=3
fi

for i in $(seq 0 $((${#RUNVALS[@]} - 1))); do
    QVAL=${RUNVALS[$i]}
    FBASE=run_${RES}_q${QVAL}_r${RUN}_n${NTH}
    ( echo "QUALITY:$QVAL"; echo "RUN:$RUN"; echo "NTHREADS:${NTH}/${TPT}"; time vpxenc --codec=vp8 --good --cpu-used=0 --end-usage=cq --min-q=0 --max-q=63 --cq-level=$QVAL --buf-initial-sz=10000 --buf-optimal-sz=20000 --buf-sz=40000 --undershoot-pct=100 --passes=2 --auto-alt-ref=1 --threads="$NTH" --token-parts="$TPT" --tune=ssim --target-bitrate=4294967295 -o "$MEMDIR"/out.ivf /mnt/exc_data/sintel-${RES}.y4m ) 2>&1 | "$BASEDIR"/clean_ansi.pl 2> "$FBASE".out
    aws s3 cp "$MEMDIR"/out.ivf s3://${BUCKET}/${S3DIR}/"$FBASE".ivf
    aws s3 cp "$FBASE".out s3://${BUCKET}/${S3DIR}/"$FBASE".txt
done
