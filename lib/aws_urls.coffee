getLocation = (href) ->
  # from http://stackoverflow.com/a/21553982/1633026
  match = href.match(/^(https?\:)\/\/(([^:\/?#]*)(?:\:([0-9]+))?)(\/[^?#]*)(\?[^#]*|)(#.*|)$/)
  match and
    protocol: match[1]
    host: match[2]
    hostname: match[3]
    port: match[4]
    pathname: match[5]
    search: match[6]
    hash: match[7]

get_region = ( name ) ->
  if name != 's3' then name.slice(3) else 'us-east-1'

root = exports ? this # make function available in node and browser
root.parse_s3_url = (orig_url) ->
  parser = getLocation(orig_url)

  host_components = parser.hostname.split('.')
  verify_aws_str = host_components.slice(host_components.length-2).join('.')
  if verify_aws_str != 'amazonaws.com'
    throw Error("not an AWS URL: "+orig_url)

  pathname = parser.pathname
  if pathname.charAt(0)=='/'
    pathname = pathname.slice(1)

  if host_components.length < 3
    throw Error("less than 2 dots!? in "+parser.hostname)

  region = get_region( host_components[host_components.length-3] )

  if host_components.length == 3
    # URL in form https://s3[-region].amazonaws.com/bucket-name/key
    first_slash_idx = pathname.indexOf('/')
    bucket = pathname.slice(0,first_slash_idx)
    key = pathname.slice(first_slash_idx+1)
  else
    # URL in form https://[bucket-name].s3[-region].amazonaws.com/key
    bucket_components = host_components.slice(0, host_components.length-3 )
    bucket = bucket_components.join('.')
    key = pathname

  result =
    s3_bucket: bucket
    s3_region: region
    s3_key: key
  result

root.compute_secure_url = (doc) ->
  # URL in form https://s3[-region].amazonaws.com/bucket-name/key
  if doc.s3_region == "us-east-1"
    hostname = "s3.amazonaws.com"
  else
    hostname = "s3-" + doc.s3_region + ".amazonaws.com"
  uri = "https://" + hostname + "/" + doc.s3_bucket + "/" + doc.s3_key
