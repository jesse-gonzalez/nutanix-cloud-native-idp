## this scripts reaches out to AWS Route 53 and creates the batch of records necessary for deploying OCP Cluster

DNS_NAME='@@{dns_name}@@'
DOMAIN_NAME='@@{domain_name}@@'
DNS_IP_ADRESS='@@{dns_ip_address}@@'

AWS_ACCESS_KEY_ID='@@{AWS Access Key.username}@@'
AWS_SECRET_ACCESS_KEY='@@{AWS Access Key.secret}@@'

import boto3

# create our route53 session using the variables above
client = boto3.client(
    'route53',
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
)

# get hosted zones list and get zone id for target zone
hosted_zones_list = client.list_hosted_zones()
for hosted_zone in hosted_zones_list['HostedZones']:
  if hosted_zone["Name"].strip().rstrip('.') == DOMAIN_NAME:
    hosted_zone_id = hosted_zone["Id"].split("/", 2)[2]

# set resource recrods
response = client.change_resource_record_sets(
    ChangeBatch={
        'Changes': [
            {
                'Action': 'UPSERT',
                'ResourceRecordSet': {
                    'Name': DNS_NAME,
                    'ResourceRecords': [
                        {
                            'Value': DNS_IP_ADRESS,
                        },
                    ],
                    'TTL': 300,
                    'Type': 'A',
                },
            },
        ],
        'Comment': 'Route53 DNS records updated by Calm Runbook',
    },
    HostedZoneId=hosted_zone_id,
)

test_dns_response = client.test_dns_answer(
    HostedZoneId=hosted_zone_id,
    RecordName=DNS_NAME,
    RecordType='A',
)

print('DNS Host Record: {} with IP Address: {} was created successfully'.format(test_dns_response["RecordName"], test_dns_response["RecordData"]))
