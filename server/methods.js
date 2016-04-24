import fs from 'fs'
import { Meteor } from 'meteor/meteor'

import { ensure_latest_json_schema } from '../lib/export_data'
import { ArchiveFileStore, ZipFileStore, CacheFileStore } from '../lib/model'
import { JSZip, MIME, FS } from './globals-server'
import { do_json_inserts } from './json_data'

Meteor.methods({
  process_zip: function () {
    // An upload of binary data was made. Process it.
    var cursor = ZipFileStore.find({})
    const results = []
    cursor.forEach(function (fileObj) {
      // unzip and process...

      const storeName = 'zip_files'
      console.log('Processing .zip upload ' + fileObj.name())
      for (var i = 0; i < 5; i++) {
        if (fileObj.hasStored(storeName)) {
          break
        }
        console.log('storage not done, sleeping')
        Meteor._sleepForMs(1000)
      }

      // Ideally, we would just directly get the data from the FS.File object
      // but I could not figure out how to do that. So we do the below hack
      // instead.

      var readStream = fileObj.createReadStream()
      // This is a hack. We should get the buffer directly from CollectionFS.
      var hack_fullpath = readStream.path
      var buf = fs.readFileSync(hack_fullpath)

      var zip = new JSZip()

      console.log('loading zip with length of', buf.length)
      console.log('fileObj.size()', fileObj.size())
      if (fileObj.size() !== buf.length) {
        throw new Error('unexpected size mismatch')
      }
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

      // now remove file
      console.log('  removing zip file')
      ZipFileStore.remove({_id: fileObj._id})

      results.push({jsonResults: jsonResults, filename: fileObj.name()})
    })
    return results
  }
})
