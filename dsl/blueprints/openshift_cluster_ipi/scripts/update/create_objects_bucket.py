OBJECTS_ACCESS_KEY = '@@{Objects S3 Access Key.username}@@'
OBJECTS_SECRET_KEY = '@@{Objects S3 Access Key.secret}@@'
OBJECTS_STORE_ENDPOINT = 'https://@@{objects_store_dns_fqdn}@@'

OBJECTS_BUCKET_LIST='@@{objects_buckets_list}@@'.split(',')

import boto3

session = boto3.session.Session()

# create our s3c session using the variables above
s3c = session.client(
    aws_access_key_id=OBJECTS_ACCESS_KEY,
    aws_secret_access_key=OBJECTS_SECRET_KEY,
    endpoint_url=OBJECTS_STORE_ENDPOINT,
    service_name="s3",
    use_ssl=False,
    verify=False,
)

# create list of existing buckets
bucket_list = s3c.list_buckets()
existing_buckets = []

print('Existing buckets:')
for bucket in bucket_list['Buckets']:
    existing_buckets.append(bucket["Name"])

print(existing_buckets)

# Attempt to create each bucket in list if it doesn't already exist

for new_bucket in OBJECTS_BUCKET_LIST:
    if( new_bucket not in existing_buckets ):
        print('Creating New Bucket: ' + new_bucket)
        s3c.create_bucket(Bucket=new_bucket)
