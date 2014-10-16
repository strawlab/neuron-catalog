from __future__ import print_function
import os, sys, time, tempfile, subprocess, shutil
import requests
import neuron_catalog_tools

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

def is_tiff(orig_rel_url):
    orig_rel_url_lower = orig_rel_url.lower()
    return orig_rel_url_lower.endswith('.tif') or orig_rel_url_lower.endswith('.tiff')

def make_cache(doc, cache_url):
    cwd = tempfile.mkdtemp()

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
    finally:
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

def make_cache_if_needed(doc):
    #show_doc(doc)

    full_url = doc['secure_url']
    orig_rel_url = doc['relative_url']
    assert full_url.endswith(orig_rel_url)
    prefix = full_url[:-len(orig_rel_url)]
    orig_prefix = '/images/'
    assert orig_rel_url.startswith(orig_prefix)
    if is_tiff(orig_rel_url):
        cache_url = CACHE_DIR_NAME+'/' + orig_rel_url[len(orig_prefix):] + \
                    '.' + CACHE_FORMAT_EXTENSION
        if cache_url not in cache_urls:
            skip=False
            if 1:
                # Check for cached image with raw HTTP HEAD
                # request. (Why is it not in boto cache? Maybe another
                # process already made it.)
                full_cache_url = prefix + '/'+ cache_url
                resp = requests.head(full_cache_url)
                if resp.status_code==200:
                    # file already present
                    cache_urls.add(cache_url)
                    skip = True
            if not skip:
                make_cache(doc, cache_url)
                cache_urls.add(cache_url)

def pump_new():
    while len(new_docs):
        doc = new_docs.pop(0)
        # FIXME: actually make cache if needed
        result = make_cache_if_needed(doc)

def fill_cache():
    bucket = neuron_catalog_tools.get_s3_bucket()
    rs = bucket.list(prefix=CACHE_DIR_NAME+'/')
    for key in rs:
        cache_urls.add(key.name)

if 1:
    db = neuron_catalog_tools.get_db()
    coll = db.binary_data

    for doc in coll.find():
        new_docs.append( doc )
        seen_docs.add( doc['_id'] )

    fill_cache()
    pump_new()

    #print('processed backlog, waiting for new images')

    while 1:
        for doc in coll.find():
            d_id = doc['_id']
            if d_id not in seen_docs:
                new_docs.append( doc )
                seen_docs.add( d_id )
        pump_new()
        time.sleep(0.5)
