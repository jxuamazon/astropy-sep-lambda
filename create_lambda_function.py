
import boto3

# Change the following 
output_bucket = ''
exec_role_arn = ''


# Auth to create a Lambda function (credentials are picked up from above .aws/credentials)
session = boto3.Session()

# Make sure Lambda is running in the same region as the HST public dataset
client = session.client('lambda', region_name='us-east-1')



# Use boto to create a Lambda function.
# Role is created here: https://console.aws.amazon.com/iam/home?region=us-east-1#/home
# The Role needs to have the AWSLambdaFullAccess permission policies attached
# 'your-s3-bucket' is the S3 bucket you've uploaded the `venv.zip` file to
response = client.create_function(
    FunctionName='SEPFunction1',
    Runtime='python3.7',
    Role=exec_role_arn, # <- Update this with your IAM role name
    Handler='process.handler',
    Code={
        'S3Bucket': output_bucket, # <- this is the bucket which holds your venv.zip file
        'S3Key': 'venv.zip'
    },
    Description='Testing Lambda with SEP!',
    Timeout=300,
    MemorySize=1024,
    Layers=['arn:aws:lambda:us-east-1:668099181075:layer:AWSLambda-Python37-SciPy1x:115'],
    Publish=True
)
