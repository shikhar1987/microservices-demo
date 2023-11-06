# Deployment on EKS (With Fargate)
1. Create a fargate cluster

    >eksctl create cluster --name Shikhar-EKS --region ap-southeast-2 --fargate


2. Install AWS Load Balancer Controller on fargate. More details can be found in [this](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html) article.
    - Check OIDC provider URL for your cluster:
      ```
        aws eks describe-cluster --name Shikhar-EKS --query "cluster.identity.oidc.issuer" --output text

        https://oidc.eks.ap-southeast-2.amazonaws.com/id/A07C9EBEBEE58E76287E8318761F0B9F
      ```
    - Check if you have IAM OIDC provider in your account:
      ```
        aws iam list-open-id-connect-providers | grep A07C9EBEBEE58E76287E8318761F0B9F

        "Arn": "arn:aws:iam::972204093366:oidc-provider/oidc.eks.ap-southeast-2.amazonaws.com/id/A07C9EBEBEE58E76287E8318761F0B9F"
      ```
    - If you don't have OIDC provider, use this command to create one:
      > eksctl utils associate-iam-oidc-provider --cluster Shikhar-EKS --approve
    - Repeat the command in step 2 to check if OIDC now shows up in your account.


3. Create an IAM policy that allows the AWS load balancer controller to make calls to AWS API's. It's a best practice to use IAM roles for service accounts when granting access to AWS APIs.
    - Download the IAM policy:
      > curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/install/iam_policy.json
    - Create an IAM policy using the policy downloaded in the previous step.
      ```
        aws iam create-policy \
      --policy-name AWSLoadBalancerControllerIAMPolicy-Shikhar \
      --policy-document file://iam_policy.json
      ```
    - Copy the ARN of the policy.

4. Create an IAM role. Create a Kubernetes service account named aws-load-balancer-controller in the kube-system namespace for the AWS Load Balancer Controller and annotate the Kubernetes service account with the name of the IAM role.
    ```
        eksctl create iamserviceaccount \
    --cluster=Shikhar-EKS \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=arn:aws:iam::972204093366:policy/AWSLoadBalancerControllerIAMPolicy-Shikhar \
    --approve --override-existing-serviceaccounts
    ```

5. Verify that serviceaccount has been created successfully by running
    > kubectl describe serviceaccount aws-load-balancer-controller -n kube-system
    
    Output should be like this
    ```
      ➜  ~ kubectl describe serviceaccount aws-load-balancer-controller -n kube-system
      Name:                aws-load-balancer-controller
      Namespace:           kube-system
      Labels:              app.kubernetes.io/managed-by=eksctl
      Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::972204093366:role/eksctl-Shikhar-EKS-addon-iamserviceaccount-ku-Role1-HsjHLK5UP6PA
      Image pull secrets:  <none>
      Mountable secrets:   <none>
      Tokens:              <none>
      Events:              <none>
    ```

6. Install the AWS Load Balancer Controller using Helm V3 or later. If you want to deploy the controller on Fargate, use the Helm procedure. The Helm procedure doesn't depend on cert-manager because it generates a self-signed certificate.
    ```
    helm repo add eks https://aws.github.io/eks-charts
    helm repo update eks
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
      -n kube-system \
      --set clusterName=Shikhar-EKS \
      --set serviceAccount.create=false \
      --set serviceAccount.name=aws-load-balancer-controller \
      --set region=ap-southeast-2 \
      --set vpcId=vpc-045702275cffed399
    ```

7. Check if aws-load-balancer-controller is ready or not:
    > kubectl get deployments -A

    > kubectl get pods -A

    > kubectl get svc -A

8. Modify the /release/manifest deployment file by replacing the complete block of frontend-external service with the following:
    ```
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: "frontend-external"
      annotations:
        kubernetes.io/ingress.class: alb
        alb.ingress.kubernetes.io/target-type: ip
        alb.ingress.kubernetes.io/scheme: internet-facing
    spec:
      rules:
        - http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: "frontend"
                    port:
                      number: 80
    ```

9. Deploy the microservices to your cluster:
    > kubectl apply -f deployment.yaml

10. Verify in the AWS UI that your application load balancer was created and it's routing correctly to the frontend pod.

11. Paste that DNS name of your load balancer (or route53 record if you have one) on your browser and make sure you are able to get to hipster shop demo website.

12. Deploy splunk otel collector using helm chart and custom values file (available in this repo) to enable network explorer and forwarding of logs to your existing splunk core environment.
    > helm --namespace=default install --generate-name splunk-otel-collector-chart/splunk-otel-collector -f values.yaml
