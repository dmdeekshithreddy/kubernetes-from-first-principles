#!/usr/bin/env bash
# Kubernetes Basic Commands — from first principles
# Run these one at a time to understand what each does.

# ─────────────────────────────────────────────────
# 1. CLUSTER INFO
# ─────────────────────────────────────────────────

# Check that kubectl can reach the cluster and show server version
kubectl version

# Show the cluster API server address and cluster services
kubectl cluster-info

# List all nodes in the cluster (the machines that run your workloads)
kubectl get nodes

# Same, but with extra details: OS, kernel, container runtime, roles
kubectl get nodes -o wide

# ─────────────────────────────────────────────────
# 2. NAMESPACES
# Namespaces are virtual clusters inside a real cluster.
# They let you isolate workloads (e.g. dev vs prod).
# ─────────────────────────────────────────────────

# List all namespaces
kubectl get namespaces

# Create a new namespace called "demo"
kubectl create namespace demo

# Delete the namespace (also deletes everything inside it)
kubectl delete namespace demo

# ─────────────────────────────────────────────────
# 3. PODS
# A Pod is the smallest deployable unit in Kubernetes.
# It wraps one or more containers that share network & storage.
# ─────────────────────────────────────────────────

# List all pods in the current (default) namespace
kubectl get pods

# List pods in a specific namespace
kubectl get pods -n kube-system

# List pods across ALL namespaces
kubectl get pods --all-namespaces

# Same as above, shorthand flag
kubectl get pods -A

# Show extra columns: which node each pod runs on, its IP, etc.
kubectl get pods -o wide

# Run a one-off pod (like "docker run") — useful for quick tests
# This starts an nginx pod named "my-nginx"
kubectl run my-nginx --image=nginx

# Watch pods in real time (updates every 2 s, Ctrl-C to stop)
kubectl get pods -w

# Show full details about a pod: events, volumes, IP, conditions
kubectl describe pod my-nginx

# Stream live logs from a pod
kubectl logs my-nginx

# Stream logs and keep following (like "tail -f")
kubectl logs -f my-nginx

# Open an interactive shell inside a running pod
kubectl exec -it my-nginx -- /bin/bash

# Delete a pod by name
kubectl delete pod my-nginx

# ─────────────────────────────────────────────────
# 4. DEPLOYMENTS
# A Deployment manages a set of identical pods and keeps them
# running, handles rolling updates, and enables rollbacks.
# ─────────────────────────────────────────────────

# Create a deployment: 3 replicas of nginx
kubectl create deployment my-deploy --image=nginx --replicas=3

# List all deployments
kubectl get deployments

# Show full details of the deployment
kubectl describe deployment my-deploy

# Scale the deployment up or down (change replica count)
kubectl scale deployment my-deploy --replicas=5

# Update the container image (triggers a rolling update)
kubectl set image deployment/my-deploy nginx=nginx:1.25

# Check the rolling-update status
kubectl rollout status deployment/my-deploy

# View rollout history (lists previous revisions)
kubectl rollout history deployment/my-deploy

# Roll back to the previous revision if something went wrong
kubectl rollout undo deployment/my-deploy

# Delete the deployment (also deletes the pods it manages)
kubectl delete deployment my-deploy

# ─────────────────────────────────────────────────
# 5. SERVICES
# A Service gives pods a stable network endpoint.
# Pods come and go; a Service's IP/DNS name stays constant.
# ─────────────────────────────────────────────────

# Expose a deployment as a ClusterIP service (internal only)
kubectl expose deployment my-deploy --port=80

# Expose as a NodePort service (accessible from outside the cluster
# via <NodeIP>:<NodePort>)
kubectl expose deployment my-deploy --port=80 --type=NodePort

# List all services
kubectl get services

# Shorthand: "svc" works as an alias for "services"
kubectl get svc

# Show full details of a service
kubectl describe svc my-deploy

# Delete a service
kubectl delete svc my-deploy

# ─────────────────────────────────────────────────
# 6. CONFIG MAPS & SECRETS
# ConfigMaps store non-sensitive config as key-value pairs.
# Secrets store sensitive data (passwords, tokens) base64-encoded.
# ─────────────────────────────────────────────────

# Create a ConfigMap from literal values
kubectl create configmap my-config --from-literal=APP_ENV=production --from-literal=LOG_LEVEL=info

# List ConfigMaps
kubectl get configmaps

# View the data inside a ConfigMap
kubectl describe configmap my-config

# Create a Secret from literal values (stored base64-encoded)
kubectl create secret generic my-secret --from-literal=DB_PASSWORD=s3cr3t

# List Secrets
kubectl get secrets

# ─────────────────────────────────────────────────
# 7. APPLY YAML FILES
# The preferred way to work with Kubernetes is declarative:
# describe what you want in a YAML file, then apply it.
# ─────────────────────────────────────────────────

# Apply (create or update) any resource from a YAML file
kubectl apply -f deployment.yaml

# Apply everything in a directory
kubectl apply -f ./manifests/

# Preview what would change WITHOUT actually applying (dry run)
kubectl apply -f deployment.yaml --dry-run=client

# Delete resources defined in a file
kubectl delete -f deployment.yaml

# ─────────────────────────────────────────────────
# 8. CONTEXT & KUBECONFIG
# A context binds a cluster + user + namespace together.
# Switching context = switching which cluster you talk to.
# ─────────────────────────────────────────────────

# List all available contexts (clusters you can talk to)
kubectl config get-contexts

# Show the currently active context
kubectl config current-context

# Switch to a different context
kubectl config use-context my-other-cluster

# Set a default namespace so you don't have to type -n every time
kubectl config set-context --current --namespace=demo

# ─────────────────────────────────────────────────
# 9. HANDY SHORTCUTS
# ─────────────────────────────────────────────────

# Short resource aliases that save typing
kubectl get po          # pods
kubectl get deploy      # deployments
kubectl get svc         # services
kubectl get ns          # namespaces
kubectl get cm          # configmaps

# Output as YAML — great for inspecting the full resource spec
kubectl get pod my-nginx -o yaml

# Output as JSON
kubectl get pod my-nginx -o json

# Label a node (useful for scheduling decisions)
kubectl label node <node-name> disktype=ssd

# Add a label to a pod
kubectl label pod my-nginx env=test

# List pods that match a label selector
kubectl get pods -l env=test
