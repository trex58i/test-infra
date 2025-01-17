# test-infra

## How to test the ProwJob

#### Method 1: Test using the kind cluster
https://github.com/kubernetes/test-infra/blob/master/prow/build_test_update.md#using-pj-on-kindsh

#### Method 2: Test on the already deployed kubernetes cluster

```shell script
# set the kubeconfig to proper cluster
$ export KUBECONFIG=/home/.kube/config

# run the ./hack/test-pj.sh script, following the script runs the k8s-ppc64le-cluster-health-check on the cluster configured by KUBECONFIG(default: ${HOME}/.kube/config)
$ CONFIG_PATH=$(pwd)/config/prow/config.yaml JOB_CONFIG_PATH=$(pwd)/config/jobs/ppc64le-cloud/test-infra/test-infra-periodics.yaml ./hack/test-pj.sh k8s-ppc64le-cluster-health-check
```

## Tools exposed via this repository

- https://prow.ppc64le-cloud.org/ - Dashboard for internal prow jobs that run on ppc64le build cluster and a few on IKS(x86) cluster.
- https://search.ppc64le-cloud.org/ - ci-search tool by openshift, configured to our internal prow jobs that have logs uploaded to GCS storage.
- https://jenkins.ppc64le-cloud.org/ - Jenkins dashboard for OCP jobs run on Jenkins infra.
- https://grafana.ppc64le-cloud.org - Grafana dashboard for analysing OCP jobs from Jenkins.

## Deprecated

03 May 2022 - Usage of pod-utility images from locally built and pushed `quay.io/powercloud` private repo is deprecated.

The upstream pod-utility images from `gcr.io/k8s-prow` will be used - [Change](https://github.com/ppc64le-cloud/test-infra/pull/309/files#diff-d840b3456d7d17beb3ded91cf0ca9d6fd065baedb31a0a634b5101df3f7925d4L77)

Files from [here](https://github.com/ppc64le-cloud/test-infra/tree/master/images/pod-utilities) will not be used.
