import { isSandstorm } from './init/sandstorm'
import { DriverLines, BinaryData, NeuronTypes, BrainRegions, ArchiveFileStore, CacheFileStore } from './model'
import { Router, archiver } from './globals-lib'
import { export_data } from './export_data'

Router.configure({
  layoutTemplate: 'ReaderRequiredLayout',
  loadingTemplate: 'Loading',
  notFoundTemplate: 'PageNotFound'
})

Router.setTemplateNameConverter(str => str)

export function make_safe (name) {
  return encodeURIComponent(name)
}

Router.route('/', {
  layoutTemplate: 'MyLayout',
  name: 'home',
  template: 'Home'
})

Router.route('/config',
  {layoutTemplate: 'AdminRequiredLayout'})

if (!isSandstorm()) {
  Router.route('/accounts-admin', {
    name: 'accountsAdmin',
    template: 'accountsAdmin',
    layoutTemplate: 'AdminRequiredLayout'
  })
}

Router.route('/driver_lines')

Router.route('/driver_lines/:_id/:name?', {
  name: 'driver_line_show',
  layoutTemplate: 'ReaderRequiredLayoutWithNamedURL',
  data () {
    return DriverLines.findOne({_id: this.params._id})
  }
})

Router.route('/neuron_types')

Router.route('/neuron_types/:_id/:name?', {
  name: 'neuron_type_show',
  layoutTemplate: 'ReaderRequiredLayoutWithNamedURL',
  data () {
    return NeuronTypes.findOne({_id: this.params._id})
  }
})

Router.route('/brain_regions')

Router.route('/brain_regions/:_id/:name?', {
  name: 'brain_region_show',
  layoutTemplate: 'ReaderRequiredLayoutWithNamedURL',
  data () {
    return BrainRegions.findOne({_id: this.params._id})
  }
})

Router.route('/binary_data')

Router.route('/binary_data/:_id/:name?', {
  name: 'binary_data_show',
  layoutTemplate: 'ReaderRequiredLayoutWithNamedURL',
  data () {
    return BinaryData.findOne({_id: this.params._id})
  }
})

Router.route('/binary_data_zip', {
  // This was inspired by
  // https://github.com/CollectionFS/Meteor-CollectionFS/issues/739#issuecomment-120036374
  // and
  // https://github.com/CollectionFS/Meteor-CollectionFS/issues/475#issuecomment-62682323
  where: 'server',
  action () {
    let fname = this.params.query.filename

    this.response.writeHead(200, {
      'Content-disposition': `attachment; filename=${fname}`,
      'Content-Type': 'application/zip'
    })

    // Create zip
    let zip = archiver('zip')
    // response pipe
    zip.pipe(this.response)
    let raw_json = export_data()
    zip.append(raw_json,
      {name: 'data.json'})
    let iterable = [[ArchiveFileStore, 'archive'], [CacheFileStore, 'cache']]
    for (let i = 0; i < iterable.length; i++) {
      let [store, prefix] = iterable[i]
      store.find({}).forEach(function (file) {
        let readStream = file.createReadStream()
        zip.append(readStream, {
          name: prefix + '/' + file._id + '/' + file.name(),
          date: file.updatedAt()
        })
        return
      })
    }
    zip.finalize()
    return
  }
})

Router.route('/RecentChanges')

Router.route('/Search', function () {
  this.render('Search', {
    data () {
      return this.params
    }
  })
  return
})

export function remove_driver_line (my_id) {
  let rdl = function (doc) {
    let setter = {}
    for (let i in this.fields) {
      let field = this.fields[i]
      let index = doc[field].indexOf(this.my_id)
      if (index !== -1) {
        doc[field].splice(index, 1)
        setter[field] = doc[field]
      }
    }
    this.coll.update(doc._id,
      {$set: setter})

    return
  }
  NeuronTypes.find({driver_lines: my_id}).forEach(rdl, {
    my_id,
    coll: NeuronTypes,
    fields: ['best_driver_lines']
  })

  DriverLines.remove(my_id)
  return
}

export function remove_binary_data (my_id) {
  let rnt = function (doc) {
    let index = doc[this.field_name].indexOf(this.my_id)

    // No need to check for index==-1 because we know it does not (except race condition).
    doc[this.field_name].splice(index, 1)
    let t2 = {}
    t2[this.field_name] = doc[this.field_name]
    this.coll.update(doc._id,
      {$set: t2})

    return
  }
  let field_name = 'images'
  let query = {}
  query[field_name] = my_id
  DriverLines.find(query).forEach(rnt, {
    my_id,
    coll: DriverLines,
    field_name})

  let doc = BinaryData.findOne(my_id)

  return BinaryData.remove(my_id, function (error, num_removed) {
    if (error != null) {
      console.error('Error removing document:', error)
      return
    }
    ArchiveFileStore.remove(doc.archiveId)
    if (doc.cacheId != null) {
      CacheFileStore.remove(doc.cacheId)
    }
    if (doc.thumbId != null) {
      return CacheFileStore.remove(doc.thumbId)
    }
  })
}

export function remove_neuron_type (my_id) {
  let rnt = function (doc) {
    let index = doc.neuron_types.indexOf(this.my_id)

    // No need to check for index==-1 because we know it does not (except race condition).
    doc.neuron_types.splice(index, 1)
    this.coll.update(doc._id, {
      $set: {
        neuron_types: doc.neuron_types
      }
    })

    return
  }
  DriverLines.find({neuron_types: my_id}).forEach(rnt, {
    my_id,
    coll: DriverLines
  })

  NeuronTypes.remove(my_id)
  return
}

export function remove_brain_region (my_id) {
  let rn = function (doc) {
    let index = doc.brain_regions.indexOf(this.my_id)

    // No need to check for index==-1 because we know it does not (except race condition).
    doc.brain_regions.splice(index, 1)
    this.coll.update(doc._id, {
      $set: {
        brain_regions: doc.brain_regions
      }
    })

    return
  }
  DriverLines.find({neuron_types: my_id}).forEach(rn, {
    my_id,
    coll: DriverLines
  })

  NeuronTypes.find({neuron_types: my_id}).forEach(rn, {
    my_id,
    coll: NeuronTypes
  })

  BrainRegions.remove(my_id)
  return
}
