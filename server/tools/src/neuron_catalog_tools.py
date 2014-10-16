from __future__ import print_function
from pymongo import MongoClient
import boto.s3.connection
from boto.s3.key import Key
import os, sys, time, json

_db = None

def get_db():
    global _db
    if _db is not None:
        return _db

    mongodb_url = os.environ.get('MONGO_URL',None)
    if mongodb_url is None:
        print('ERROR: environment variable MONGO_URL must be set (e.g. '
              '"mongodb://127.0.0.1:3001/meteor")', file=sys.stderr)
        sys.exit(1)
    _db = MongoClient(mongodb_url).meteor
    return _db

def get_admin_config():
    db = get_db()
    assert db.admin_config.find().count()==1
    doc = db.admin_config.find_one()
    return doc

def get_s3_bucket():
    cfg = get_admin_config()
    if cfg['s3_region']:
        conn = boto.s3.connect_to_region(cfg['s3_region'],
                                         aws_access_key_id=cfg['s3_key'],
                                         aws_secret_access_key=cfg['s3_secret'],
                                         is_secure=True)
    else:
        conn = boto.s3.connection.S3Connection(cfg['s3_key'],cfg['s3_secret'],
                                               is_secure=True)
    bucket = conn.get_bucket(cfg['s3_bucket'])
    return bucket

def upload(local_filename, path):
    bucket = get_s3_bucket()
    k = Key(bucket)
    k.key = path
    k.set_contents_from_filename(local_filename)

def normalize_json(buf):
    buf = json.dumps(json.loads(buf),sort_keys=True)
    return buf

def ensure_public_read():
    bucket = get_s3_bucket()
    cfg = get_admin_config()
    desired_policy = """{
	"Version": "2008-10-17",
	"Statement": [
		{
			"Sid": "AllowPublicRead",
			"Effect": "Allow",
			"Principal": {
				"AWS": "*"
			},
			"Action": "s3:GetObject",
			"Resource": "arn:aws:s3:::%s/*"
		}
	]
}"""%(cfg['s3_bucket'],)
    desired_policy = normalize_json(desired_policy)

    try:
        actual_policy = bucket.get_policy()
        actual_policy = normalize_json(actual_policy)
    except boto.exception.S3ResponseError:
        actual_policy = None

    if actual_policy==desired_policy:
        # OK
        return
    assert actual_policy is None, "will not overwrite existing policy"
    bucket.set_policy(desired_policy)
