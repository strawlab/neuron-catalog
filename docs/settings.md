## Settings

The neuron-catalog is configured through the standard [Meteor
settings](http://docs.meteor.com/#/full/meteor_settings). When you
start the Meteor server, you must pass these settings. For example:

```bash
meteor run --settings server/server-config.json
```

### Configuration variables

The file server/server-config.json.example is provided as an example
configuration file. It looks like this:

```
{"DefaultUserRoles": ["read","write"]}
```

The fields are:

- `DefaultUserRoles` When a user creates an account (without any email
  verifcation), what roles should the user have? For maximum security,
  set this to an empty list `[]`. An administrator can then add the
  user to the appropriate role (e.g. `"read","write"` or
  `"read"`). For more convenience, set to `["read","write"]` so
  that each new user can read and write the database immediately.
