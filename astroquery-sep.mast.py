# Import astroquery.mast (http://astroquery.readthedocs.io/en/latest/mast/mast.html)
# Note, you may need to build from source to access the HST data on AWS.
from astroquery.mast import Observations
import boto3
import json
import os

# Change this to your bucket
output_bucket = ''

# Query MAST for some WFC3 data
obsTable = Observations.query_criteria(obs_collection='HST',
                                       filters='F160W',
                                       instrument_name='WFC3/IR',
                                       dataRights='PUBLIC')

# Grab 100 products: 
# http://astroquery.readthedocs.io/en/latest/mast/mast.html#getting-product-lists
products = Observations.get_product_list(obsTable[:100])

# Filter out just the drizzled FITS files
filtered_products = Observations.filter_products(products,
                                                 mrp_only=False,
                                                 productSubGroupDescription='DRZ')

# Use AWS S3 URLs for the MAST records (rather than the ones at http://mast.stsci.edu)
Observations.enable_cloud_dataset(provider='AWS', profile='default')

# We want URLs like this: s3://stpubdata/hst/public/ibg7/ibg705080/ibg705081_drz.fits
s3_urls = Observations.get_cloud_uris(filtered_products)

# Auth to create a Lambda function 
# (credentials are picked up from .boto file in home directory)
session = boto3.Session()
client = session.client('lambda', region_name='us-east-1')

# Loop through the URLs for the data on S3
# 'your-output-bucket' is where you want to the Lambda outputs to be written
# FunctionName is the name of the Lambda function you made earlier.
for url in s3_urls:
  if url:
    fits_s3_key = url.replace("s3://stpubdata/", "")
    event = {
          'fits_s3_key': fits_s3_key,
          'fits_s3_bucket': 'stpubdata',
          's3_output_bucket': output_bucket # <- change this to your output bucket
          }
    
    # Invoke Lambda function
    response = client.invoke(
            FunctionName='SEPFunction',
            InvocationType='Event',
            LogType='Tail',
            Payload=json.dumps(event)
            )

