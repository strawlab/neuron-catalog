# see http://jwage.com/post/30490196727/mongodb-tailable-cursors
from __future__ import print_function
from pymongo import MongoClient
import boto
import os, sys, time

mongodb_url = os.environ.get('MONGO_URL')

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
    pass

def make_cache_if_needed(doc):
    show_doc(doc)
    orig_rel_url = doc['relative_url']
    orig_prefix = '/images/'
    assert orig_rel_url.startswith(orig_prefix)
    if is_tiff(orig_rel_url):
        cache_url = '/cache/' + orig_rel_url[len(orig_prefix)] + '.png'
        if cache_url not in cache_urls:
            make_cache(doc, cache_url)
            cache_urls.add(cache_url)

def pump_new():
    while len(new_docs):
        doc = new_docs.pop(0)
        # FIXME: actually make cache if needed
        result = make_cache_if_needed(doc)

if 1:
    db = MongoClient(mongodb_url).meteor
    coll = db.binary_data

    for doc in coll.find():
        new_docs.append( doc )
        seen_docs.add( doc['_id'] )

    pump_new()

    while 1:
        for doc in coll.find():
            d_id = doc['_id']
            if d_id not in seen_docs:
                new_docs.append( doc )
                seen_docs.add( d_id )
        pump_new()
        time.sleep(0.5)
