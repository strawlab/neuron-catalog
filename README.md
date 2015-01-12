# neuron-catalog

A web-based user interface for a neuron catalog database.

This software was developed by the [Straw Lab](http://strawlab.org/)
and is based on [Meteor](http://meteor.com/). The software development
was supported by [ERC](http://erc.europa.eu/) Starting Grant 281884
FlyVisualCircuits and by [IMP](http://www.imp.ac.at/) core
funding. Software development happens on GitHub in the
[strawlab/neuron-catalog](https://github.com/strawlab/neuron-catalog).
project.

## Installation

There are two ways to install neuron_catalog. There is a development
install meant for local development and there is a deployment install
meant for deployment. For initial testing, use the development install
instructions.

### Development installation

Run the following commands in your bash console

    # copy the example server configuration
    cp server/server-config.json.example server/server-config.json

    # edit the server configuration
    <your favorite editor> server/server-config.json

    # In one console, run the Meteor webserver and Mongo database
    meteor run --settings server/server-config.json

### AWS Setup and Configuration

For image and volume data uploads, neuron-catalog depends on [Amazon
Simple Storage Service](http://aws.amazon.com/s3/) by using [Meteor
Slingshot](https://github.com/CulturalMe/meteor-slingshot). You need
to setup and configure this to run your own instance of
neuron-catalog.

1. Create an AWS user and login to the [AWS Console](https://console.aws.amazon.com/).

2. Create an S3 Bucket. Keep in mind the following points:

   a) Use the `US Standard` region for the bucket. Otherwise, Meteor
      Slingshot has trouble uploading.

   b) The bucket name must not have dots (no `.`). Otherwise, secure
      uploads will fail due to the HTTPS certificate wildcards only
      supporting a single level subdomain.

3. In the bucket permissions, add the following CORS configuration:

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

4. Enable static website hosting for this S3 bucket by selecting
`Enable website hosting` in the AWS Console. Also set "Index Document"
to `index.html`.

5. Set the bucket policy to (substitute the name of your bucket for
`your-bucket-name`):

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

6. In the Identity & Access Management (IAM) configuration, create a
user and group for performing the uploads. Note the Access Key and the
Secret Key - you will need to enter these.

7. Still in IAM, set the group policy to the following (again,
substitute the name of your bucket for `your-bucket-name`):

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
