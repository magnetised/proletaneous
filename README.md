proletaneous
============

Provisioning of Spontaneous CMS systems using Sprinkle


Notes:

(To be expanded at some point...)


Environment variables
---------------------

To avoid having sensitive information in your capistrano configuration Proletaneous will take
configuration values from a `.env.production` file in the root of your site.

This is currently used to configure the WAL-E postgres backups with an S3 ID & key.

You need to add the following keys:

    WALE_AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    WALE_AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxxxxxxx
    WALE_WALE_S3_PREFIX=s3://bucket-name-without-dots/prefix

The `WALE_` prefix is a namespace and the actual env settings drop it.

I've had trouble getting WAL-E to work with anything other than a bucket based in the default region
and for some reason its best to go with a bucket name without any dots.
