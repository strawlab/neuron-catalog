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

      // This is a hack. We should ask CollectionFS where the file is.
      var hack_fullpath = process.env.PWD+"/.meteor/local/cfs/files/zip_files/zip_filestore-"+fileObj._id+"-"+fileObj.name();
      var buf = fs.readFileSync(hack_fullpath);
      var zip = new JSZip();

      // Ideally, we would just directly get the data from the FS.File object
      //var buf = fileObj.data;
      //  but the above line does not work.

      zip.load(buf);
      for (var filename in zip.files) {
        var contents = zip.files[filename];
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
      ZipFileStore.remove({_id:fileObj._id});
    });
  }
});
