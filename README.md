<p align="center">
<img src="/src/frontend/static/icons/Hipster_HeroLogoMaroon.svg" width="300" alt="Online Boutique" />
</p>

![Continuous Integration](https://github.com/GoogleCloudPlatform/microservices-demo/workflows/Continuous%20Integration%20-%20Main/Release/badge.svg)

**Online Boutique** is a cloud-first microservices demo application.
Online Boutique consists of an 11-tier microservices application. The application is a
web-based e-commerce app where users can browse items,
add them to the cart, and purchase them.

Google uses this application to demonstrate the use of technologies like
Kubernetes, GKE, Istio, Stackdriver, and gRPC. This application
works on any Kubernetes cluster, like Google
Kubernetes Engine (GKE). It’s **easy to deploy with little to no configuration**.

If you’re using this demo, please **★Star** this repository to show your interest!

\*\*We'll be using this to demonstrate capabilities of Splunk Observability Cloud offerings. We'll be doing it in phases:

**Phase 1 (Docker)**
Modify the configuration a bit on 2 microservices (paymentservice and currencyservice) so that it can run on docker environment

Create Docker images for all the microservices

Run docker images locally on your machine

Install either a Docker Desktop on your mac or windows or Docker binary in your choice of linux. Run the following command to ensure docker daemon is running
```sh
docker ps
```
The output should be blank.

Clone this repository.
```sh
gh repo clone shikhar1987/microservices-demo
cd microservices-demo
cd src
```

Modify 2 microservices so that they can run on Docker

**Currency Service:** 

Modify the server.js file to add port 7000

```sh
cd <PATH>/microservice-demo/src/currencyservice
vi server.js
```

On line 64, replace

const PORT = process.env.PORT;

with

const PORT = 7000;

Save and exit

**Payment Service:** 

Modify the server.js file to add port 50051

```sh
cd <PATH>/microservice-demo/src/paymentservice
vi server.js
```

On line 68, replace

const port = this.port

with

const PORT = 50051;

Save and exit


## Create Docker Images

Make sure you are in /microservice-demo/src folder
```sh
cd adservice
docker build -t adservice .
cd ../cartservice/src
docker build -t cartservice .
cd ../../checkoutservice
docker build -t checkoutservice .
cd ../currencyservice
docker build -t currencyservice .
cd ../emailservice
docker build -t emailservice .
cd ../frontend
docker build -t frontend .
cd ../paymentservice
docker build -t paymentservice .
cd ../productcatalogservice
docker build -t productcatalogservice .
cd ../recommendationservice
docker build -t recommendationservice .
cd ../shippingservice
docker build -t shippingservice .
```

Run the following command to ensure images are ready. 

```
docker images
```

Create Environment File
Create a file env.txt with the following values and place it somewhere on your local machine, eg: Desktop.
```
PRODUCT_CATALOG_SERVICE_ADDR=productcatalogservice:3550
CURRENCY_SERVICE_ADDR=currencyservice:7000
CART_SERVICE_ADDR=cartservice:7070
RECOMMENDATION_SERVICE_ADDR=recommendationservice:8070
SHIPPING_SERVICE_ADDR=shippingservice:50051
CHECKOUT_SERVICE_ADDR=checkoutservice:5050
AD_SERVICE_ADDR=adservice:9555
EMAIL_SERVICE_ADDR=emailservice:8090
PAYMENT_SERVICE_ADDR=paymentservice:50057
PROJECT_ID=Shikhar-Demo
DISABLE_PROFILER=1
DISABLE_TRACING=1
DISABLE_STATS=1
```

Create a user-defined bridge network We need the microservices to be able to communicate to each other using names. Default bridge network in Docker doesn't allow you to do that. So we'll create a new network and add all our containers in it. Refer to this link for more info: https://docs.docker.com/network/network-tutorial-standalone/
(Name it anything)
```sh
docker network create shikhar
```
## Run the Containers 

Note: We'll only be exposing frontend service on 8080 and nothing else. Rest of the communication will happen via names using user defined bridge network.
```sh
docker run --env-file ~/Desktop/env.txt -dit --network shikhar --name currencyservice currencyservice
docker run --env-file ~/Desktop/env.txt -dit --network shikhar --name paymentservice paymentservice
docker run --env-file ~/Desktop/env.txt -dit --network shikhar --name emailservice emailservice
docker run --env-file ~/Desktop/env.txt -dit --network shikhar --name adservice adservice
docker run --env-file ~/Desktop/env.txt -dit --network shikhar --name checkoutservice checkoutservice
docker run --env-file ~/Desktop/env.txt -dit --network shikhar --name shippingservice shippingservice
docker run --env-file ~/Desktop/env.txt -dit --network shikhar --name recommendationservice recommendationservice
docker run --env-file ~/Desktop/env.txt -dit --network shikhar --name cartservice cartservice
docker run --env-file ~/Desktop/env.txt -dit --network shikhar --name productcatalogservice productcatalogservice
docker run --env-file ~/Desktop/env.txt -dit --network shikhar --name frontend -p 8080:8080 frontend
```

Verify that all containers are up and running and no one is in exit state

```sh
docker ps
```

Note- Following commands maybe helpful in troubleshooting if needed:

SSH into a container:
```sh
docker exec -it stupefied_cray /bin/sh
```

Kill all exited containers:
```
sudo docker ps -a | grep Exited | cut -d ' ' -f 1 | xargs sudo docker rm
```
Kill all containers:
```
docker kill $(docker ps -q)
```
Identify used ports on your mac:
```
sudo lsof -i -n -P | grep TCP
```
Verify if Online Boutique is working or not: Go to your browser and open http://127.0.0.1:8080

Happy Dockering :)



