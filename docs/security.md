## Security

### User roles

neuron-catalog is software designed to be run on your server on the internet or
in a restricted intranet. With its default configuration value of
`DefaultUserRole = "none"`, anyone can create an account, but the account will
not enable them to see or edit data. Only an administrator can add permissions
such as `"read"`, `"write"` or `"admin"`. (The first user is automatically
created with `"admin"` permissions.)

On an intranet, you may wish to set the `DefaultUserRole = `["editor"]` to
enable new users to immediately see and modify data without being approved by an
administrator. See the [configuration](configuration.md) documentation for more
information.
