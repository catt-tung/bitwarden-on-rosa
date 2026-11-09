# Bitwarden on ROSA

A step-by-step walkthrough of deploying self-hosted Bitwarden on Red Hat OpenShift Service on AWS (ROSA, with hosted control planes, or HCP), with explanations behind every step wherever appropriate.

**Disclaimer:** While I am an engineer at Bitwarden, this repository is a learning project and a walkthrough of one deployment on ROSA. It is not official Bitwarden documentation or production guidance (in fact it's probably the opposite, given the aim is a quick set-up to test things, followed by a full-blown teardown).

Always check the official docs for up-to-date instructions on deploying.

**Status:** Work in progress.

## Why this exists
Some Bitwarden customers deploy their self-hosted instance on OpenShift (or use the Helm deployment more generally), and at times I need a cluster to test whether I can reproduce what they report. A cluster that runs around the clock isn't practical for that, so I wanted to put in the upfront time to document repeatable steps: spin up an OpenShift cluster, deploy Bitwarden with its Helm chart, test what I need, and tear it all down again (which matters, to avoid unnecessary charges).

## Goals
+ Get a working self-hosted Bitwarden instance, deployed with its Helm chart, running on ROSA
+ Document each step so the pieces make sense (what each identity, network component and setting is for), not just which commands to run
+ Write the documentation so that anyone, including future me, can follow along and build the same thing
+ Keep a rough account of the cost, and of anything that went wrong along the way
+ Document a full, clean teardown that leaves nothing billing on AWS

## References used
+ Red Hat: [ROSA Quickstart](https://cloud.redhat.com/experts/rosa/quickstart/), [Required IAM roles and resources](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws/4/html/prepare_your_environment/rosa-hcp-prepare-iam-roles-resources), [OCM role becoming mandatory](https://access.redhat.com/articles/7137057), [Using Container Storage Interface (CSI), including the AWS EFS section](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws_classic_architecture/4/html/storage/using-container-storage-interface-csi) (classic architecture edition; the steps worked on HCP)
+ AWS: [Set up to use ROSA](https://docs.aws.amazon.com/rosa/latest/userguide/set-up.html), [ROSA pricing](https://aws.amazon.com/rosa/pricing/), [aws login announcement](https://aws.amazon.com/about-aws/whats-new/2025/11/console-credentials-aws-cli-sdk-authentication/)
+ Bitwarden: [Kubernetes service accounts](https://bitwarden.com/help/kubernetes-service-accounts/), [Add rawManifest files](https://bitwarden.com/help/add-rawmanifest-files/), [External MSSQL database](https://bitwarden.com/help/external-db/), [helm-charts repo](https://github.com/bitwarden/helm-charts)
+ Kubernetes: [Ingress NGINX retirement statement](https://kubernetes.io/blog/2026/01/29/ingress-nginx-statement/)