# Bitwarden on ROSA

A step-by-step walkthrough of deploying self-hosted Bitwarden on Red Hat OpenShift on AWS (ROSA, with hosted control planes), with explanations behind every step (wherever appropriate).

**Disclaimer**: While I am an engineer at Bitwarden, I want to note that this repository is a learning project and a walk through of deploying on ROSA; it is not official Bitwarden documentation or production guidance (in fact, it's probably the opposite, given the purpose of the deployment aims for quick set-up to test things, then a full blown tear down).
Always check official docs for up to date instructions on deploying.

**Status:** Work in progress.


## References used
+ Red Hat: [ROSA Quickstart](https://cloud.redhat.com/experts/rosa/quickstart/), [Required IAM roles and resources](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws/4/html/prepare_your_environment/rosa-hcp-prepare-iam-roles-resources), [OCM role becoming mandatory](https://access.redhat.com/articles/7137057), [Persistent storage using AWS EFS](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws_classic_architecture/4/html/storage/using-container-storage-interface-csi) (classic edition; the steps worked on HCP)
+ AWS: [Set up to use ROSA](https://docs.aws.amazon.com/rosa/latest/userguide/set-up.html), [ROSA pricing](https://aws.amazon.com/rosa/pricing/), [aws login announcement](https://aws.amazon.com/about-aws/whats-new/2025/11/console-credentials-aws-cli-sdk-authentication/)
+ Bitwarden: [Kubernetes service accounts](https://bitwarden.com/help/kubernetes-service-accounts/), [Add rawManifest files](https://bitwarden.com/help/add-rawmanifest-files/), [External MSSQL database](https://bitwarden.com/help/external-db/), [helm-charts repo](https://github.com/bitwarden/helm-charts)
+ Kubernetes: [Ingress NGINX retirement statement](https://kubernetes.io/blog/2026/01/29/ingress-nginx-statement/)