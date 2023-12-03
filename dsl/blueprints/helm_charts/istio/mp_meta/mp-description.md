*Istio*

Istio is an open source service mesh that layers transparently onto existing distributed applications

### Chart Details

This chart will do the following:

- Deploy Istioctl
- Deploy Istio Components - [more info](https://istio.io/latest/docs/setup/getting-started/)
  - Deploy Base Components
  - Deploy Discovery Services
  - Deploy Ingress Gateway
  - Deploy Egress Gateway

#### Prerequisites:

- Existing Karbon Cluster

#### Deploy Example Application

The `Bookinfo` application is broken into four separate microservices:

`productpage`. The `productpage` microservice calls the `details` and `reviews` microservices to populate the page.
`details`. The `details` microservice contains book information.
`reviews`. The `reviews` microservice contains book reviews. It also calls the ratings microservice.
`ratings`. The `ratings` microservice contains book ranking information that accompanies a book review.

There are 3 versions of the reviews microservice:

Version `v1` doesn’t call the ratings service.
Version `v2` calls the ratings service, and displays each rating as 1 to 5 black stars.
Version `v3` calls the ratings service, and displays each rating as 1 to 5 red stars.
