#!/bin/bash

# Configuration
USER_NAME="ali"
GROUP_NAME="admin"
NAMESPACE="default"

echo "Creating user: $USER_NAME"

# Create directory for user files
mkdir -p ~/minikube-users/$USER_NAME
cd ~/minikube-users/$USER_NAME

# 1. Generate private key
openssl genrsa -out $USER_NAME.key 2048

# 2. Create certificate signing request
openssl req -new -key $USER_NAME.key -out $USER_NAME.csr -subj "/CN=$USER_NAME/O=$GROUP_NAME"

# 3. Get Minikube CA location
MINIKUBE_HOME=~/.minikube

# 4. Sign certificate with Minikube CA
openssl x509 -req -in $USER_NAME.csr \
  -CA $MINIKUBE_HOME/ca.crt \
  -CAkey $MINIKUBE_HOME/ca.key \
  -CAcreateserial \
  -out $USER_NAME.crt \
  -days 365

# 5. Get cluster information
CLUSTER_NAME=$(kubectl config current-context)
CLUSTER_ENDPOINT=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# 6. Add user to kubeconfig
kubectl config set-credentials $USER_NAME \
  --client-certificate=$PWD/$USER_NAME.crt \
  --client-key=$PWD/$USER_NAME.key

# 7. Create context
kubectl config set-context $USER_NAME-context \
  --cluster=$CLUSTER_NAME \
  --user=$USER_NAME \
  --namespace=$NAMESPACE

echo "✅ User '$USER_NAME' created successfully!"
echo "📋 Files created in: $PWD"
echo "🔄 Switch context with: kubectl config use-context $USER_NAME-context"
echo "⚠️  Note: User has no permissions yet. Create RBAC rules next."
