# neuron-catalog

A simple web database for keeping track of neurons

This software was developed by the [Straw Lab](http://strawlab.org/)
and is based on [Meteor.js](https://www.meteor.com/). The software
development was supported by [ERC](http://erc.europa.eu/) Starting
Grant 281884 FlyVisualCircuits and by [IMP](http://www.imp.ac.at/)
core funding.

Links:

- documentation: [ReadTheDocs.org](https://neuron-catalog.readthedocs.org/en/latest/)
- project page: [github](https://github.com/strawlab/neuron-catalog)

## Quick install for testing

The neuron catalog can be most easily installed for testing using
[Vagrant](https://www.vagrantup.com/).

1. Install [VirtualBox](https://www.virtualbox.org/)
2. Install [Vagrant](https://www.vagrantup.com/).
3. Download the neuron catalog source code from our [GitHub repository](https://github.com/strawlab/neuron-catalog).
4. Open a terminal window into the `neuron-catalog` directory (containing the `Vagrantfile`).
5. Type `vagrant up`.
6. Wait a few minutes until for the Vagrant machine to come up.
7. Open [http://localhost:3450/](http://localhost:3450/) with your browser to visit your newly installed neuron catalog server.

If you want to enable image uploads, follow the `AWS Setup and
Configuration` section below and edit the Vagrantfile before running
the above steps.

## Install for longer term runs

The neuron catalog software consists of a standard
[Meteor.js](https://www.meteor.com/) server. Instructions for getting
started with Meteor are
[here](http://docs.meteor.com/#/basic/quickstart). Rougly speaking,
configure Amazon AWS for image storage, create a Meteor settings file
and then run Meteor.

```
cp server/server-config.json.example server/server-config.json
# Edit server/server-config.json in a text editor as appropriate.
meteor run --settings server/server-config.json
```

## AWS Setup and Configuration

For image and volume data uploads, neuron-catalog depends on [Amazon
Simple Storage Service](http://aws.amazon.com/s3/) by using [Meteor
Slingshot](https://github.com/CulturalMe/meteor-slingshot). You need
to setup and configure this to run your own instance of
neuron-catalog.

1. Create an AWS user and login to the [AWS Console](https://console.aws.amazon.com/).

2. Create an S3 Bucket.

3. In the bucket permissions, add the following CORS configuration:

```xml
<pre>
    <code>
       <?xml version="1.0" encoding="UTF-8"?>
       <CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
           <CORSRule>
               <AllowedOrigin>*</AllowedOrigin>
               <AllowedMethod>PUT</AllowedMethod>
               <AllowedMethod>POST</AllowedMethod>
               <AllowedMethod>GET</AllowedMethod>
               <AllowedMethod>HEAD</AllowedMethod>
               <MaxAgeSeconds>3000</MaxAgeSeconds>
               <AllowedHeader>*</AllowedHeader>
           </CORSRule>
       </CORSConfiguration>
    </code>
</pre>
```

4. Enable static website hosting for this S3 bucket by selecting
`Enable website hosting` in the AWS Console. Also set "Index Document"
to `index.html`.

5. Set the bucket policy to (substitute the name of your bucket for
`your-bucket-name`):

<pre>
   <code>
   {
   	"Version": "2008-10-17",
   	"Statement": [
   		{
   			"Sid": "AllowPublicRead",
   			"Effect": "Allow",
   			"Principal": {
   				"AWS": "*"
   			},
   			"Action": "s3:GetObject",
   			"Resource": "arn:aws:s3:::your-bucket-name/*"
   		}
   	]
   }
   </code>
</pre>

6. In the Identity & Access Management (IAM) configuration, create a
user and group for performing the uploads. Note the Access Key and the
Secret Key - you will need to enter these.

7. Still in IAM, set the group policy to the following (again,
substitute the name of your bucket for `your-bucket-name`):

<pre>
    <code>
       {
         "Version": "2012-10-17",
         "Statement": [
           {
             "Sid": "Stmt1410709913000",
             "Effect": "Allow",
             "Action": [
               "s3:*"
             ],
             "Resource": [
               "arn:aws:s3:::your-bucket-name"
             ]
           },
           {
             "Sid": "Stmt1410710014000",
             "Effect": "Allow",
             "Action": [
               "s3:*"
             ],
             "Resource": [
               "arn:aws:s3:::your-bucket-name/*"
             ]
           }
         ]
       }
    </code>
</pre>

8. Now, you need to tell neuron-catalog what your IAM Access Key and
Secret Key created above. These go in a JSON file like the prototype
in `server/server-config.json.example`. Change the relevant variables
and save it as something like `server/server-config.json`. You can
also enter these values into the top of the `Vagrantfile` and
re-create your vagrant machine.
