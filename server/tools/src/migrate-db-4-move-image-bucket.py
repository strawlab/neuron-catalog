from __future__ import print_function
import os, sys, time, tempfile
import requests
import neuron_catalog_tools
import urlparse
import urllib
import argparse

def show_doc(doc):
    print('---- %s -----'%doc['_id'])
    for k in doc:
        if k=='_id':
            continue
        print('  ',k, doc[k])

if 1:
    parser = argparse.ArgumentParser()
    parser.add_argument("--settings", type=str, default=None,
                        help="filename of JSON file for Meteor.settings")
    args = parser.parse_args()
    neuron_catalog_tools.set_settings_filename(args.settings)

    db = neuron_catalog_tools.get_db()
    tmpdir = tempfile.mkdtemp()
    cfg = neuron_catalog_tools.get_admin_config()
    bucket_name = cfg['S3Bucket']
    new_base = 'https://%s.s3.amazonaws.com/'%bucket_name

    for fixup_coll in ['binary_data']:
        coll = getattr(db,fixup_coll)
        for doc in coll.find():
            if not doc['secure_url'].startswith('https://s3-eu-west-1.amazonaws.com/'):
                continue

            d_id = doc['_id']
            print()
            print()
            print()
            print("updating %r"%d_id)
            print("old")
            show_doc(doc)


            if 1:
                for key in ['thumb_src', 'thumb_width', 'cache_src', 'cache_height', 'thumb_height', 'cache_width', 'height', 'width' ]:
                    if key in doc:
                        del doc[key]

                url = doc['secure_url']
                r = requests.get(url)
                parts = urlparse.urlparse(url)
                orig_fname = parts.path.split('/')[-1]

                filename = os.path.join(tmpdir,orig_fname)
                with open(filename, 'wb') as fd:
                    fd.write(r.content)
                print("downloaded",url)

                new_key = 'images/%s/%s'%(doc['_id'],doc['name'])
                print("new key in new bucket:",new_key)
                new_url = new_base + urllib.quote(new_key)
                doc['secure_url']=new_url
                print("should be available at",new_url)

                neuron_catalog_tools.upload( filename, new_key )

                try_num = 0
                success = False
                while try_num < 10:
                    # check for completion
                    resp = requests.head(new_url)
                    if resp.status_code==200:
                        success = True
                        break
                    time.sleep(0.5)
                    try_num+=1
                if not success:
                    raise RuntimeError('could not upload?')

                print()
                print("new")
                show_doc(doc)

                print("using save()")
                r=coll.save(doc)
                print("result: %r"%r)

                print("new from db")
                new_doc = coll.find_one({'_id':d_id})
                show_doc(new_doc)

            if 0:
                print("only updating one doc")
                sys.exit(0)
