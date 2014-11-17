from __future__ import print_function
import os, sys, time, tempfile, subprocess, shutil
from email.Utils import formatdate
import requests
from PIL import Image
import argparse
import neuron_catalog_tools
import collections

CACHE_DIR_NAME = 'cache'
CACHE_FORMAT_EXTENSION = 'jpg'
CACHE_FORMAT_SIPS_NAME = 'jpeg'

def show_doc(doc):
    print('---- %s -----'%doc['_id'])
    for k in doc:
        if k=='_id':
            continue
        print('  ',k, doc[k])

new_docs = []
seen_docs = set()
cache_urls = set()
skip_image_file_for_now = collections.defaultdict( list )

def is_tiff(orig_rel_url):
    orig_rel_url_lower = orig_rel_url.lower()
    return orig_rel_url_lower.endswith('.tif') or orig_rel_url_lower.endswith('.tiff')

def make_cache(doc, cache_url, options):
    cwd = tempfile.mkdtemp()
    if options.verbose:
        print("made temp dir",cwd)

    try:
        orig_url = doc['secure_url']
        orig_rel_url = doc['relative_url']
        orig_fname = os.path.split( orig_rel_url )[-1]

        filename = os.path.join( cwd, orig_fname)

        if 0:
            r = requests.get(orig_url,stream=True)
            chunk_size=4096
            with open(filename, 'wb') as fd:
                for chunk in r.iter_content(chunk_size):
                    fd.write(chunk)
                    print("got %d bytes"%len(chunk))
        else:
            r = requests.get(orig_url)
            with open(filename, 'wb') as fd:
                fd.write(r.content)

        new_fname = os.path.split(cache_url)[-1]
        out_full = os.path.join( cwd, new_fname)
        convert(filename, out_full)
        #print("OUTPUT",out_full,"to",cache_url)
        neuron_catalog_tools.upload(out_full, cache_url)
    except:
        print("ERROR while processing doc")
        show_doc(doc)
        raise
    finally:
        if not options.keep:
            shutil.rmtree(cwd)

def convert(input_fname, output_fname):
    assert os.path.exists(input_fname)
    assert not os.path.exists(output_fname)

    if sys.platform.startswith('darwin'):
        cmd = "sips -s format %s %s --out %s"%(CACHE_FORMAT_SIPS_NAME,
                                               input_fname, output_fname)
    else:
        assert sys.platform.startswith('linux')
        cmd = ['convert',input_fname,output_fname]
        cmd = ' '.join(cmd)
    subprocess.check_call(cmd, shell=True)
    assert os.path.exists(output_fname)

def parse_urls_from_doc(doc):
    full_url = doc['secure_url']
    orig_rel_url = doc['relative_url']
    assert full_url.endswith(orig_rel_url)
    if not orig_rel_url.startswith('/'):
        orig_rel_url = '/' + orig_rel_url
    prefix = full_url[:-len(orig_rel_url)]

    if orig_rel_url.startswith('/images/'):
        my_type = 'images'
    elif orig_rel_url.startswith('/volumes/'):
        my_type = 'volumes'
    else:
        raise RuntimeError('unknown directory: %r'%orig_rel_url)

    orig_prefix = '/'+my_type+'/'

    assert orig_rel_url.startswith(orig_prefix)
    cache_url = CACHE_DIR_NAME+'/' + orig_rel_url[len(orig_prefix):] + \
                '.' + CACHE_FORMAT_EXTENSION
    full_cache_url = prefix + '/'+ cache_url
    extension = os.path.splitext(orig_rel_url)[1]
    return {'cache_url':cache_url,
            'prefix':prefix,
            'full_cache_url':full_cache_url,
            'type':my_type,
            'extension':extension,
        }

def get_image_properties(filename):
    im = Image.open(filename)
    w,h = im.size
    return dict(width=w, height=h)

