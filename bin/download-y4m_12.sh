#!/bin/bash

if [ -z "$1" ]; then
    START=0
else
    START=$1
fi

for i in $(seq $START 1775); do
    NUMj=$(printf "%08d.y4m" $((2 * $i)))
    NUMk=$(printf "%08d.y4m" $(($((2 * $i)) + 1)))
    NUMi=$(printf "%08d.y4m" $i)

    while [ ! -f /dev/shm/out ]; do
        aws s3 cp s3://${BUCKET}/sintel-${RES}-y4m_06/$NUMj /dev/shm/out
    done
    while [ ! -f /dev/shm/out1 ]; do
        aws s3 cp s3://${BUCKET}/sintel-${RES}-y4m_06/$NUMk /dev/shm/out1
    done
    tail -n +2 /dev/shm/out1 >> /dev/shm/out

    rm /dev/shm/out1
    mv /dev/shm/out /dev/shm/$NUMi
done
