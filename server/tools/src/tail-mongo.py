from __future__ import print_function
import os, sys, time, tempfile, subprocess, shutil
from email.Utils import formatdate
import requests
from PIL import Image
import argparse
import urlparse
import urllib
import neuron_catalog_tools
import collections

CACHE_DIR_NAME = 'cache'
CACHE_FORMAT_EXTENSION = 'jpg'
CACHE_FORMAT_SIPS_NAME = 'jpeg'

THUMBNAIL_DIR_NAME = 'thumbs'
THUMBNAIL_FORMAT_EXTENSION = 'jpeg'
THUMBNAIL_SQUARE_SIZE = 200

SKIP_EXTENSIONS = ['.am']

def show_doc(doc):
    print('---- %s -----'%doc['_id'])
    for k in doc:
        if k=='_id':
            continue
        print('  ',k, doc[k])

new_docs = []
seen_docs = set()
cache_ids = set()
thumbnail_ids = set()
skip_image_file_for_now = collections.defaultdict( list )

def is_tiff(orig_rel_url):
    orig_rel_url_lower = orig_rel_url.lower()
    return orig_rel_url_lower.endswith('.tif') or orig_rel_url_lower.endswith('.tiff')

def make_thumbnail(coll, doc, upload_key, options):
    this_result = make_cache_inner(doc, upload_key, options, _type='thumbnail')
    if this_result['success']:
        doc['thumb_src']= this_result['download_url']
        doc['thumb_width']=this_result['width']
        doc['thumb_height']=this_result['height']
        r = coll.save(doc)
        if options.verbose:
            print('saved new thumbnail')
            show_doc(doc)
    return this_result

def make_cache(coll, doc, upload_key, options):
    this_result = make_cache_inner(doc, upload_key, options, _type='cache')
    if this_result['success']:
        doc['cache_src']=this_result['download_url']
        doc['cache_width']=this_result['width']
        doc['cache_height']=this_result['height']
        r = coll.save(doc)
        if options.verbose:
            print('saved new cache')
            show_doc(doc)
    return this_result

def make_cache_inner(doc, upload_key, options, _type='cache'):
    cfg = neuron_catalog_tools.get_admin_config()
    bucket_name = cfg['S3Bucket']

    this_result=dict(success = False)
    assert _type in ['cache','thumbnail']

    skip_doc = False
    if doc['_id'] in skip_image_file_for_now:
        bad_urls = skip_image_file_for_now[ doc['_id'] ]
        if doc['secure_url'] in bad_urls:
            skip_doc = True

    if not skip_doc:
        cwd = tempfile.mkdtemp()
        if options.verbose:
            print("made temp dir",cwd)

        try:
            orig_url = doc['secure_url']
            orig_rel_url = get_rel_url(orig_url)
            orig_fname = os.path.split( orig_rel_url )[-1]

            filename = os.path.join( cwd, orig_fname)

            if 1:
                r = requests.get(orig_url)
                with open(filename, 'wb') as fd:
                    fd.write(r.content)

            new_fname = os.path.split(upload_key)[-1]
            out_full = os.path.join( cwd, new_fname)
            if _type=='cache':
                convert(filename, out_full, options)
            elif _type=='thumbnail':
                convert(filename, out_full, options, square_size=THUMBNAIL_SQUARE_SIZE)
            if options.verbose:
                print("OUTPUT",out_full,"to",upload_key)
        except Exception as err:
            if options.fail:
                raise
            if options.verbose:
                print('problems with this document, ignoring for now')
                print("ERROR while processing doc: %s"%(err,))
                show_doc(doc)
            skip_image_file_for_now[ doc['_id'] ].append( doc['secure_url'] )
        else:
            props = get_image_properties(out_full)
            neuron_catalog_tools.upload(out_full, upload_key)

            # compute download URL
            base_url = 'https://%s.s3.amazonaws.com/'%bucket_name
            download_url = base_url + urllib.quote( upload_key )

            # verify download available
            num_tries = 0
            while num_tries < 10 and not this_result['success']:
                resp = requests.head(download_url)
                if resp.status_code==200:
                    this_result['success'] = True
                    this_result['download_url'] = download_url
                    this_result.update(props)
                num_tries += 1
                time.sleep(0.2)
        finally:
            if not options.keep:
                shutil.rmtree(cwd)
    return this_result

def convert(input_fname, output_fname, options, square_size=None):
    assert os.path.exists(input_fname)
    assert not os.path.exists(output_fname)
    use_shell = False

    if sys.platform.startswith('darwin'):
        cmd = "/usr/bin/sips -s format %s %s --out %s"%(CACHE_FORMAT_SIPS_NAME,
                                               input_fname, output_fname)
        if square_size is not None:
            cmd += ' --resampleHeightWidthMax %d'%(square_size,)
        use_shell = True
    else:
        assert sys.platform.startswith('linux')
        if square_size is None:
            cmd = ['convert',input_fname,output_fname]
        else:
            cmd = ['convert',input_fname,
                   '-thumbnail','x%d>'%(square_size,),
                   output_fname,
                   ]
        #cmd = ' '.join(cmd)
    if options.verbose:
        print('CALLING: %r'%(cmd,))
    subprocess.check_call(cmd, shell=use_shell)
    assert os.path.exists(output_fname)

