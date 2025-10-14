# 🚀 Sample Application – EKS CI/CD with Jenkins & GitHub Actions

This project demonstrates a complete **CI/CD pipeline** for deploying a sample application to an **Amazon EKS cluster** using both **Jenkins** and **GitHub Actions**.  
It also includes **Snyk container security scanning**, **AWS Load Balancer Controller**, and **Helm-based deployments**.

---

## 🏗️ Infrastructure Setup

The infrastructure was provisioned using **Terraform**, which created:

- **Amazon EKS Cluster** – for deploying containerized workloads.
- **Amazon EC2 Jenkins Server** – for running Jenkins-based CI/CD jobs.
- **Amazon ECR (Elastic Container Registry)** – for storing Docker images.
- **IAM Role for ServiceAccount (IRSA)** – for the AWS Load Balancer Controller.
- **VPC, Subnets, Security Groups** – required for EKS networking.

---
## ⚙️ Terraform Deployment Workflow

Terraform code is available at here: https://github.com/aswarda/terraform/tree/aswarda & branch is `aswarda

### 🔹 Terraform Commands

Below are the commands used to deploy the infrastructure:

- Install necessary softwares like `terraform`, `awscli`, `helm`, `kubect`, `eksctl` ..etc
- Clone the repository `git clone https://github.com/aswarda/sample-app.git`

```bash
# 1. Initialize Terraform
terraform init

# 2. Validate Terraform configuration
terraform validate

# 3. Format Terraform files
terraform fmt

# 4. Preview the resources to be created
terraform plan

# 5. Deploy the infrastructure to AWS
terraform apply -auto-approve

## ⚙️ Application Deployment Workflow
```
### Connect to EKS Cluster
```yaml
aws eks update-kubeconfig --name my-eks-cluster --region eu-central-1
```
### Deploy The App  manully
```yaml
#.Go to folder
cd nginx-app/

#.build the docker image
docker build -t sample-app .

#.login to ecr
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 966127383941.dkr.ecr.eu-central-1.amazonaws.com

#.tag & push the image
docker tag sample-app:latest 966127383941.dkr.ecr.eu-central-1.amazonaws.com/sample-app:latest
docker push 966127383941.dkr.ecr.eu-central-1.amazonaws.com/sample-app:latest
````
### Deploy AWS Load Balancer Controller

The **AWS Load Balancer Controller** was installed via Helm and linked to the IRSA IAM role.

```yaml
helm repo add eks https://aws.github.io/eks-charts
helm repo update

kubectl create namespace kube-system

#. Create IAM policy
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

# attach OIDC
eksctl utils associate-iam-oidc-provider   --region eu-central-1   --cluster my-eks-cluster   --approve

#. Create stack for service account
eksctl create iamserviceaccount   --cluster my-eks-cluster   --namespace kube-system   --name aws-load-balancer-controller   --attach-policy-arn arn:aws:iam::966127383941:policy/AWSLoadBalancerControllerIAMPolicy   --approve

#. Install the aws lb controller
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=eu-central-1
  --set vpcId=vpc-0400b0ec0aa8064e6
```
### Deploy the Sample Application (Helm Chart)

The sample Nginx app is deployed via Helm:

```yaml
helm install my-nginx-app ./nginx-app
```
To redeploy or upgrade:
```yaml
helm upgrade --install my-nginx-app ./nginx-app
```

### CI/CD Workflows

1️⃣ GitHub Actions Workflow

This workflow runs on every push to the main branch.
It builds the Docker image, scans it using Snyk, pushes it to ECR, and deploys it via Helm to EKS.
`.github/workflows/appdeployment.yaml`
```yaml
name: Build and Deploy to Sample App

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    env:
      AWS_REGION: eu-central-1
      ECR_REPO: 966127383941.dkr.ecr.eu-central-1.amazonaws.com/sample-app
      HELM_RELEASE: my-nginx-app
      HELM_CHART_PATH: ./nginx-app
      NAMESPACE: default

    steps:
      # Step 1: Checkout repository
      - name: Checkout repository
        uses: actions/checkout@v4

      # Step 2: Configure AWS credentials
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      # Step 3: Login to Amazon ECR
      - name: Login to Amazon ECR
        uses: aws-actions/amazon-ecr-login@v2

      # Step 4: Build Docker Image
      - name: Build Docker image
        run: docker build -t $ECR_REPO:${{ github.run_number }} .

      # Step 5: Run Snyk Security Scan
      - name: Run Snyk Security Scan
        run: |
          npm install -g snyk
          snyk auth $SNYK_TOKEN
          snyk container test $ECR_REPO:${{ github.run_number }} || true
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

      # Step 6: Push Docker Image
      - name: Push Docker image
        run: docker push $ECR_REPO:${{ github.run_number }}

      # Step 7: Install Helm
      - name: Install Helm
        uses: azure/setup-helm@v4

      # Step 8: Configure kubectl for EKS
      - name: Configure kubectl for EKS
        run: aws eks update-kubeconfig --region $AWS_REGION --name my-eks-cluster

      # Step 9: Deploy with Helm
      - name: Deploy with Helm
        run: |
          helm upgrade --install $HELM_RELEASE $HELM_CHART_PATH \
            --namespace $NAMESPACE \
            --set image.repository=$ECR_REPO \
            --set image.tag=${{ github.run_number }} \
            --create-namespace
