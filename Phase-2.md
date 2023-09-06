# Phase 2: Deploying this on EKS
1. Login to AWS web console and create a EKS cluster

2. Choose a VPC with 4 subnets
    - 2 private subnets (with no route to IGW). Add the tags _kubernetes.io/role/internal-elb_ with value 1 to both of them.
    - 2 public subnets (with route to IGW). Add the tags _kubernetes.io/role/elb_ with value 1 to both of them.

    More details [here](https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html) and [here](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.5/guide/service/nlb/)

3. Create a node group and attach it to your cluster by following [this](https://docs.aws.amazon.com/eks/latest/userguide/create-managed-node-group.html) article.

4. SSH to your node and verify that node has internet connectivity (ping 4.2.2.2).

5. Install AWS Load Balancer Controller on an EC2 node group in EKS. More details can be found in [this](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html) article and [this](https://www.youtube.com/watch?v=TUS8KWaGKco) video.
    - Check OIDC provider URL for your cluster:
      ```
        aws eks describe-cluster --name Shikhar-Demo --query "cluster.identity.oidc.issuer" --output text

        https://oidc.eks.ap-southeast-2.amazonaws.com/id/5C0C2048CC226AE1A1E78A2C89DE529D
      ```
    - Check if you have IAM OIDC provider in your account:
      ```
      aws iam list-open-id-connect-providers | grep 5C0C2048CC226AE1A1E78A2C89DE529D

      "Arn": "arn:aws:iam::972204093366:oidc-provider/oidc.eks.ap-southeast-2.amazonaws.com/id/5C0C2048CC226AE1A1E78A2C89DE529D"
      ```
    - If you don't have OIDC provider, use this command to create one:
      > eksctl utils associate-iam-oidc-provider --cluster Shikhar-Demo --approve
    - Repeat the command in step 2 to check if OIDC now shows up in your account.


6. Create an IAM policy that allows the AWS load balancer controller to make calls to AWS API's. It's a best practice to use IAM roles for service accounts when granting access to AWS APIs.
    - Download the IAM policy:
      > curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/install/iam_policy.json
    - Create an IAM policy using the policy downloaded in the previous step.
      ```
        aws iam create-policy \
      --policy-name AWSLoadBalancerControllerIAMPolicy-Shikhar \
      --policy-document file://iam_policy.json
      ```
    - Copy the ARN of the policy.

7. Create an IAM role. Create a Kubernetes service account named aws-load-balancer-controller in the kube-system namespace for the AWS Load Balancer Controller and annotate the Kubernetes service account with the name of the IAM role.
    ```
        eksctl create iamserviceaccount \
    --cluster=Shikhar-Demo \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=arn:aws:iam::972204093366:policy/AWSLoadBalancerControllerIAMPolicy-Shikhar \
    --approve --override-existing-serviceaccounts
    ```

8. Verify that serviceaccount has been created successfully by running
    > kubectl describe serviceaccount aws-load-balancer-controller -n kube-system
    
    Output should be like this
    ```
      kubectl describe serviceaccount aws-load-balancer-controller -n kube-system

      Name:                aws-load-balancer-controller
      Namespace:           kube-system
      Labels:              app.kubernetes.io/component=controller
                          app.kubernetes.io/name=aws-load-balancer-controller
      Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::972204093366:role/AmazonEKSLoadBalancerControllerRole-Shikhar
      Image pull secrets:  <none>
      Mountable secrets:   <none>
      Tokens:              <none>
      Events:              <none>
    ```

9. Install cert manager to inject the cert configuration into the webhook. Use the latest release if possible.
    > kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.11.4/cert-manager.yaml

10. Download the manifest file for aws load balancer controller. Use the latest if possible:
    > curl -Lo ingress-controller.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.5.4/v2_5_4_full.yaml

11. Modify the manifest:
    - Update cluster name like this:
      > --cluster-name=Shikhar-Demo
    - Add annotation to ServiceAccount:
      ```
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        labels:
          app.kubernetes.io/component: controller
          app.kubernetes.io/name: aws-load-balancer-controller
        annotations:
          eks.amazonaws.com/role-arn: arn:aws:iam::972204093366:role/AmazonEKSLoadBalancerControllerRole-Shikhar
        name: aws-load-balancer-controller
        namespace: kube-system
      ```
    - Save this manifest file.

12. Apply this ingress controller manifest file:
    > kubectl apply -f ingress-controller.yaml

13. Check if aws-load-balancer-controller is ready or not:
    > kubectl get deployments -A

    > kubectl get pods -A

    > kubectl get svc -A

14. Modify the /release/manifest deployment file and add the following annoations:
    ```
          apiVersion: v1
    kind: Service
    metadata:
      name: frontend-external
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
        service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
        service.beta.kubernetes.io/aws-load-balancer-subnets: subnet-15ff0c73,subnet-3989eb61
        service.beta.kubernetes.io/aws-load-balancer-type: nlb
    spec:
      type: LoadBalancer
      selector:
        app: frontend
      ports:
      - name: http
        port: 81
        targetPort: 8080
    ```

15. Deploy the microservices to your cluster:
    > kubectl apply -f deployment.yaml

16. Check if public DNS name is visible for frontend-external service
    > kubectl get svc -A
    
    Output should look something like this:
    ```
    ➜  AKS-Demo kubectl get svc -A
    NAMESPACE      NAME                                       TYPE           CLUSTER-IP       EXTERNAL-IP                                                                          PORT(S)                                                                      AGE
    cert-manager   cert-manager                               ClusterIP      10.100.155.123   <none>                                                                               9402/TCP                                                                     7h13m
    cert-manager   cert-manager-webhook                       ClusterIP      10.100.246.15    <none>                                                                               443/TCP                                                                      7h13m
    default        adservice                                  ClusterIP      10.100.199.9     <none>                                                                               9555/TCP                                                                     5h42m
    default        cartservice                                ClusterIP      10.100.170.70    <none>                                                                               7070/TCP                                                                     5h42m
    default        checkoutservice                            ClusterIP      10.100.154.20    <none>                                                                               5050/TCP                                                                     5h42m
    default        currencyservice                            ClusterIP      10.100.218.31    <none>                                                                               7000/TCP                                                                     5h42m
    default        emailservice                               ClusterIP      10.100.94.124    <none>                                                                               5000/TCP                                                                     5h42m
    default        frontend                                   ClusterIP      10.100.149.46    <none>                                                                               80/TCP                                                                       5h42m
    default        frontend-external                          LoadBalancer   10.100.230.122   a6f247e56ef424ec4a14f4cff77cbce4-417c2e2e113d25a3.elb.ap-southeast-2.amazonaws.com   81:31578/TCP                                                                 5h42m
    default        kubernetes                                 ClusterIP      10.100.0.1       <none>                                                                               443/TCP                                                                      28d
    default        loadgenerator                              LoadBalancer   10.100.115.221   <pending>                                                                            82:30488/TCP                                                                 5h42m
    default        paymentservice                             ClusterIP      10.100.96.17     <none>                                                                               50051/TCP                                                                    5h42m
    default        productcatalogservice                      ClusterIP      10.100.192.232   <none>                                                                               3550/TCP                                                                     5h42m
    default        recommendationservice                      ClusterIP      10.100.154.171   <none>                                                                               8080/TCP                                                                     5h42m
    default        redis-cart                                 ClusterIP      10.100.232.57    <none>                                                                               6379/TCP                                                                     5h42m
    default        shippingservice                            ClusterIP      10.100.162.145   <none>                                                                               50051/TCP                                                                    5h42m
    default        splunk-otel-collector-1689918990           ClusterIP      10.100.57.19     <none>                                                                               6060/TCP,14250/TCP,14268/TCP,4317/TCP,4318/TCP,55681/TCP,9943/TCP,9411/TCP   3h24m
    default        splunk-otel-collector-1689918990-reducer   ClusterIP      10.100.246.255   <none>                                                                               7000/TCP                                                                     3h24m
    kube-system    aws-load-balancer-webhook-service          ClusterIP      10.100.255.17    <none>                                                                               443/TCP                                                                      5h42m
    kube-system    kube-dns                                   ClusterIP      10.100.0.10      <none>                                                                               53/UDP,53/TCP  
    ```

17. Paste that public domain name with port 81 on your browser and make sure you are able to get to hipster shop demo website.

18. Deploy splunk otel collector using helm chart and custom values file (available in this repo) to enable network explorer and forwarding of logs to your existing splunk core environment.
    > helm --namespace=default install --generate-name splunk-otel-collector-chart/splunk-otel-collector -f values.yaml
