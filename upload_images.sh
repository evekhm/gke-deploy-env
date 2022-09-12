PROJECT_ID=$(gcloud config get-value project)

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR"/SET

docker-credential-gcr configure-docker --registries=${REGION}-docker.pkg.dev

function upload()
{
  local app=$1
  local gitlab_path=registry.gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/${app}/released
  docker pull "${gitlab_path}"
  docker tag "${gitlab_path}" \
          ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${app}
  docker push ${REGION}-docker.pkg.dev/$PROJECT_ID/${REPOSITORY}/${app}
}

upload auth
upload crd
upload dtr
upload prior-auth
upload test-ehr
upload crd-request-generator