```

##. actions URL for CI/CD

https://github.com/aswarda/sample-app/actions/runs/18463476043/job/52599977694

2️⃣ Jenkins Pipeline
A parallel Jenkins pipeline was also created to perform the same CI/CD operations.
> set-up node with basic info for appnode
**Jenkinsfile**

```yaml
pipeline {
    agent { label 'appnode' }

    environment {
        AWS_REGION = 'eu-central-1'
        ECR_REPO = '966127383941.dkr.ecr.eu-central-1.amazonaws.com/sample-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        HELM_RELEASE = 'my-nginx-app'
        HELM_CHART_PATH = './nginx-app'
        NAMESPACE = 'default'
        AWS_CREDENTIALS_ID = 'aws-credentials-id'
    }

    stages {
        stage('Checkout Code') {
            steps {
                sshagent(['git-access']) {
                    sh 'git clone git@github.com:aswarda/sample-app.git .'
                }
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
                    sh '''
                        aws ecr get-login-password --region $AWS_REGION | \
                        docker login --username AWS --password-stdin $ECR_REPO
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $ECR_REPO:$IMAGE_TAG .'
            }
        }

        stage('Push Docker Image') {
            steps {
                sh 'docker push $ECR_REPO:$IMAGE_TAG'
            }
        }

        stage('Deploy/Upgrade Helm Chart') {
            steps {
                sh '''
                    helm upgrade --install $HELM_RELEASE $HELM_CHART_PATH \
                        --namespace $NAMESPACE \
                        --set image.repository=$ECR_REPO \
                        --set image.tag=$IMAGE_TAG \
                        --create-namespace
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful! Image: $ECR_REPO:$IMAGE_TAG"
        }
        failure {
            echo "❌ Deployment failed!"
        }
    }
}
```
### 📊 Optional Monitoring Setup

To enable observability, Prometheus and Grafana were deployed using Helm.
> Here i adjusted the grafana `svc` to nodeport & exposed as a loadbalancer in this case using ingress
```yaml
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
#. Create namespce
kubectl create namespace monitoring

#. Install monitoring stack
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring

#. Copy values to override
helm show values prometheus-community/kube-prometheus-stack > values.yaml

#. edit the grafana svc to NodePort
kubectl edit svc kube-prometheus-stack-grafana -n monitoring

#. Take grafana password for login later
kubectl --namespace monitoring get secrets kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
```
### 🔒 Security

- `Snyk` is integrated into both CI/CD pipelines to scan Docker images for known vulnerabilities.
- The scan runs automatically and reports any high or critical vulnerabilities.

### 📋 Prerequisites

Before running this setup, ensure:
- Terraform v1.5+ is installed
- AWS CLI is configured
- Helm v3+ is installed
- kubectl is installed
- Jenkins node (Ubuntu) has Docker and AWS CLI configured
- GitHub Secrets configured:
    - AWS_ACCESS_KEY_ID
    - AWS_SECRET_ACCESS_KEY
    - SNYK_TOKEN
 
## 🧠 Summary

| Component         | Tool Used                        |
|------------------|---------------------------------|
| Infrastructure    | Terraform                        |
| CI/CD #1          | Jenkins                          |
| CI/CD #2          | GitHub Actions                   |
| Deployment        | Helm                             |
| Container Registry| Amazon ECR                       |
| Cluster           | Amazon EKS                       |
| Monitoring        | Prometheus & Grafana             |
| Security Scanning | Snyk                             |
| Ingress           | AWS Load Balancer Controller     |


## 🌐 Endpoints & Access

| Service / Dashboard | URL / Endpoint                                                                                      | Username | Password       |
|-------------------|----------------------------------------------------------------------------------------------------|---------|----------------|
| Sample App        | [http://k8s-default-nginxing-6bf0f46ca6-1726110413.eu-central-1.elb.amazonaws.com](http://k8s-default-nginxing-6bf0f46ca6-1726110413.eu-central-1.elb.amazonaws.com) | -       | -              |
| Grafana Dashboard | [http://k8s-monitori-grafanai-d5a7266c62-270405332.eu-central-1.elb.amazonaws.com/login](http://k8s-monitori-grafanai-d5a7266c62-270405332.eu-central-1.elb.amazonaws.com/login) | admin   | prom-operator  |
| Jenkins           | skipped here due to time & other works                                                    | -       | -              |

## 🛠 Environment Availability

The deployed environment (EKS cluster, sample app, and Grafana dashboard) will be available until **14th end of the day of this month**. Please ensure all testing and usage is completed before this date.
> If you are checking this assignment after 14th oct 2025, please refer the files -> `sample-app.png`, `grafana-dashboards.png`, `dashboard-2.png`


# 👨‍💻 Author

Aswarda Chari
DevOps Engineer | Cloud Automation | Kubernetes | Terraform | Jenkins | GitHub Actions
📧 aswardavadlamani45@gmail.com
