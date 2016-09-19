#!/bin/bash

NTHREADS=$(($(nproc)-1))
if [ $NTHREADS -gt 64 ]; then
    NTHREADS=64
fi
BASEDIR=$(readlink -f "$(dirname "$0")")

DFL_RUNVALS=(0 4 7 11 14 18 21 25 28 32 35 39 42 46 49 53 56 60 63)
DFL_MEMDIR=/dev/shm
DFL_OUTDIR=/mnt/exc_data
DFL_RES=4k
DFL_RUN=0
DFL_MULTI=1
DFL_BUCKET=excamera-us-east-1
DFL_S3DIR=sintel-serial
DFL_INSTNUM=0
DFL_RUNTHREADS=$NTHREADS

if [ "$1" = "-h" ]; then
    echo "Usage: $0"
    echo "Environment variables:"
    echo "  QVALS='0 1 2 3'         runs corresponding cq results (default: '"${DFL_RUNVALS[@]}"')"
    echo "  MEMDIR=/path/to/shm     path to temp space (default: '"$DFL_MEMDIR"')"
    echo "  OUTDIR=/scratch/path    path to scratch space (default: '"$DFL_OUTDIR"')"
    echo "  RES=<1k | 4k>           run 1k or 4k (default: '"$DFL_RES"')"
    echo "  RUN=n                   add a run number tag (default: '"$DFL_RUN"')"
    echo "  MULTI=<0 | 1>           run vpxenc multi-threaded (default: '"$DFL_MULTI"')"
    echo "  RUNTHREADS=nthr         number of threads used in multi-run (default: '"$DFL_RUNTHREADS"')"
    echo "  BUCKET=mybucket         s3 bucket for uploads (default: '"$DFL_BUCKET"')"
    echo "  S3DIR=mykey             s3 dirname for uploads (default: '"$DFL_S3DIR"')"
    echo "  INSTNUM=num             instnum for xterm title (default: '"$DFL_INSTNUM"')"
    exit 0
fi

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
for i in MEMDIR OUTDIR RES RUN MULTI RUNTHREADS BUCKET S3DIR INSTNUM; do
    setwithdefault $i
done

### make sure we can write to MEMDIR
if touch "$MEMDIR"/testfile_ &>/dev/null ; then
    rm "$MEMDIR"/testfile_
else
    echo "ERROR: Cannot write to MEMDIR=$MEMDIR"
    exit 1
fi
if touch "$OUTDIR"/testfile_ &>/dev/null ; then
    rm "$OUTDIR"/testfile_
else
    echo "ERROR: Cannot write to OUTDIR=$OUTDIR"
    exit 1
fi

### set xterm title
if [ "$MULTI" != 0 ]; then
    MSTR="multi"
else
    MSTR="single"
fi
echo -en "\033]0;"$(printf "%02d" $INSTNUM)"-sintel-${RES}-(${RUNVALS[@]})-${MSTR}-${RUN}-ssim\a"

### make sure we can find all the executables
if ! which vpxdec &>/dev/null ; then
    echo "ERROR: cannot find \`vpxdec\`"
    exit 1
fi
if [ ! -x "$BASEDIR"/../daala_tools/dump_ssim ]; then
    echo "You need to build the daala_tools submodule first!"
    exit 1
fi

### number of threads and token parts depends on the MULTI variable
if [ "$MULTI" = 0 ]; then
    NTH=1
else
    NTH=$RUNTHREADS
fi

rm -f "$MEMDIR"/out.ivf "$OUTDIR"/out.y4m
for i in $(seq 0 $((${#RUNVALS[@]} - 1))); do
    QVAL=${RUNVALS[$i]}
    FBASE=run_${RES}_q${QVAL}_r${RUN}_n${NTH}

    # get, reliably
    while [ ! -f "$MEMDIR"/out.ivf ]; do
        aws s3 cp s3://${BUCKET}/${S3DIR}/${FBASE}.ivf "$MEMDIR"/out.ivf
    done

    # decode
    vpxdec --codec=vp8 --threads=$NTHREADS -o "$OUTDIR"/out.y4m "$MEMDIR"/out.ivf

    # dump ssim
    "$BASEDIR"/../daala_tools/dump_ssim -p $(nproc) "$OUTDIR"/sintel-4k.y4m "$OUTDIR"/out.y4m > "$FBASE".out

    # upload result
    aws s3 cp "$FBASE".out s3://${BUCKET}/${S3DIR}/"$FBASE".ssim.txt

    # clean up
    rm "$MEMDIR"/out.ivf "$OUTDIR"/out.y4m
done
