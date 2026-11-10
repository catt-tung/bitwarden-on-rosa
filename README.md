# Bitwarden on ROSA

A step-by-step walkthrough of deploying self-hosted Bitwarden on Red Hat OpenShift Service on AWS (ROSA, with hosted control planes, or HCP), with explanations behind every step wherever appropriate.

**Disclaimer:** While I am an engineer at Bitwarden, this repository is a learning project and a walkthrough of one deployment on ROSA. It is not official Bitwarden documentation or production guidance (in fact it's probably the opposite, given the aim is a quick set-up to test things, followed by a full-blown teardown).

Always check the official docs for up-to-date instructions on deploying.

**Status:** Work in progress. I ran this deployment once, in November 2026, and I'm writing it up chapter by chapter.

## Why this exists
Some Bitwarden customers deploy their self-hosted instance on OpenShift (or use the Helm deployment more generally), and at times I need a cluster to test whether I can reproduce what they report. A cluster that runs around the clock isn't practical for that, so I wanted to put in the upfront time to document repeatable steps: spin up an OpenShift cluster, deploy Bitwarden with its Helm chart, test what I need, and tear it all down again (which matters, to avoid unnecessary charges).

## Goals
+ Get a working self-hosted Bitwarden instance, deployed with its Helm chart, running on ROSA
+ Document each step so the pieces make sense (what each identity, network component and setting is for), not just which commands to run
+ Write the documentation so that anyone, including future me, can follow along and build the same thing
+ Keep a rough account of the cost, and of anything that went wrong along the way
+ Document a full, clean teardown that leaves nothing billing on AWS

## What this builds
+ A ROSA cluster with hosted control planes and two worker nodes, in an AWS account
+ The identities it needs (Identity and Access Management (IAM) roles and an OpenID Connect (OIDC) provider) and a purpose-built Virtual Private Cloud (VPC)
+ Shared storage on Amazon Elastic File System (EFS), so the Bitwarden chart's ReadWriteMany volumes work
+ Bitwarden itself, installed with its Helm chart and exposed through OpenShift Routes
+ A custom domain with a Let's Encrypt certificate
+ Outgoing email through an SMTP service (a sandbox mail catcher, so nothing real is sent)
+ A full teardown, so nothing keeps billing

## Time and cost
These are my own rough estimates from my run in November 2026. Check current pricing for up-to-date figures.
+ Time: a few hours end to end if nothing goes wrong. The cluster itself takes about 10 to 15 minutes to become ready.
+ Cost while the cluster runs: roughly US$1.10 to US$1.30 an hour (ROSA service fees, two worker nodes, plus the AWS network and storage underneath).
+ My whole run: roughly US$11 to US$12 in total, with a clean teardown at the end. I did it in two sittings (about 8 hours of cluster time between them, much of it spent on snags this walkthrough should save you from) and kept the network and storage in place in between rather than rebuilding them.
+ In a shared AWS account, Cost Explorer can't isolate your own spend, so these figures are estimates from the pricing pages and my own timings, not from an actual bill.
+ Each chapter has a short Cost check that says what starts billing at that point.

## Before you start
+ An AWS account where you can create IAM roles, CloudFormation stacks, VPC resources and EFS file systems
+ A Red Hat account (free)
+ The `aws`, `rosa`, `oc`, `kubectl` and `helm` CLIs (and AWS CLI 2.32.0 or later if you want `aws login`)
+ A Bitwarden installation ID and key from [bitwarden.com/host](https://bitwarden.com/host/)
+ An SMTP service for the verification emails (I used a sandbox mail catcher)
+ A domain you control and a TLS certificate bundle for it (needed for the custom domain chapter; the earlier chapters work on the cluster's own default domain)
+ Strongly recommended: an AWS budget alert, set up before anything billable exists (I didn't set one up, because the AWS account was shared)

## Contents
Chapters get a link when they're written. Until then they're planned.

| # | Chapter | What it covers | Status |
|---|---|---|---|
| 00 | Why OpenShift, and why ROSA | What OpenShift is, options available, Bitwarden on Kubernetes, how Helm fits in | planned |
| 01 | Prerequisites | Accounts, CLIs, logins, enabling and linking ROSA, a naming/tagging convention | planned |
| 02 | Identity | Account roles, the OIDC provider, operator roles and the OCM role, and why there are so many | planned |
| 03 | Network | The VPC, public and private subnets, NAT, endpoints, and CloudFormation | planned |
| 04 | Cluster | Creating the cluster, reading the logs, logging in | planned |
| 05 | Storage | Amazon EFS, the CSI operator and a StorageClass | planned |
| 06 | Bitwarden | Project, service account, secret, values, install, verification | planned |
| 07 | Domain and TLS | DNS, the certificate, Routes, restarting pods | planned |
| 08 | Teardown | Deleting everything in the right order, and checking nothing is left | planned |
| 09 | Gotchas | Any problems I ran into: symptom, cause, fix | planned |
| 10 | Reflections | How this compares with EKS, AKS and GKE, and what I'd do differently | planned |
| A | Session restart, glossary, costs | | planned |

## Repository layout
```
bitwarden-on-rosa/
  README.md
  LICENSE
  .gitignore
  docs/       the chapters
  assets/     redacted screenshots and diagrams, one folder per chapter
```
`helm/` (a values template with placeholders) and `secrets/` (`*.example` files only) arrive with chapter 06.

## How to read this
+ **Placeholders** are in capitals inside angle brackets, such as `<ACCOUNT_ID>` and `<CLUSTER_NAME>`. Replace them with your own values. Examples use the prefix `rosalab` and the domain `example.com`.
+ **Shell variables** keep the same names throughout, such as `ACCOUNT_ROLES_PREFIX`, `OPERATOR_ROLES_PREFIX`, `OIDC_CONFIG_ID` and `SUBNET_IDS`.
+ Commands were run on macOS with zsh. Most work on Linux, but check `sed -i` and package-manager steps.

## Privacy
There are none of my own account IDs, emails, domains or keys in this repository. Screenshots are redacted with solid boxes, and the real secrets live outside the repo. If you notice something that looks like a leak, please open an issue.

## Licence
MIT. See [LICENSE](LICENSE).

## References used
+ Red Hat: [ROSA Quickstart](https://cloud.redhat.com/experts/rosa/quickstart/), [Required IAM roles and resources](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws/4/html/prepare_your_environment/rosa-hcp-prepare-iam-roles-resources), [OCM role becoming mandatory](https://access.redhat.com/articles/7137057), [Using Container Storage Interface (CSI), including the AWS EFS section](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws_classic_architecture/4/html/storage/using-container-storage-interface-csi) (classic architecture edition; the steps worked on HCP)
+ AWS: [Set up to use ROSA](https://docs.aws.amazon.com/rosa/latest/userguide/set-up.html), [ROSA pricing](https://aws.amazon.com/rosa/pricing/), [aws login announcement](https://aws.amazon.com/about-aws/whats-new/2025/11/console-credentials-aws-cli-sdk-authentication/)
+ Bitwarden: [Kubernetes service accounts](https://bitwarden.com/help/kubernetes-service-accounts/), [Add rawManifest files](https://bitwarden.com/help/add-rawmanifest-files/), [External MSSQL database](https://bitwarden.com/help/external-db/), [helm-charts repo](https://github.com/bitwarden/helm-charts)
+ Kubernetes: [Ingress NGINX retirement statement](https://kubernetes.io/blog/2026/01/29/ingress-nginx-statement/)