# Docker
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

### Currency Service: 

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

### Payment Service:

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

## Create Environment File

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