from __future__ import print_function
import os, sys, time, tempfile, subprocess, shutil
import requests
import bson
import neuron_catalog_tools

def show_doc(doc):
    print('---- %s -----'%doc['_id'])
    for k in doc:
        if k=='_id':
            continue
        print('  ',k, doc[k])

if 1:
    db = neuron_catalog_tools.get_db()
    for fixup_coll in ['binary_data']:
        coll = getattr(db,fixup_coll)
        for doc in coll.find():
            need_update = False

            d_id = doc['_id']
            print()
            print()
            print()
            print("updating %r"%d_id)
            print("old")
            show_doc(doc)
            if 'relative_url' in doc:
                del doc['relative_url']
                need_update = True
            if 'url' in doc:
                del doc['url']
                need_update = True
            print("new")
            show_doc(doc)
            if 1:
                print("using save()")
                r=coll.save(doc)
                print("result: %r"%r)
            print("new from db")
            new_doc = coll.find_one({'_id':d_id})
            show_doc(new_doc)
            if 0:
                print("only updating one doc")
                sys.exit(0)
