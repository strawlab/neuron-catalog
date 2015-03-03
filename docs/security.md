## Security

### User roles

neuron-catalog is software designed to be run on your server on the
internet or in a restricted intranet. With its default setting of
`DefaultUserRoles = []` (an empty list), anyone can create an account,
but the account will not enable them to see or edit data. Only an
administrator can add them to a role such as `"read-only"`,
`"read-write"` or `"admin"`. (The first user is automatically created
with an `"admin"` role.)

On and intranet, you may wish to set the `DefaultUserRoles =
["read-write"]` to enable new users to immediately see and modify data
without being approved by an administrator. See the
[settings](settings.md) documentation for more information.

