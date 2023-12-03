# Set creds and headers
era_user = '@@{Era User.username}@@'
era_pass = '@@{Era User.secret}@@'
era_ip = '@@{era_vm_ip}@@'

# ========= DO NOT CHANGE AFTER HERE ==========
headers = {'Content-Type': 'application/json', 'Accept': 'application/json'}

# Get Cluster ID
url = "https://{}/era/v0.8/clusters".format(era_ip)

resp = urlreq(url, verb='GET', auth='BASIC', user=era_user, passwd=era_pass, headers=headers)
if resp.ok:
  print("era_cluster_uuid={}".format(json.loads(resp.content)[0]['id']))
else:
  print("Get Cluster ID request failed", json.dumps(json.loads(resp.content), indent=4))
  exit(1)