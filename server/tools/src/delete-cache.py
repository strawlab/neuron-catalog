from __future__ import print_function
import os, sys, time, tempfile
import requests
import neuron_catalog_tools
import urlparse
import urllib
import argparse

CACHE_DIR_NAME = 'cache'
THUMBNAIL_DIR_NAME = 'thumbs'

if 1:
    parser = argparse.ArgumentParser()
    parser.add_argument("--settings", type=str, default=None,
                        help="filename of JSON file for Meteor.settings")
    args = parser.parse_args()
    neuron_catalog_tools.set_settings_filename(args.settings)

    for prefix in [CACHE_DIR_NAME, THUMBNAIL_DIR_NAME]:
        bucket = neuron_catalog_tools.get_s3_bucket()
        rs = bucket.list(prefix=prefix+'/')
        for key in rs:
            bucket.delete_key(key)

    db = neuron_catalog_tools.get_db()
    coll = db.binary_data
    for doc in coll.find():
        changed = False
        for key in ['thumb_src', 'cache_src']:
            if key in doc:
                del doc[key]
                changed = True
        if changed:
            coll.save(doc)