## Screenshots

| Home Page                                                                                                             | Checkout Screen                                                                                                        |
| --------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| [![Screenshot of store homepage](/docs/img/online-boutique-frontend-1.png)](/docs/img/online-boutique-frontend-1.png) | [![Screenshot of checkout screen](/docs/img/online-boutique-frontend-2.png)](/docs/img/online-boutique-frontend-2.png) |

## Interactive quickstart (GKE)

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2FGoogleCloudPlatform%2Fmicroservices-demo&shellonly=true&cloudshell_image=gcr.io/ds-artifacts-cloudshell/deploystack_custom_image)

## Quickstart (GKE)

1. Ensure you have the following requirements:

   - [Google Cloud project](https://cloud.google.com/resource-manager/docs/creating-managing-projects#creating_a_project).
   - Shell environment with `gcloud`, `git`, and `kubectl`.

2. Clone the repository.

   ```sh
   git clone https://github.com/GoogleCloudPlatform/microservices-demo
   cd microservices-demo/
   ```

3. Set the Google Cloud project and region and ensure the Google Kubernetes Engine API is enabled.

   ```sh
   export PROJECT_ID=<PROJECT_ID>
   export REGION=us-central1
   gcloud services enable container.googleapis.com \
     --project=${PROJECT_ID}
   ```

   Substitute `<PROJECT_ID>` with the ID of your Google Cloud project.

4. Create a GKE cluster and get the credentials for it.

   ```sh
   gcloud container clusters create-auto online-boutique \
     --project=${PROJECT_ID} --region=${REGION}
   ```

   Creating the cluster may take a few minutes.

5. Deploy Online Boutique to the cluster.

   ```sh
   kubectl apply -f ./release/kubernetes-manifests.yaml
   ```

6. Wait for the pods to be ready.

   ```sh
   kubectl get pods
   ```

   After a few minutes, you should see the Pods in a `Running` state:

   ```
   NAME                                     READY   STATUS    RESTARTS   AGE
   adservice-76bdd69666-ckc5j               1/1     Running   0          2m58s
   cartservice-66d497c6b7-dp5jr             1/1     Running   0          2m59s
   checkoutservice-666c784bd6-4jd22         1/1     Running   0          3m1s
   currencyservice-5d5d496984-4jmd7         1/1     Running   0          2m59s
   emailservice-667457d9d6-75jcq            1/1     Running   0          3m2s
   frontend-6b8d69b9fb-wjqdg                1/1     Running   0          3m1s
   loadgenerator-665b5cd444-gwqdq           1/1     Running   0          3m
   paymentservice-68596d6dd6-bf6bv          1/1     Running   0          3m
   productcatalogservice-557d474574-888kr   1/1     Running   0          3m
   recommendationservice-69c56b74d4-7z8r5   1/1     Running   0          3m1s
   redis-cart-5f59546cdd-5jnqf              1/1     Running   0          2m58s
   shippingservice-6ccc89f8fd-v686r         1/1     Running   0          2m58s
   ```

7. Access the web frontend in a browser using the frontend's external IP.

   ```sh
   kubectl get service frontend-external | awk '{print $4}'
   ```

   Visit `http://EXTERNAL_IP` in a web browser to access your instance of Online Boutique.

8. Once you are done with it, delete the GKE cluster.

   ```sh
   gcloud container clusters delete online-boutique \
     --project=${PROJECT_ID} --region=${REGION}
   ```

   Deleting the cluster may take a few minutes.

## Use Terraform to provision a GKE cluster and deploy Online Boutique

The [`/terraform` folder](/terraform) contains instructions for using [Terraform](https://www.terraform.io/intro) to replicate the steps from [**Quickstart (GKE)**](#quickstart-gke) above.

## Other deployment variations

- **Istio/Anthos Service Mesh**: [See these instructions.](/kustomize/components/service-mesh-istio/README.md)
- **non-GKE clusters (Minikube, Kind)**: see the [Development Guide](/docs/development-guide.md)

## Deploy Online Boutique variations with Kustomize

The [`/kustomize` folder](/kustomize) contains instructions for customizing the deployment of Online Boutique with different variations such as:

- integrating with [Google Cloud Operations](/kustomize/components/google-cloud-operations/)
- replacing the in-cluster Redis cache with [Google Cloud Memorystore (Redis)](/kustomize/components/memorystore), [AlloyDB](/kustomize/components/alloydb) or [Google Cloud Spanner](/kustomize/components/spanner)
- etc.

## Architecture

**Online Boutique** is composed of 11 microservices written in different
languages that talk to each other over gRPC.

[![Architecture of
microservices](/docs/img/architecture-diagram.png)](/docs/img/architecture-diagram.png)

Find **Protocol Buffers Descriptions** at the [`./protos` directory](/protos).

| Service                                             | Language      | Description                                                                                                                       |
| --------------------------------------------------- | ------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| [frontend](/src/frontend)                           | Go            | Exposes an HTTP server to serve the website. Does not require signup/login and generates session IDs for all users automatically. |
| [cartservice](/src/cartservice)                     | C#            | Stores the items in the user's shopping cart in Redis and retrieves it.                                                           |
| [productcatalogservice](/src/productcatalogservice) | Go            | Provides the list of products from a JSON file and ability to search products and get individual products.                        |
| [currencyservice](/src/currencyservice)             | Node.js       | Converts one money amount to another currency. Uses real values fetched from European Central Bank. It's the highest QPS service. |
| [paymentservice](/src/paymentservice)               | Node.js       | Charges the given credit card info (mock) with the given amount and returns a transaction ID.                                     |
| [shippingservice](/src/shippingservice)             | Go            | Gives shipping cost estimates based on the shopping cart. Ships items to the given address (mock)                                 |
| [emailservice](/src/emailservice)                   | Python        | Sends users an order confirmation email (mock).                                                                                   |
| [checkoutservice](/src/checkoutservice)             | Go            | Retrieves user cart, prepares order and orchestrates the payment, shipping and the email notification.                            |
| [recommendationservice](/src/recommendationservice) | Python        | Recommends other products based on what's given in the cart.                                                                      |
| [adservice](/src/adservice)                         | Java          | Provides text ads based on given context words.                                                                                   |
| [loadgenerator](/src/loadgenerator)                 | Python/Locust | Continuously sends requests imitating realistic user shopping flows to the frontend.                                              |

## Features

- **[Kubernetes](https://kubernetes.io)/[GKE](https://cloud.google.com/kubernetes-engine/):**
  The app is designed to run on Kubernetes (both locally on "Docker for
  Desktop", as well as on the cloud with GKE).
- **[gRPC](https://grpc.io):** Microservices use a high volume of gRPC calls to
  communicate to each other.
- **[Istio](https://istio.io):** Application works on Istio service mesh.
- **[Cloud Operations (Stackdriver)](https://cloud.google.com/products/operations):** Many services
  are instrumented with **Profiling** and **Tracing**. In
  addition to these, using Istio enables features like Request/Response
  **Metrics** and **Context Graph** out of the box. When it is running out of
  Google Cloud, this code path remains inactive.
- **[Skaffold](https://skaffold.dev):** Application
  is deployed to Kubernetes with a single command using Skaffold.
- **Synthetic Load Generation:** The application demo comes with a background
  job that creates realistic usage patterns on the website using
  [Locust](https://locust.io/) load generator.

## Development

See the [Development guide](/docs/development-guide.md) to learn how to run and develop this app locally.

## Demos featuring Online Boutique

- [Use Helm to simplify the deployment of Online Boutique, with a Service Mesh, GitOps, and more!](https://medium.com/p/246119e46d53)
- [How to reduce microservices complexity with Apigee and Anthos Service Mesh](https://cloud.google.com/blog/products/application-modernization/api-management-and-service-mesh-go-together)
- [gRPC health probes with Kubernetes 1.24+](https://medium.com/p/b5bd26253a4c)
- [Use Google Cloud Spanner with the Online Boutique sample](https://medium.com/p/f7248e077339)
- [Seamlessly encrypt traffic from any apps in your Mesh to Memorystore (redis)](https://medium.com/google-cloud/64b71969318d)
- [Strengthen your app's security with Anthos Service Mesh and Anthos Config Management](https://cloud.google.com/service-mesh/docs/strengthen-app-security)
- [From edge to mesh: Exposing service mesh applications through GKE Ingress](https://cloud.google.com/architecture/exposing-service-mesh-apps-through-gke-ingress)
- [Take the first step toward SRE with Cloud Operations Sandbox](https://cloud.google.com/blog/products/operations/on-the-road-to-sre-with-cloud-operations-sandbox)
- [Deploying the Online Boutique sample application on Anthos Service Mesh](https://cloud.google.com/service-mesh/docs/onlineboutique-install-kpt)
- [Anthos Service Mesh Workshop: Lab Guide](https://codelabs.developers.google.com/codelabs/anthos-service-mesh-workshop)
- [KubeCon EU 2019 - Reinventing Networking: A Deep Dive into Istio's Multicluster Gateways - Steve Dake, Independent](https://youtu.be/-t2BfT59zJA?t=982)
- Google Cloud Next'18 SF
  - [Day 1 Keynote](https://youtu.be/vJ9OaAqfxo4?t=2416) showing GKE On-Prem
  - [Day 3 Keynote](https://youtu.be/JQPOPV_VH5w?t=815) showing Stackdriver
    APM (Tracing, Code Search, Profiler, Google Cloud Build)
  - [Introduction to Service Management with Istio](https://www.youtube.com/watch?v=wCJrdKdD6UM&feature=youtu.be&t=586)
- [Google Cloud Next'18 London – Keynote](https://youtu.be/nIq2pkNcfEI?t=3071)
  showing Stackdriver Incident Response Management

---

This is not an official Google project.
