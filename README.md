# Terraform AWS EKS Kubernetes Node & Pod Metrics Module

A simple module for implementing cluster & pod metric collection (CPU %, Mem. Usage, etc.).

## How it works

Kubernetes on AWS, known as EKS, allows kubernetes workloads to run on kubernetes natively in the cloud without users having to manage the control plane.
AWS Abstracts the control plane, so you only worry about your data plane specifics. Users can use the [Terraform EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) to quickly
stand up an EKS cluster for running workloads on.

This module simplifies metric collection on EKS. [This link](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-metrics.html) describes how to manually deploy the solution, but this
module makes it simpler to easily add this solution into your existing Terraform code for your EKS deployments. 

It contains the following Kubernetes Resources:

- Namespace
- Service Account
- Cluster Role
- Cluster Role Binding
- ConfigMap 
- Daemonset

Once deployed, run the following to ensure your daemonset pods are running:

> kubectl get pods -n amazon-cloudwatch

