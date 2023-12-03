## this scripts reaches out to AWS Route 53 and creates the batch of records necessary for deploying OCP Cluster

OCP_CLUSTER_NAME='@@{ocp_cluster_name}@@'
OCP_BASE_DOMAIN='@@{ocp_base_domain}@@'
OCP_API_VIP='@@{api_ipv4_vip}@@'
OCP_APPS_INGRESS_VIP='@@{wildcard_ingress_ipv4_vip}@@'

AWS_ACCESS_KEY_ID='@@{AWS Access Key.username}@@'
AWS_SECRET_ACCESS_KEY='@@{AWS Access Key.secret}@@'

OCP_SUBDOMAIN=OCP_CLUSTER_NAME + "." + OCP_BASE_DOMAIN
OCP_NTNX_PC_DNS_SHORT="prism-central." + OCP_SUBDOMAIN

OCP_API_DNS_SHORT="api." + OCP_SUBDOMAIN
OCP_APPS_INGRESS_DNS_SHORT="*.apps." + OCP_SUBDOMAIN

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
  if hosted_zone["Name"].strip().rstrip('.') == OCP_BASE_DOMAIN:
    hosted_zone_id = hosted_zone["Id"].split("/", 2)[2]

# set resource recrods
response = client.change_resource_record_sets(
    ChangeBatch={
        'Changes': [
            {
                'Action': 'UPSERT',
                'ResourceRecordSet': {
                    'Name': OCP_API_DNS_SHORT,
                    'ResourceRecords': [
                        {
                            'Value': OCP_API_VIP,
                        },
                    ],
                    'TTL': 300,
                    'Type': 'A',
                },
            },
            {
                'Action': 'UPSERT',
                'ResourceRecordSet': {
                    'Name': OCP_APPS_INGRESS_DNS_SHORT,
                    'ResourceRecords': [
                        {
                            'Value': OCP_APPS_INGRESS_VIP,
                        },
                    ],
                    'TTL': 300,
                    'Type': 'A',
                },
            },
        ],
        'Comment': 'Openshift DNS records needed for OCP Cluster Deploy',
    },
    HostedZoneId=hosted_zone_id,
)

test_apps_dns_response = client.test_dns_answer(
    HostedZoneId=hosted_zone_id,
    RecordName=OCP_APPS_INGRESS_DNS_SHORT,
    RecordType='A',
)

print('DNS Host Record: {} with IP Address: {} was created successfully'.format(test_apps_dns_response["RecordName"], test_apps_dns_response["RecordData"]))

test_api_dns_response = client.test_dns_answer(
    HostedZoneId=hosted_zone_id,
    RecordName=OCP_API_DNS_SHORT,
    RecordType='A',
)

print('DNS Host Record: {} with IP Address: {} was created successfully'.format(test_api_dns_response["RecordName"], test_api_dns_response["RecordData"]))
