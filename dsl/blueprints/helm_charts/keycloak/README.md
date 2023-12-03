


## Configure User Federation - LDAP / Active Directory Users

After logging into the Keycloak administrative console with our admin user, head to User Federation and select ldap from the "Add Provider` dropdown.

Set the following:

- Edit Mode: Writable
- Sync Registrations: On
- Vendor: Active Directory
- Connection URL: ldap://10.38.19.139
  - Test Connection
- Users DN: CN=Users,DC=ntnxlab,DC=local
- Search Scope: Subtree
- Bind DN: CN=Administrator,CN=Users,DC=ntnxlab,DC=local
- Bind Credential: <pass>
  - Test Authentication and Save
- Synchronize all users

Once we've entered all of these details, we can use the "Test connection" and "Test authentication" buttons to make sure that everything works. Assuming it does, we can select "Save" to complete the addition of a User Federation provider.

## Configure User Federation - LDAP / Active Directory Group Mappers

go back to the "User Federation" entry on the left menu, choose our ldap entry and select the "Mappers" tab.

We then need to select "Create", enter group as the Name for our federation mapper and select group-ldap-mapper as the "Mapper Type". Then select the following (leaving all else default):

- Name: active-directory-group-mapper
- LDAP Groups DN: CN=Users,DC=ntnxlab,DC=local
- Ignore Missing Groups: ON
- Sync LDAP Groups to Keycloak

https://rancher.com/docs/rancher/v2.6/en/admin-settings/authentication/keycloak-saml/

## Configure New Keycloak SAML Client

- Client ID: https://rancher.10.38.19.146.nip.io/v1-saml/keycloak/saml/metadata
- Client Name: Rancher
- Sign Documents: On
- Sign Assertions: ON
- ALL OTHER: OFF
- Client Protocol: SAML
- Valid Redirect URI: https://rancher.10.38.19.146.nip.io/v1-saml/keycloak/saml/acs

## Configure User / Group Mappers in SAML Client

In the new SAML client, create Mappers to expose the users fields

- Add all “Builtin Protocol Mappers”
- Create a new “Group list” mapper to map the member attribute to a user’s groups
  - Name: Gropus
  - Mapper Type: Group List
  - SAML Attribute NameFormat: Basic

## Configure Role Mappings for LDAP Group

Add default realm role to Domain Users

## Configure Rancher Auth Provider

- Get SAML 2.0 IDP Metadata from Realm Settings, Endpoints Link

- Display Name Field: givenName
- User Name Field: email
- UID Field: email
- Groups Field: member
- Entity ID Field: https://rancher.10.38.19.146.nip.io/v1-saml/keycloak/saml/metadata
- Rancher API Host: https://rancher.10.38.19.146.nip.io

Private Key: kubectl get secrets keycloak.10.38.19.146.nip.io-tls -o jsonpath='{.data.tls\.key}' | base64 -d
Certificate: kubectl get secrets keycloak.10.38.19.146.nip.io-tls -o jsonpath='{.data.tls\.crt}' | base64 -d

login with adminuser01@ntnxlab.local