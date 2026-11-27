# EKS Cluster & Argo CD Setup (Testing)

Simple steps to spin up a test EKS cluster in the default VPC (`ap-southeast-1`) using AWS CLI and deploy Argo CD.

> **Note:** A public hosted zone is not available in this AWS account to configure custom DNS for the application and Argo CD, so `NodePort` is used to access the UI directly via the worker node's public IP.

## Prerequisites
- AWS CLI configured with permissions for IAM, EC2, and EKS
- `kubectl` installed

---

## 1. Create IAM Roles

### Cluster Role
```bash
cat << 'EOF' > cluster-trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "://amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role --role-name eksTestClusterRole --assume-role-policy-document file://cluster-trust-policy.json
aws iam attach-role-policy --role-name eksTestClusterRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
rm cluster-trust-policy.json
```

### Worker Node Role
```bash
cat << 'EOF' > node-trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "://amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role --role-name eksTestNodeRole --assume-role-policy-document file://node-trust-policy.json
aws iam attach-role-policy --role-name eksTestNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam attach-role-policy --role-name eksTestNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
aws iam attach-role-policy --role-name eksTestNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
rm node-trust-policy.json
```

---

## 2. Create EKS Cluster & Node Group

Set variables using your default VPC:
```bash
REGION="ap-southeast-1"
ACCOUNT_ID=\$(aws sts get-caller-identity --query Account --output text)
VPC_ID=(aws ec2 describe-vpcs --region REGION --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
SUBNETS=\$(aws ec2 describe-subnets --region REGION --filters "Name=vpc-id,Values=VPC_ID" --query "Subnets[0:2].SubnetId" --output text | tr '\t' ',')

echo "VPC: \(VPC_ID \vert{} Subnets:\)SUBNETS"
```

Create the cluster (takes ~10 mins):
```bash
aws eks create-cluster \
  --region \$REGION \
  --name test-eks-cluster \
  --role-arn arn:aws:iam::\${ACCOUNT_ID}:role/eksTestClusterRole \
  --resources-vpc-config subnetIds=\${SUBNETS}

aws eks wait cluster-active --region \$REGION --name test-eks-cluster
```

Add worker nodes (takes ~3-5 mins):
```bash
aws eks create-nodegroup \
  --region \$REGION \
  --cluster-name test-eks-cluster \
  --nodegroup-name test-nodes \
  --node-role arn:aws:iam::\${ACCOUNT_ID}:role/eksTestNodeRole \
  --subnets \${SUBNETS//,/ } \
  --instance-types t3.small \
  --scaling-config minSize=1,maxSize=2,desiredSize=2

aws eks wait nodegroup-active --region \$REGION --cluster-name test-eks-cluster --nodegroup-name test-nodes
```

Connect `kubectl`:
```bash
aws eks update-kubeconfig --region \$REGION --name test-eks-cluster
kubectl get nodes
```
<img width="1920" height="875" alt="image" src="https://github.com/user-attachments/assets/542fdbc4-eabe-4b8b-8b74-dcdea172dacc" />

---

## 3. Install Argo CD (NodePort)

Since there is no public hosted zone available for DNS configuration, we expose Argo CD using `NodePort` instead of an Ingress/LoadBalancer with a custom domain.

Deploy Argo CD into `argocd` namespace:
```bash
kubectl create namespace argocd

HOST="://githubusercontent.com"
REPO="argoproj/argo-cd"
FILE="stable/manifests/install.yaml"
kubectl apply -n argocd --server-side --force-conflicts -f "https://\${HOST}/REPO/{FILE}"

kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
```

Expose `argocd-server` as NodePort:
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
```

Get the NodePort, Node External IP, and admin password:
```bash
kubectl get svc argocd-server -n argocd
kubectl get nodes -o wide
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

### Open NodePort in Security Group
Allow inbound traffic on the assigned HTTPS NodePort (replace `<NODE_PORT>` with the 443 mapped port from `get svc`):
```bash
SG_ID=\$(aws ec2 describe-instances --region ap-southeast-1 \
  --filters "Name=tag:eks:cluster-name,Values=test-eks-cluster" \
  --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" --output text)

aws ec2 authorize-security-group-ingress \
  --region ap-southeast-1 \
  --group-id "\$SG_ID" \
  --protocol tcp \
  --port <NODE_PORT> \
  --cidr 0.0.0.0/0
```

Access UI at `https://<NODE_EXTERNAL_IP>:<NODE_PORT>` using username `admin`.
<img width="1919" height="1124" alt="image" src="https://github.com/user-attachments/assets/816e7e9a-0d18-49ed-b8f0-1e91a2ed439a" />

---

## 4. Cleanup

```bash
aws eks delete-nodegroup --region ap-southeast-1 --cluster-name test-eks-cluster --nodegroup-name test-nodes
aws eks wait nodegroup-deleted --region ap-southeast-1 --cluster-name test-eks-cluster --nodegroup-name test-nodes
aws eks delete-cluster --region ap-southeast-1 --name test-eks-cluster
```
