import { JSZip, MIME, FS } from './globals-server'
import { ensure_latest_json_schema } from '../lib/export_data'
import { do_json_inserts } from './json_data'
import { ArchiveFileStore, CacheFileStore } from '../lib/model'

export function processZip (buf) {
  var zip = new JSZip()

  console.log('loading zip with length of', buf.length)
  zip.load(buf)

  let jsonResults = null
  for (var filename in zip.files) {
    console.log('  processing zip filename: ' + filename)
    var contents = zip.files[filename]
    if (filename === 'data.json') {
      var payload_raw = JSON.parse(contents.asBinary())
      var payload = ensure_latest_json_schema(payload_raw)
      jsonResults = do_json_inserts(payload)
      continue // continue to next file
    }
    var parts = filename.split('/')
    if (parts.length !== 3) {
      throw new Error('unexpected filename:' + filename)
    }
    var store
    if (parts[0] === 'archive') {
      store = ArchiveFileStore
    } else if (parts[0] === 'cache') {
      store = CacheFileStore
    } else {
      throw new Error('not in archive or cache dir:' + filename)
    }
    var _id = parts[1]
    var testFileObj = store.findOne({_id: _id})

    if (typeof testFileObj !== 'undefined' && testFileObj !== null) {
      console.log('WARNING: already have ' + parts[0] + ' with id ' + _id + '. Skipping.')
      continue
    }

    var origName = parts[2]
    var thisBuf = contents.asNodeBuffer()
    var mtype = MIME.lookup(origName)
    var thisFileObj = new FS.File()
    thisFileObj.attachData(thisBuf, {type: mtype})
    thisFileObj._id = _id
    thisFileObj.name(origName)
    thisFileObj.updatedAt(contents.date)
    store.insert(thisFileObj)
  }
  return jsonResults
}
