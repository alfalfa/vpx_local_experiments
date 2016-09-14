#!/bin/bash

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
#sha1sum /mnt/exc_data/sintel-4k.y4m
sha1sum -c <<< "698448854097b835c20e55d40fe99dc2a5a76bba  /mnt/exc_data/sintel-4k.y4m"
