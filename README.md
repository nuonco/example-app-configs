# Example App Configurations for Nuon

[App Configs](https://docs.nuon.co/concepts/apps) are versions of a software provider's application that can be deployed on a customer's infrastructure with Nuon. Nuon provides a set of example app configurations "App Configs" that can be used as a starting point for configuring and deploying applications using Nuon.

# Example Apps

## aws-lambda

Creates an AWS Lambda function based on a Go app image built from a Dockerfile. The app config also includes a DynamoDB table, a certificate and an API Gateway. The user `curl`s a POST endpoint to add an integer, which is stored in the DynamoDB table. Then `curl` a GET endpoint to retrieve the integer from the DynamoDB table. We built this app config to demonstrate how Nuon can work with serverless apps and not Kubernetes. See the [minimum sandbox](https://github.com/nuonco/aws-min-sandbox) repository used by the AWS Lambda app config and which does not include Kubernetes resources.

## eks-simple

Creates an EKS cluster with a `whoami` application deployed on it, an Application Load Balancer and a Certificate. The App Install is accessible from https://<subdomain input>.<install id>.nuon.run. See the Nuon docs for [a step-by-step guide](https://docs.nuon.co/get-started/create-your-first-app) on how to deploy this app.

## coder

[Coder](https://coder.com) is a self-hosted Cloud Development Environment (CDE) platform that allows developers and their agents to develop and build code remotely in the cloud with container or VM workspaces. This app config deploys a Postgres database container and Coder control plane container in an EKS cluster as well as an ALB and certificate in the VPC for cluster and Coder access. It has several Action scripts including creating a base64 Postgres secret, an ALB health check, and a default storage class. Read this blog post about: [installing Coder with Nuon](https://nuon.co/blog/installing-coder-with-nuon/).

## mattermost

[Mattermost](https://mattermost.com) is an open-source, self-hostable collaboration platform. This app config deploys the Mattermost operator and a Mattermost instance in an EKS cluster as well as an ALB and certificate in the VPC for cluster and Mattermost access. It has several Action scripts including creating a base64 Postgres secret, an ALB health check, and a default storage class.

## penpot

[Penpot](https://penpot.app) is an open-source design and prototyping platform comparable to Figma. This app config deploys a Postgres database container and several Penpot control plane containers in an EKS cluster as well as an ALB and certificate in the VPC for cluster and Penpot access.

## httpbin

[httpbin](https://httpbingo.org) is a simple HTTP request and response debugging service. This app config deploys an ec2 instance and runs the httpbin service using a docker container.

# How to Use

Clone this repo and cd into the app config directory you want to use, e.g. `cd example-app-configs/<app directory>`. Then run the following commands to create and sync the app config to the Nuon cloud:

```bash
brew install nuonco/tap/nuon
nuon login
nuon apps create --name <app directory>
nuon apps sync .
```

> If you are requesting a Nuon login for the first time, authenticate with your Google account, fill out the form, and wait for follow-up from the Nuon team. Once you receive access, you can proceed with the `nuon apps` commands above.

Go to the Nuon dashboard at https://app.nuon.co, select your app, and click "Install". Follow the prompts to complete your first app install in AWS.

# Resources

[Nuon docs](https://docs.nuon.co)

[AWS EKS Sandbox](https://github.com/nuonco/aws-eks-sandbox)

[AWS EKS Karpenter Sandbox](https://github.com/nuonco/aws-eks-karpenter-sandbox)

[AWS Min Sandbox](https://github.com/nuonco/aws-min-sandbox)
