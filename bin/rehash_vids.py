#!/usr/bin/python

import md5
import os
import sys

import boto3

s3_client = boto3.client('s3')

do_delete = False

region = os.getenv('REGION')
if region is None:
    print "Please set REGION envvar"
    sys.exit(1)
bucket = "excamera-%s" % region

folders = []
for vid in [ "sintel", "tears" ]:
    for frames in [ "06", "12", "24" ]:
        folders.append("%s-4k-y4m_%s" % (vid, frames))

for folder in folders:
    # test for existence of hashed filenames
    hashed_exists = False
    try:
        s3_client.head_object(Bucket=bucket, Key="%s/%s" % (folder, md5.md5('00000000.y4m').hexdigest()))
    except:
        pass
    else:
        hashed_exists = True

    # test for existence of non-hashed filenames
    numeric_exists = False
    try:
        s3_client.head_object(Bucket=bucket, Key="%s/00000000.y4m" % folder)
    except:
        pass
    else:
        numeric_exists = True

    if not hashed_exists and not numeric_exists:
        print "WARNING: %s does not seem to exist" % folder
        continue

    if folder[0] is "t":
        length = 734
    else:
        length = 888

    if folder[-1] is "6":
        length *= 4
    elif folder[-1] is "2":
        length *= 2

    for vidnum in range(0, length):
        vidname = "%08d.y4m" % vidnum
        inname = vidname
        hashname = md5.md5(vidname).hexdigest()
        if hashed_exists:
            inname = hashname

        prehash = hashname[0:4]
        target = "%s-%s/%s" % (prehash, folder, vidname)

        s3_client.copy_object(Bucket=bucket, Key=target, CopySource="%s/%s/%s" % (bucket, folder, inname))
        print "%s -> %s" % (inname, target)

        if do_delete and hashed_exists:
            s3_client.delete_object(Bucket=bucket, Key=hashname)
