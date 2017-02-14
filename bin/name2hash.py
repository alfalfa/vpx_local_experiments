#!/usr/bin/python

import md5
import sys

for fname in ( x.strip() for x in sys.stdin.readlines() ):
    print "%s:%s" % (fname, md5.md5(fname).hexdigest())

