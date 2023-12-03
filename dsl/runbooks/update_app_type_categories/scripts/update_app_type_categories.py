user = "@@{Prism Central User.username}@@"
password = "@@{Prism Central User.secret}@@"

def process_request(url, method, user, password, headers, payload=None):
  r = urlreq(url, verb=method, auth="BASIC", user=user, passwd=password, params=payload, verify=False, headers=headers)
  return r

headers = {'Accept': 'application/json', 'Content-Type': 'application/json; charset=UTF-8'}
payload = {"length":500}
base_url = "https://127.0.0.1:9440"

app_type_categories_list='@@{categories_list}@@'.split(',')

print(app_type_categories_list)

for app_type_category in app_type_categories_list:
  url = base_url + "/api/nutanix/v3/categories/AppType/" + app_type_category
  headers = {'Accept': 'application/json', 'Content-Type': 'application/json'}
  url_method = "PUT"
  payload = {"value": app_type_category,"description": ""}
  r = process_request(url, url_method, user, password, headers, json.dumps(payload))
  print "Response Status: " + str(r.status_code)
  print "Response: ", r.json()
