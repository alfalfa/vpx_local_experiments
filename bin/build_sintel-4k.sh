#!/bin/bash

BASEDIR=$(readlink -f "$(dirname "$0")")

if [ ! -x "${BASEDIR}"/../src/psha256 ]; then
    echo "ERROR: please make first!"
    exit 1
fi

cd /dev/shm
for i in $(seq 0 887); do
    NUM=$(printf "%08d.y4m" $i)

    while [ ! -f /dev/shm/out ]; do
        aws s3 cp s3://excamera-us-east-1/sintel-4k-y4m_24/$NUM /dev/shm/out
    done

    if [ $i = 0 ]; then
        mv /dev/shm/out /mnt/exc_data/sintel-4k.y4m
    else
        tail -n +2 /dev/shm/out >> /mnt/exc_data/sintel-4k.y4m
        rm /dev/shm/out
    fi
done
#sha1sum -c <<< "698448854097b835c20e55d40fe99dc2a5a76bba  /mnt/exc_data/sintel-4k.y4m"
#sha1sum /mnt/exc_data/sintel-4k.y4m

if ! "${BASEDIR}"/../src/psha256 -c e1e4897faa8a9882673501af00ccf40a4d6b8b690557a34a9867b10868b310ef -p $(nproc) /mnt/exc_data/sintel-4k.y4m; then
    print "ERROR: checksum mismatch. Download seems to have failed."
    exit 1
fi
