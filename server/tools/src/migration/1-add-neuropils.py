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
            need_update = False
            for np_id in doc['neuropils']:
                if hasattr(np_id,'has_key'):
                    print("already updated!")
                    break
                new_neuropils.append( {'_id':np_id,
                                       'type':'unspecified'} )
                need_update = True

            if need_update:
                #d_id = bson.ObjectId(doc['_id'])
                d_id = doc['_id']
                print("updating %r"%d_id)
                print("old: %s"%doc['neuropils'])
                print("new: %s"%new_neuropils)
                if 0:
                    print('----- test find ----')
                    for doc in coll.find({'_id:':d_id}):
                        show_doc(doc)
                    print('----- test find ----')
                    r = coll.update({'_id:':d_id},
                                    {'$set': {'neuropils':new_neuropils}},
                                    w=1,
                                    )
                elif 0:
                    print("replacing whole doc")
                    doc2 = doc.copy()
                    doc2['neuropils']=new_neuropils
                    r = coll.update({'_id:':d_id},
                                    doc2)
                else:
                    doc['neuropils']=new_neuropils
                    print("using save()")
                    r=coll.save(doc)
                print("result: %r"%r)
                new_doc = coll.find_one({'_id':d_id})
                show_doc(new_doc)
                assert new_doc['neuropils']==new_neuropils
                #print("only updating one doc")
                #sys.exit(0)
