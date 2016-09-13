#!/bin/bash

if ! which vpxenc &>/dev/null ; then
    echo "ERROR: cannot find \`vpxenc\`"
    exit 1
fi

if [ -z "$QVALS" ]; then
    RUNVALS=(0 4 7 11 14 18 21 25 28 32 35 39 42 46 49 53 56 60 63)
else
    read -a RUNVALS <<< $QVALS
fi
echo "INFO: RUNVALS="${RUNVALS[@]}

NTHREADS=$(($(nproc)-1))
BASEDIR=$(readlink -f "$(dirname "$0")")

if [ ! -x "$BASEDIR"/../daala_tools/dump_ssim ]; then
    echo "You need to build the daala_tools submodule first!"
    exit 1
fi

if [ -z "$OUTDIR" ]; then
    OUTDIR=/mnt/exc_scratch
fi
if touch "$OUTDIR"/testfile_ &>/dev/null ; then
    rm "$OUTDIR"/testfile_
else
    echo "ERROR: Cannot write to OUTDIR=$OUTDIR"
    exit 1
fi

if [ -z "$MEMDIR" ]; then
    MEMDIR=/dev/shm
fi
if touch "$MEMDIR"/testfile_ &>/dev/null ; then
    rm "$MEMDIR"/testfile_
else
    echo "ERROR: Cannot write to MEMDIR=$MEMDIR"
    exit 1
fi

if [ -z "$RES" ]; then
    RES=1k
fi

if [ -z "$RUN" ]; then
    RUN=0
fi

for i in $(seq 0 $((${#RUNVALS[@]} - 1))); do
    QVAL=${RUNVALS[$i]}
    ( echo "QUALITY:$QVAL"; echo "RUN:$RUN"; echo "NTHREADS:1"; time vpxenc --codec=vp8 --good --cpu-used=0 --end-usage=cq --min-q=0 --max-q=63 --cq-level=$QVAL --buf-initial-sz=10000 --buf-optimal-sz=20000 --buf-sz=40000 --undershoot-pct=100 --passes=2 --auto-alt-ref=1 --threads=1 --token-parts=0 --tune=ssim --target-bitrate=4294967295 -o "$MEMDIR"/out.ivf /mnt/exc_data/sintel-${RES}.y4m ) 2>&1 | "$BASEDIR"/clean_ansi.pl 2> run_${RES}_q${QVAL}_r${RUN}_n1.out
    vpxdec --codec=vp8 -o "$OUTDIR"/out.y4m "$MEMDIR"/out.ivf
    "$BASEDIR"/../daala_tools/dump_ssim /mnt/exc_data/sintel-${RES}.y4m "$OUTDIR"/out.y4m 2>&1 | tee -a run_${RES}_q${QVAL}_r${RUN}_n1.out

    ( echo "QUALITY:$QVAL"; echo "RUN:$RUN"; echo "NTHREADS:$NTHREADS"; time vpxenc --codec=vp8 --good --cpu-used=0 --end-usage=cq --min-q=0 --max-q=63 --cq-level=$QVAL --buf-initial-sz=10000 --buf-optimal-sz=20000 --buf-sz=40000 --undershoot-pct=100 --passes=2 --auto-alt-ref=1 --threads=$NTHREADS --token-parts=3 --tune=ssim --target-bitrate=4294967295 -o "$MEMDIR"/out.ivf /mnt/exc_data/sintel-${RES}.y4m ) 2>&1 | "$BASEDIR"/clean_ansi.pl 2> run_${RES}_q${QVAL}_r${RUN}_n${NTHREADS}.out
    vpxdec --codec=vp8 -o "$OUTDIR"/out.y4m "$MEMDIR"/out.ivf
    "$BASEDIR"/../daala_tools/dump_ssim /mnt/exc_data/sintel-${RES}.y4m "$OUTDIR"/out.y4m 2>&1 | tee -a run_${RES}_q${QVAL}_r${RUN}_n${NTHREADS}.out
done
