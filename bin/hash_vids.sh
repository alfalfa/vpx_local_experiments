#!/bin/bash

if [ -z "$REGION" ]; then
    echo "please set REGION envvar"
    exit 1
fi

for i in $(seq 0 3551); do
    NAME=$(printf "%08d.y4m" $i)
    HASH=$(echo -n $NAME | md5sum | cut -d \  -f 1)

    aws s3 cp --region $REGION s3://excamera-${REGION}/sintel-4k-y4m_06/${NAME} s3://excamera-${REGION}/sintel-4k-y4m_06/${HASH}
    if [ $i -lt 888 ]; then
        aws s3 cp --region $REGION s3://excamera-${REGION}/sintel-4k-y4m_24/${NAME} s3://excamera-${REGION}/sintel-4k-y4m_24/${HASH}
    fi
    if [ $i -lt 1776 ]; then
        aws s3 cp --region $REGION s3://excamera-${REGION}/sintel-4k-y4m_12/${NAME} s3://excamera-${REGION}/sintel-4k-y4m_12/${HASH}
    fi
done
