import fs from 'fs'
import { Meteor } from 'meteor/meteor'

import { UploadedDataFileStore } from '../lib/model'
import { processZip } from './processZip'

Meteor.methods({
  process_data_upload: function () {
    // An upload of binary data was made. Process it.
    var cursor = UploadedDataFileStore.find({})
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

      console.log('fileObj.size()', fileObj.size())
      if (fileObj.size() !== buf.length) {
        throw new Error('unexpected size mismatch')
      }

      const jsonResults = processZip(buf)

      // now remove file
      console.log('  removing zip file')
      UploadedDataFileStore.remove({_id: fileObj._id})

      results.push({jsonResults: jsonResults, filename: fileObj.name()})
    })
    return results
  }
})