def make_cache_if_needed(coll, doc, options):
    if options.verbose:
        print("new document:")
        show_doc(doc)


    if options.verbose:
        print()


    z = parse_urls_from_doc(doc)

    if doc['type']=='images':
        if 'width' not in doc or 'height' not in doc:
            skip_doc = False
            if doc['_id'] in skip_image_file_for_now:
                bad_relative_urls = skip_image_file_for_now[ doc['_id'] ]
                if doc['relative_url'] in bad_relative_urls:
                    skip_doc = True

            if not skip_doc:
                r = requests.get(doc['secure_url'])
                tmpdir = tempfile.mkdtemp()
                if options.verbose:
                    print("getting image size: made temp dir",tmpdir)
                try:
                    filename = os.path.join(tmpdir,'image'+z['extension'])
                    with open(filename, 'wb') as fd:
                        fd.write(r.content)
                    if options.verbose:
                        print('getting image properties for %r (doc id %r)'%(filename,doc['_id']))
                    props = get_image_properties(filename)
                except:
                    if options.verbose:
                        print('problems with this document, ignoring for now')
                    skip_image_file_for_now[ doc['_id'] ].append( doc['relative_url'] )
                else:
                    for key in ['width','height']:
                        doc[key] = props[key]
                    r = coll.save(doc)
                    if options.verbose:
                        print("updated width and height of",doc['_id'])
                finally:
                    if not options.keep:
                        shutil.rmtree(tmpdir)

    orig_rel_url = doc['relative_url']
    if is_tiff(orig_rel_url):
        if z['cache_url'] not in cache_urls:
            skip=False
            if 1:
                # Check for cached image with raw HTTP HEAD
                # request. (Why is it not in boto cache? Maybe another
                # process already made it.)

                resp = requests.head(z['full_cache_url'])
                if resp.status_code==200:
                    # file already present
                    cache_urls.add(z['cache_url'])
                    skip = True
            if not skip:
                make_cache(doc, z['cache_url'], options)
                cache_urls.add(z['cache_url'])

def pump_new(coll,options):
    while len(new_docs):
        doc = new_docs.pop(0)
        result = make_cache_if_needed(coll,doc,options)

def fill_cache():
    bucket = neuron_catalog_tools.get_s3_bucket()
    rs = bucket.list(prefix=CACHE_DIR_NAME+'/')
    for key in rs:
        cache_urls.add(key.name)

def infinite_poll_loop(options):
    db = neuron_catalog_tools.get_db()
    coll = db.binary_data

    for doc in coll.find():
        new_docs.append( doc )
        seen_docs.add( doc['_id'] )

    fill_cache()
    pump_new(coll,options)

    if options.verbose:
        print('processed backlog, waiting for new images')

    status_collection_name = "upload_processor_status"
    status_doc_query = {'_id':'status'}
    status_coll = db[status_collection_name]
    status_coll.remove(status_doc_query)
    assert status_coll.find().count()==0

    while 1:
        this_cache_urls = set()
        for doc in coll.find():
            d_id = doc['_id']
            if d_id not in seen_docs:
                new_docs.append( doc )
                seen_docs.add( d_id )
            this_cache_urls.add( parse_urls_from_doc(doc)['cache_url'] )
        status_doc = status_coll.find_one(status_doc_query)

        for_js = formatdate()
        status_coll.update(status_doc_query,{'$set':{'time':for_js,
                                                     'status':'ok',
                                                 }},
                           upsert=True)

        delete_cache_set = cache_urls - this_cache_urls
        for cache_url in delete_cache_set:
            # delete stale cached image
            bucket = neuron_catalog_tools.get_s3_bucket()
            bucket.delete_key(cache_url)
            cache_urls.remove( cache_url )

        pump_new(coll,options)
        time.sleep(2.0)

if __name__=='__main__':
    parser = argparse.ArgumentParser(
        description="poll for new images and data and process if needed",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("--verbose", action="store_true", default=False,
                        help="be verbose")
    parser.add_argument("--keep", action="store_true", default=False,
                        help="do not delete temporary files")
    args = parser.parse_args()
    infinite_poll_loop(args)
