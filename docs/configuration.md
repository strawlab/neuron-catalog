## Configuration

Configuration variables can be updated at any time by any user with `"admin"`
[permissions](security.md). There is a configuration page available at the URL
ending in `/config` where these options are available.

- `NeuronCatalogSpecialization` Because the neuron-catalog could be used for
  any species, any [specialization](specialization.md) for a particular
  species must be enabled. Currently, `"Drosophila melanogaster"` is the only
  supported specialization. (Optional.)

- `DefaultUserRole` When a user creates an account (without any email
  verification), what role should the user have? For maximum security, set this
  to `"none"`. An administrator can then add appropriate permissions to the user
  (e.g. `"read","write"` or `"read"`). For more convenience, set to
  `["editor"]` so that each new user can read and write the database
  immediately.
