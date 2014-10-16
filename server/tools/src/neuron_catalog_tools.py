from __future__ import print_function
from pymongo import MongoClient
import boto
import os, sys, time

def get_db():
    mongodb_url = os.environ.get('MONGO_URL',None)
    if mongodb_url is None:
        print('ERROR: environment variable MONGO_URL must be set (e.g. '
              '"mongodb://127.0.0.1:3001/meteor")', file=sys.stderr)
        sys.exit(1)
    db = MongoClient(mongodb_url).meteor
    return db
