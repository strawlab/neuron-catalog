Meteor.methods({
  get_specializations: function () {
    var x = Meteor.settings.NeuronCatalogSpecializations;
    if (typeof x !== "undefined" && x !== null) {
      return x;
    } else {
      return [];
    }
  },
  process_zip: function () {
    // An upload of binary data was made. Process it.
    var cursor = ZipFileStore.find({});
    cursor.forEach(function (fileObj) {
      // unzip and process...

      console.log("Processing .zip upload "+fileObj.name());
      if (!fileObj.hasStored()) {
        console.log("storage not done, sleeping");
        Meteor._sleepForMs(1000);
      }

      // Ideally, we would just directly get the data from the FS.File object
      // var buf = fileObj.data;
      //  but the above line does not work. So we do the below hack instead.

      // This is a hack. We should ask CollectionFS where the file is.
      var hack_fullpath = process.env.PWD+"/.meteor/local/cfs/files/zip_files/zip_filestore-"+fileObj._id+"-"+fileObj.name();
      var buf = fs.readFileSync(hack_fullpath);

      var zip = new JSZip();

      console.log("loading zip with length of", buf.length)
      console.log("fileObj.size()", fileObj.size());
      if (fileObj.size() != buf.length) {
        throw "unexpected size mismatch"
      }
      zip.load(buf);

      for (var filename in zip.files) {
        console.log("  processing zip filename: "+filename)
        var contents = zip.files[filename];
        if (filename == "data.json") {
          var payload_raw = JSON.parse( contents.asBinary() );
          var payload = ensure_latest_json_schema( payload_raw );
          do_json_inserts(payload);
          continue // continue to next file
        }
        var parts = filename.split('/');
        if (parts.length != 3) {
          throw "unexpected filename:"+filename
        }
        var store;
        if (parts[0] == "archive") {
          store = ArchiveFileStore;
        } else if (parts[0] == "cache") {
          store = CacheFileStore;
        } else {
          throw "not in archive or cache dir:"+filename;
        }
        var _id = parts[1];
        var testFileObj = store.findOne({_id:_id});

        if (typeof testFileObj !== "undefined" && testFileObj !== null) {
          console.log("WARNING: already have "+parts[0]+" with id "+_id+". Skipping.");
          continue
        }

        var origName = parts[2];
        var thisBuf = contents.asNodeBuffer();
        var mtype = MIME.lookup(origName);
        var thisFileObj = new FS.File();
        thisFileObj.attachData(thisBuf,{type:mtype});
        thisFileObj._id = _id;
        thisFileObj.name(origName);
        thisFileObj.updatedAt(contents.date);
        store.insert(thisFileObj);
      }

      // now remove file
      console.log("  removing zip file");
      ZipFileStore.remove({_id:fileObj._id});


    });
  }
});
