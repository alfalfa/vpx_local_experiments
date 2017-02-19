#!/bin/bash

BASEDIR=$(readlink -f "$(dirname "$0")")

if [ -z "$REGION" ]; then
    REGION=us-west-2
fi

if [ ! -x "${BASEDIR}"/../src/psha256 ]; then
    echo "ERROR: please make first!"
    exit 1
fi

cd /dev/shm
for i in $(seq 0 834); do
    NUM=$(printf "%08d.y4m" $i)
    HASH=$(echo -n $NUM | md5sum | cut -d \  -f 1)

    while [ ! -f /dev/shm/out ]; do
        aws s3 cp s3://excamera-${REGION}/tears-4k-y4m_24/$HASH /dev/shm/out
    done

    if [ $i = 0 ]; then
        mv /dev/shm/out /mnt/exc_data/tears-4k.y4m
    else
        tail -n +2 /dev/shm/out >> /mnt/exc_data/tears-4k.y4m
        rm /dev/shm/out
    fi
done

if ! "${BASEDIR}"/../src/psha256 -c c598e75722fd4b2dad9d7dafcd65bb321607185f2ee4303b59407d0c18d0d33a -p $(nproc) /mnt/exc_data/tears-4k.y4m; then
    print "ERROR: checksum mismatch. Download seems to have failed."
    exit 1
fi
