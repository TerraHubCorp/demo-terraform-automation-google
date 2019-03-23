#!/usr/bin/env bash

gcloud --version > /dev/null 2>&1 || { echo >&2 'gcloud is missing. aborting...'; exit 1; }
jq --version > /dev/null 2>&1 || { echo >&2 'jq is missing. aborting...'; exit 1; }
npm --version > /dev/null 2>&1 || { echo >&2 'npm is missing. aborting...'; exit 1; }
export NODE_PATH="$(npm root -g)"

if [ -z "${BRANCH_FROM}" ]; then BRANCH_FROM = "dev"; fi
if [ -z "${BRANCH_TO}" ]; then BRANCH_TO = "dev"; fi
if [ "${BRANCH_TO}" != "dev" ]; then THUB_ENV="-e ${BRANCH_TO}"; fi
if [ "${THUB_STATE}" == "approved" ]; then THUB_APPLY="-a"; fi

git --version > /dev/null 2>&1 || { echo >&2 'git is missing. aborting...'; exit 1; }
git checkout $BRANCH_TO
git checkout $BRANCH_FROM

export GOOGLE_CLOUD_PROJECT="$(gcloud config list --format=json | jq -r '.core.project')"
echo "GOOGLE_CLOUD_PROJECT: ${GOOGLE_CLOUD_PROJECT}"
export GOOGLE_APPLICATION_CREDENTIALS="${HOME}/.config/gcloud/${GOOGLE_CLOUD_PROJECT}.json"
echo "GOOGLE_APPLICATION_CREDENTIALS: ${GOOGLE_APPLICATION_CREDENTIALS}"
echo $GOOGLE_APPLICATION_CREDENTIALS_CONTENT > ${GOOGLE_APPLICATION_CREDENTIALS}
gcloud auth activate-service-account --key-file ${GOOGLE_APPLICATION_CREDENTIALS}
export BILLING_ID="$(gcloud beta billing accounts list --format=json | jq -r '.[0].name[16:]')"

terrahub --version > /dev/null 2>&1 || { echo >&2 'terrahub is missing. aborting...'; exit 1; }
terrahub configure -c template.locals.google_project_id="${GOOGLE_CLOUD_PROJECT}"
terrahub configure -c template.locals.google_billing_account="${BILLING_ID}"

terrahub run -y -b ${THUB_APPLY} ${THUB_ENV}