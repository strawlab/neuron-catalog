from __future__ import print_function
import os, sys, time
import argparse
import neuron_catalog_tools
import json

def main():
    parser = argparse.ArgumentParser(
        description="get or set neuron catalog administrative configuration",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    subparsers = parser.add_subparsers(dest='subparser_name')
    parser_delete = subparsers.add_parser('delete',
                                          help="remove the current configuration")
    parser_get = subparsers.add_parser('get',
                                       help="print the current configuration as JSON to stdout")
    parser_set = subparsers.add_parser('set',
                                       help="set the current configuration as JSON from stdin")
    args = parser.parse_args()

    db = neuron_catalog_tools.get_db()
    coll = db.admin_config

    if args.subparser_name=='delete':
        coll.remove({})
        return

    assert coll.find().count() <= 1, "multiple documents in the admin_config collection"

    if args.subparser_name=='get':
        doc = coll.find_one()
        if doc is not None:
            del doc["_id"]
            buf = json.dumps(doc)
            sys.stdout.write(buf)
        return

    if args.subparser_name=='set':
        buf = sys.stdin.read()
        doc = json.loads(buf)
        if "_id" in doc:
            del doc["_id"]
        coll.remove({})
        coll.insert( doc )
        return
    
if __name__=='__main__':
    main()
