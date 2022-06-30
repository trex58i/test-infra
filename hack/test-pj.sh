#!/usr/bin/env bash
# Inspired by https://github.com/kubernetes/test-infra/blob/047b0a0596f7d42b909405c0b8ed4366de2bef72/prow/pj-on-kind.sh
# Required kubectl
# Rightnow this work only on the x86 platform(Linux, MacOS)

set -o errexit
set -o nounset
set -o pipefail

###
# The pod utilites image are of the cluster is out of sync with the latest mpkod image at he moment.
#See the change introduced Feb 17 2022 by the PR https://github.com/kubernetes/test-infra/pull/25305
#In particular this line https://github.com/kubernetes/test-infra/blob/38badb969d5acd85e08c154e48adf175bfba86a9/prow/pod-utils/decorate/podspec.go#L575
#If using the latest mkpod imag (as per Feb 18 2022), the pod fails because of this error:
#  place-entrypoint:
    # Container ID:  containerd://48b9b96ec644912103b2480f4ffe7ac1fff726bc5bb4c393e828da11b7f05ab8
    # Image:         quay.io/powercloud/entrypoint:v20220201-d251d8b00d
    # Image ID:      quay.io/powercloud/entrypoint@sha256:5a0e03ab7e1989a6a742b7988575aa7f1c9059ee2c7777a6f734dee708b4d65e
    # Port:          <none>
    # Host Port:     <none>
    # Args:
    #   --copy-mode-only
    # State:      Terminated
    #   Reason:   Error
    #   Message:  {"component":"unset","file":"/go/test-infra/prow/cmd/entrypoint/main.go:37","func":"main.main","level":"fatal","msg":"Invalid options: no process to wrap specified","severity":"fatal","time":"2022-02-18T17:12:29Z"}

    #   Exit Code:    1
MKPOD_IMAGE="gcr.io/k8s-prow/mkpod@sha256:f0dd9d390d4d668510fd296cc119adde7b159d4b7b9e8898eb3c1c11d7a53b57"


function main() {
  parseArgs "$@"

  # Generate PJ and Pod.
  docker run -i --rm -v "${PWD}:${PWD}" -v "${config}:${config}" ${job_config_mnt} -w "${PWD}" gcr.io/k8s-prow/mkpj "--config-path=${config}" "--job=${job}" ${job_config_flag} "${base_ref_flag}"> "${PWD}/pj.yaml"
  docker run -i --rm -v "${PWD}:${PWD}" -w "${PWD}" ${MKPOD_IMAGE} --build-id=snowflake "--prow-job=${PWD}/pj.yaml" > "${PWD}/pod.yaml"

  echo "Applying pod to the mkpod cluster. Configure kubectl for the mkpod cluster with:"
  echo "Press Control+c for exiting the script"
  pod=$(kubectl apply -f "${PWD}/pod.yaml" | cut -d ' ' -f 1)
  echo ""
  echo "POD=${pod}" > ~/current_prow_job.env
  echo "Wrote POD=${pod} ~/current_prow_job.env ."
  echo "After the pod completed the initialization step, you can run this command to display the log of the job:"
  echo ". ~/current_prow_job.env && kubectl logs -f ${pod} -c test"
  echo ""

  kubectl get "${pod}" -w
}

function parseArgs() {
  job="${1:-}"
  git_ref="${2:-}"
  config="${CONFIG_PATH:-}"
  job_config_path="${JOB_CONFIG_PATH:-}"
  out_dir="${OUT_DIR:-/tmp/prowjob-out}"
  #node_dir="${NODE_DIR:-/tmp/kind-node}"

  echo "job=${job}"
  echo "CONFIG_PATH=${config}"
  echo "JOB_CONFIG_PATH=${job_config_path}"
  echo "OUT_DIR=${out_dir}"
  #echo "NODE_DIR=${node_dir}"

  if [[ -z "${job}" ]]; then
    echo "Must specify a job name as the first argument."
    exit 2
  fi
  if [[ -z "${config}" ]]; then
    echo "Must specify config.yaml location via CONFIG_PATH env var."
    exit 2
  fi
  job_config_flag=""
  job_config_mnt=""
  if [[ -n "${job_config_path}" ]]; then
    job_config_flag="--job-config-path=${job_config_path}"
    job_config_mnt="-v ${job_config_path}:${job_config_path}"
  fi

  base_ref_flag=""
  if [[ -n "${git_ref}" ]]; then
    base_ref_flag="-base-ref=${git_ref}"
  fi
}

main "$@"