def get_rel_url(url):
    parts = urlparse.urlparse(url)
    path = parts.path
    pp = path.split('/')
    assert pp[0]==''
    pp.pop(0)

    if pp[0]!='images':
        assert pp[1]=='images'
        #bucket_name = pp.pop(0)

    key_in_bucket = '/'.join(pp)
    return key_in_bucket

def parse_urls_from_doc(doc):
    full_url = doc['secure_url']
    orig_rel_url = get_rel_url(full_url)
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
    cache_key = CACHE_DIR_NAME+'/' + doc['_id'] + '/' + doc['name'] + '.' + CACHE_FORMAT_EXTENSION
    full_cache_url = prefix + '/'+ urllib.quote(cache_key)

    # just ensure that we have a different name...
    tmp_input_fname = os.path.split(orig_rel_url)[1]
    tmp_output_fname = os.path.split(cache_key)[1]
    assert tmp_input_fname.lower() != tmp_output_fname.lower()

    thumbnail_key = THUMBNAIL_DIR_NAME+'/' + doc['_id'] + '/' + doc['name'] + '.' + THUMBNAIL_FORMAT_EXTENSION
    full_thumbnail_url = prefix + '/'+ urllib.quote(thumbnail_key)

    extension = os.path.splitext(orig_rel_url)[1]
    return {'prefix':prefix,
            'cache_key':cache_key,
            'full_cache_url':full_cache_url,
            'thumbnail_key':thumbnail_key,
            'full_thumbnail_url':full_thumbnail_url,
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
                bad_urls = skip_image_file_for_now[ doc['_id'] ]
                if doc['secure_url'] in bad_urls:
                    skip_doc = True
            if z['extension'] in SKIP_EXTENSIONS:
                skip_doc=True
                print("SKIPPING: z['extension']: ",z['extension'])
            else:
                print("NOT SKIPPED: z['extension']: ",z['extension'])

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
                    if options.fail:
                        raise
                    if options.verbose:
                        print('problems with this document, ignoring for now')
                    skip_image_file_for_now[ doc['_id'] ].append( doc['secure_url'] )
                else:
                    for key in ['width','height']:
                        doc[key] = props[key]
                    r = coll.save(doc)
                    if options.verbose:
                        print("updated width and height of",doc['_id'])
                finally:
                    if not options.keep:
                        shutil.rmtree(tmpdir)

    full_url = doc['secure_url']
    orig_rel_url = get_rel_url(full_url)
    if is_tiff(orig_rel_url):
        if doc['_id'] not in cache_ids:
            if 1:
                make_cache(coll, doc,
                           z['cache_key'],
                           options)
                cache_ids.add(doc['_id'])

    # ensure thumbnail -----
    if doc['_id'] not in thumbnail_ids:
        if z['extension'] not in SKIP_EXTENSIONS: # cannot make thumbnails of these yet
            make_thumbnail(coll, doc,
                           z['thumbnail_key'],
                           options)
        thumbnail_ids.add(doc['_id'])

def pump_new(coll,options):
    while len(new_docs):
        doc = new_docs.pop(0)
        result = make_cache_if_needed(coll,doc,options)

def fill_cache():
    db = neuron_catalog_tools.get_db()
    for doc in db.binary_data.find():
        if 'cache_src' in doc:
            cache_ids.add( doc['_id'] )

        if 'thumb_src' in doc:
            thumbnail_ids.add( doc['_id'] )

def infinite_poll_loop(options):
    if options.verbose:
        print("Connecting to mongo.")
    if options.settings:
        neuron_catalog_tools.set_settings_filename(options.settings)

    db = neuron_catalog_tools.get_db()
    if options.verbose:
        print("Connected to mongo, processing backlog.")
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

    if options.verbose:
        print("Finished processing backlog, now waiting for new images.")

    while 1:
        for doc in coll.find():
            d_id = doc['_id']
            if doc['secure_url'] == '(uploading)':
                # file not done uploading yet... wait...
                continue
            if d_id not in seen_docs:
                new_docs.append( doc )
                seen_docs.add( d_id )
        status_doc = status_coll.find_one(status_doc_query)

        for_js = formatdate()
        status_coll.update(status_doc_query,{'$set':{'time':for_js,
                                                     'status':'ok',
                                                 }},
                           upsert=True)

        pump_new(coll,options)
        time.sleep(2.0)

if __name__=='__main__':
    parser = argparse.ArgumentParser(
        description="poll for new images and data and process if needed",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("--verbose", action="store_true", default=False,
                        help="be verbose")
    parser.add_argument("--fail", action="store_true", default=False,
                        help="fail on errors instead of keeping going")
    parser.add_argument("--keep", action="store_true", default=False,
                        help="do not delete temporary files")
    parser.add_argument("--settings", type=str, default=None,
                        help="filename of JSON file for Meteor.settings")
    args = parser.parse_args()
    infinite_poll_loop(args)
