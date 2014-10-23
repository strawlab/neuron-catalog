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
    for fixup_coll in ['driver_lines','neuron_types']:
        coll = getattr(db,fixup_coll)
        for doc in coll.find():
            show_doc(doc)
            new_neuropils = []
            need_update = True
            for np_orig in doc['neuropils']:
                np_new = np_orig.copy()
                np_new['type'] = [ np_orig['type'] ]
                new_neuropils.append( np_new )

            if need_update:
                #d_id = bson.ObjectId(doc['_id'])
                d_id = doc['_id']
                print("updating %r"%d_id)
                print("old: %s"%doc['neuropils'])
                print("new: %s"%new_neuropils)
                if 1:
                    doc['neuropils']=new_neuropils
                    print("using save()")
                    r=coll.save(doc)
                print("result: %r"%r)
                new_doc = coll.find_one({'_id':d_id})
                show_doc(new_doc)
                assert new_doc['neuropils']==new_neuropils
                #print("only updating one doc")
                #sys.exit(0)
