import fs from 'fs'
import { Meteor } from 'meteor/meteor'

import { JSZip } from './globals-server'
import { UploadedTempFileStore, UploadTempStoreName } from '../lib/model'
import { processRawJsonBuf } from './json_data'
import { processZip } from './processZip'

function processUpload (fileObj) {
  // process a file, which is either a .zip or a .json
  console.log('Processing upload ' + fileObj.name())
  for (var i = 0; i < 5; i++) {
    if (fileObj.hasStored(UploadTempStoreName)) {
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

  console.log('fileObj.size()', fileObj.size())
  if (fileObj.size() !== buf.length) {
    throw new Error('unexpected size mismatch')
  }

  let isZip = false
  const zip = new JSZip()
  console.log('loading file with length of', buf.length)

  try {
    zip.load(buf)
    isZip = true
  } catch (e) {
    console.log('not a zip file:', e)
  }

  let jsonResults = null
  let error = null
  try {
    jsonResults = isZip ? processZip(zip) : processRawJsonBuf(buf)
  } catch (e) {
    error = e.toString()
  } finally {
    // now remove file
    console.log('  removing file')
    UploadedTempFileStore.remove({_id: fileObj._id})
  }

  return {jsonResults, filename: fileObj.name(), error}
}

Meteor.methods({
  process_data_upload: function () {
    // An upload of binary data was made. Process it.
    const cursor = UploadedTempFileStore.find({})
    return cursor.map(processUpload)
  }
})
