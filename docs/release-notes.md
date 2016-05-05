# Release notes

A list of changes with each release. Downloads are
[here](https://github.com/strawlab/neuron-catalog/releases).

---

## v0.6.1

##### Features and Improvements

- Improve the description for the Sandstorm market.

## v0.6.0

##### Features and Improvements

- Require the use of [Sandstorm](https://sandstorm.io) to host the project. See
  [the neuron-catalog
  app](https://apps.sandstorm.io/app/u1pa4174jqhvn93fkgr6u07mfgpk53dtgvfqqz9hec0pxk6c8nuh)
  in the Sandstorm app store.

- A cool logo from Nena Nguyen (sandstorm.io). Thanks!

- Use Meteor 1.3, drop the use of coffeescript, and convert as much as possible
  into ES6 javascript.

- Do not require use of Amazon S3 to store files. Instead, save them into
  the local mongodb database instance.

- Specializations (e.g. "Drosophila melanogaster") and default user role (e.g.
  "editor" or "none") are now set directly through the web interface by an
  administrator. Previously, this was set via Meteor settings during server
  startup.

- The default user role is now set directly through the web interface by an
  administrator. Previously, this was set via Meteor settings during server
  startup.

##### Upgrading

  - Neuron-catalog preserves data in-place during an upgrade and automatically
    updates the schema if required. To import data from an old installation into
    a new installation, download your data from the old installation and upload
    it into the new installation. The data should be automatically migrated.

---

## v0.5.7 (2015-09-16)

##### Features and Improvements

- Each tag button now links to a search for that tag
- Do not download font into browser

##### Bugfixes

- Fix broken dialogs (JSON data download/upload and binary data upload)
  introduced in a regression with v0.5.6.

---

## v0.5.6 (2015-07-22)

##### Features and Improvements

- Update to Meteor 1.1.0.2 and Bootstrap 3.3.5
- Improve UI once a user logs in

---

## v0.5.5 (2015-04-14)

##### Features and Improvements

- Support files to use WebStorm IDE for development
- Amira file parser moved to https://github.com/strawlab/py_amira_file_reader

##### Bugfixes

- Fix broken links when a slash is in the item name.

---

## v0.5.4 (2015-03-07)

##### Security

- No emails or hashed passwords in JSON download.

##### Features and Improvements

- Support for Drosophila Anatomy Ontology

##### Bugfixes

- Remove redundant text when editing brain regions.

---

## v0.5.3 (2015-03-07)

##### Bugfixes

- Show tags from all collections when searching.
- Unicode characters do not break JSON download.
- Fix showing meaningless expression type in brain region table

---

## v0.5.2 (2015-03-06)

##### Features and Improvements

- Enable uploading JSON encoded data, simplify JSON schema.

##### Bugfixes

- If a TIFF file cannot be parsed, show an error dialog.

---

## v0.5.1 (2015-03-03)

##### Security

- Perform version check over HTTPS.

---

## v0.5.0 (2015-03-03)

- Initial release
