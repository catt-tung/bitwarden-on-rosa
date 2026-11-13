# 01 - Prerequisites

**Goal:** get the accounts, command line tools and logins in place, and enable ROSA in AWS, so the next chapters can start creating things.

**Cost check:** nothing in this chapter bills. Enabling ROSA creates a no-cost contract on the AWS account to make on-demand billing work.

## Accounts
### AWS
+ An AWS account where you can create IAM roles, CloudFormation stacks, VPC resources and EFS file systems. Use an IAM user (or role) rather than the root user.
+ If the account is shared, check with whoever owns it first. Enabling ROSA is account-wide (it links the whole AWS account to a Red Hat organisation), and company guardrails such as restricted regions or blocked IAM actions can make a step fail half-way through.

### Red Hat
+ Register for a free account at `console.redhat.com`.
+ The sign-up asks for an account type, personal or corporate. Red Hat says to select corporate if the account will be used with an organisation or business, and personal if it will only have a single user and won't be used for business purposes ([How to Create a New Red Hat Login ID and Account](https://access.redhat.com/node/7136860)).
+ If your company already has a Red Hat organisation, ask its organisation administrator to add you rather than registering a new account. A separate registration creates a separate account without access to the company's.
+ When I signed up, the page warned me that the login ID can't be changed once it's created.
+ Note that the login ID can't be changed once it's created.

## Setting a budget alert
Do this before anything billable exists. In the AWS console, go to Billing > Budgets > Create budget. A monthly cost budget with email alerts at 50%, 80% and 100% is plenty.

Two things to note:
+ A budget only notifies you, it doesn't stop spending, and billing data lags by hours. It's a backstop for forgetting to tear things down. The teardown is the real protection.
+ In a shared account a budget can't be scoped to your own activity. The closest options are a linked account, a region only you use, or cost allocation tags.

## A naming and tagging convention
Reference - this matters in a shared account, especially for teardown: other people deploy things in the same account, so everything you create should be easy to identify, and safe to delete without touching anyone else's resources. **Pick a short prefix and two tags, and use them for everything.**
+ **Prefix:** the examples in this repository use `rosalab`. It goes into IAM role names, the network stack, the cluster and the EFS file system. Keep it short (but identifiable!): IAM role names are limited to 64 characters, and one of the operator roles had its name cut off when I deployed it, because the name was too long. The cluster name is limited to 54 characters and the domain prefix to 15.
+ **Tags:** `owner=<YOUR_HANDLE>` and `project=rosalab`. Later chapters pass them to the network stack, the cluster and the EFS resources, and the teardown checks use them to find leftovers. (The IAM roles are identified by the prefix instead.)
+ **The rule:** before deleting anything, confirm its name or tag matches.

