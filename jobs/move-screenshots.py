#!/usr/bin/env python

import os
import shutil
import ConfigParser

from datetime import date
from datetime import timedelta

# get yesterday's date, in YYYY-MM-DD format
d = timedelta(days=-1)

# new directory name
yest_dir = (date.today() + d).isoformat()

# move all files with this prefix
yest_pre = yest_dir.replace("-", "")

#
config = ConfigParser.ConfigParser()
config.read("./config.cfg")
dropbox_dir = config.get('dirs', 'dropbox')
offload_dir = config.get('dirs', 'offload')
offload_dir = os.path.join(offload_dir, yest_dir)

# make the destination directory
if not os.path.exists(offload_dir):
    os.makedirs(offload_dir)

for root, dirs, files in os.walk(dropbox_dir):
    for name in files:
        if name.startswith(yest_pre):
            shutil.move(os.path.join(root, name), offload_dir)
