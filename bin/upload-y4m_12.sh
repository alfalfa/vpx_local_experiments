#!/bin/bash

if [ -z "$1" ]; then
    START=0
else
    START=$1
fi

for i in $(seq $START 1775); do
    NUM=$(printf "%08d.y4m" $i)
    while [ ! -f $NUM ]; do
        sleep 1
    done

    while ! aws s3 cp $NUM s3://${BUCKET}/sintel-${RES}-y4m_12/$NUM; do
        sleep 1
    done

    rm $NUM
done
