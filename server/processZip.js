import { MIME, FS } from './globals-server'
import { processJsonBuf } from './json_data'
import { ArchiveFileStore, CacheFileStore } from '../lib/model'

export function processZip (zip) {
  let jsonResults = null
  for (var filename in zip.files) {
    console.log('  processing zip filename: ' + filename)
    var contents = zip.files[filename]
    if (filename === 'data.json') {
      var payload_raw = JSON.parse(contents.asBinary())
      jsonResults = processJsonBuf(payload_raw.collections)
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