## The command line tools needed
| Tool | What it's for | Needed from |
|---|---|---|
| `aws` | Talking to AWS | This chapter |
| `rosa` | Creating and managing the ROSA cluster | This chapter |
| `oc` | Talking to the cluster (OpenShift's `kubectl`) | Chapter 04 |
| `kubectl` | Optional, `oc` covers the same ground | Chapter 04 |
| `helm` | Installing Bitwarden | Chapter 06 |

On macOS you can do this with Homebrew:
```bash
brew install awscli
brew install openshift-cli
brew install kubectl
brew install helm
```
Note: `aws login` needs AWS CLI 2.32.0 or later. I used 2.38.4.

### Installing rosa
You can install any of these tools from binaries instead of Homebrew, but for `rosa` I had to. The Homebrew formula was behind the version Red Hat currently serves, and `brew upgrade` never moved it, so installing the binary directly was the only thing that worked.
1. Download the `rosa` tarball for your operating system and chip from the [Downloads](https://console.redhat.com/openshift/downloads) page of the Red Hat console (you need to be signed in to access that page).
2. Extract it and install it on your `PATH`:
```bash
tar -xzf <DOWNLOADED_FILE>.tar.gz
sudo install -m 0755 ./rosa /usr/local/bin/rosa
rosa version
```
If macOS refuses to run it, remove the quarantine flag with `xattr -d com.apple.quarantine /usr/local/bin/rosa`. I used `rosa` 1.2.67.

## Logging in to AWS
Reference - `aws login` and profiles: `aws login` signs you in through the browser as your IAM user and caches short-lived credentials on your machine, so there are no long-term access keys to leak. A profile is just a named block in `~/.aws/config` on your machine, and the name means nothing to AWS. The session refreshes automatically for up to 12 hours, and after that you will have to log in again.

```bash
aws login --profile <PROFILE_NAME>
export AWS_PROFILE=<PROFILE_NAME>
aws configure set region <REGION> --profile <PROFILE_NAME>
export AWS_REGION=<REGION>
aws sts get-caller-identity
```
+ The last command shows who you are. Check it's your IAM user and not root. It prints your account ID inside the ARN, so don't paste the output into any notes!
+ Pick a region that supports ROSA with hosted control planes. I used `us-east-1`. Check AWS's ROSA documentation for the supported list (the CLI command that should list them didn't work for me, see the section describing the quirk below).

## Logging in to Red Hat
```bash
rosa login --use-auth-code
rosa whoami
```
The first command signs you in through the browser with Red Hat single sign-on. It's a separate session from the AWS one. `rosa whoami` prints both your Red Hat and AWS account information, so be sure to keep that output private too.

## Enabling ROSA and linking your accounts
Now that you are logged in to both AWS and Red Hat, the AWS account has to be enabled for ROSA, and linked to your Red Hat account.
1. In the AWS console, search for ROSA and choose **Get started**. The page lists what's needed: verify the prerequisites, enable ROSA, and check you have enough quota for other AWS services and the Elastic Load Balancing service-linked role.
2. Choose **Enable ROSA with HCP and ROSA classic**. It can take several minutes to activate (it will say something like "Your request to enable ROSA is pending"). Keep the page open so you can see any errors.
3. When it shows a green checkmark, choose **Continue to Red Hat** and log in with the Red Hat account you registered. You'll see both account numbers on the screen, and a message that your Red Hat and AWS accounts are linked.

A few things to know:
+ Enabling is account-wide, as noted previously.
+ There's an additional link to make in chapter 02 - Red Hat now requires a role called the OCM role before it will create clusters in your account.

## Checking quotas
```bash
rosa verify quota
```
This returned `AWS quota ok`, along with a reminder that if the installation fails you should compare your real AWS usage against the required quotas. That matters most in a shared account, where existing usage may already be high. For this lab, the two workers use 8 vCPUs of on-demand instance quota (an `m7i.xlarge` has 4 vCPUs).
If something happens to fail later on in the process, check Service Quotas in the console for the region, especially vCPUs, Elastic IPs and VPCs.

## A weird quirk I never resolved: `rosa list regions --hosted-cp`
This command is meant to list the regions that support hosted control planes. For me it returned this error, every time, even though `aws sts get-caller-identity` worked and `rosa verify quota` passed:

```
E: Failed to fetch regions: An error occurred while trying to create an AWS client: The provided AWS credentials are not valid
```

The debug output (`--debug`) shows the failing request goes to Red Hat's API (`.../cloud_providers/aws/regions`) and returns HTTP 400 with the code `CLUSTERS-MGMT-400`, so it isn't an error from AWS itself. I kept an eye on it throughout the whole lab, it never stopped me from doing anything, and I never found the cause. Enabling ROSA and linking the accounts didn't change it either. I ended up just ignoring it and it was fine.

## A helper for new terminals
Every new terminal starts without your `AWS_PROFILE` and `AWS_REGION`, and sessions expire. `scripts/env.sh` sets the variables and defines `lab-start`, which logs you in to AWS and Red Hat only if the sessions have expired, shows the active Kubernetes context, and lists any ROSA clusters (the main things that bill by the hour).

Edit the two values at the top of the script, then you can source `scripts/env.sh` at the start of every terminal session:
```bash
cd <PATH_TO_THIS_REPO>
source scripts/env.sh
lab-start
```
The script also clears any stale `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `AWS_SESSION_TOKEN` variables, which would otherwise override your profile.

## Verify
```bash
aws --version                           # 2.32.0 or later
aws sts get-caller-identity             # your IAM user, not root
rosa version
rosa whoami                             # shows your AWS and Red Hat accounts
rosa verify quota                       # AWS quota ok
```
In the AWS console, ROSA should show as enabled, with the Red Hat link confirmed.

## What's next
Chapter 02 creates the identities ROSA needs: IAM roles and an OpenID Connect provider. It's still free, and chapter 02 is where we'll go into why there are so many roles!

## Sources for this chapter
+ [Red Hat: Prerequisites checklist for deploying ROSA](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws/4/html/prepare_your_environment/rosa-cloud-expert-prereq-checklist)
+ [AWS: Set up to use ROSA](https://docs.aws.amazon.com/rosa/latest/userguide/set-up.html)
+ [AWS: aws login announcement](https://aws.amazon.com/about-aws/whats-new/2025/11/console-credentials-aws-cli-sdk-authentication/) and [the AWS security blog post on aws login](https://aws.amazon.com/blogs/security/simplified-developer-access-to-aws-with-aws-login)
+ [AWS: How ROSA works with AWS Marketplace](https://docs.aws.amazon.com/rosa/latest/userguide/integration-marketplace.html)
+ [Red Hat: Required AWS service quotas for ROSA](https://docs.openshift.com/rosa/rosa_getting_started/rosa-required-aws-service-quotas.html)
+ [AWS: IAM and AWS STS quotas](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-quotas.html) (the 64-character role name limit)
+ `rosa create cluster --help` (the 54-character cluster name and 15-character domain prefix limits)