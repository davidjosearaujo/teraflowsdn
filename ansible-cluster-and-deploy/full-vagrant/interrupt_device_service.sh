kubectl delete pods -n tfs $(kubectl get pods -n tfs --no-headers -o custom-columns=":metadata.name" | grep device)

sleep 30

source my_deploy.sh

#!/bin/bash
# Copyright 2022-2024 ETSI OSG/SDG TeraFlowSDN (TFS) (https://tfs.etsi.org/)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


########################################################################################################################
# Read deployment settings
########################################################################################################################


# ----- TeraFlowSDN ------------------------------------------------------------

# If not already set, set the URL of the Docker registry where the images will be uploaded to.
# By default, assume internal MicroK8s registry is used.
export TFS_REGISTRY_IMAGES=${TFS_REGISTRY_IMAGES:-"http://localhost:32000/tfs/"}

# If not already set, set the list of components, separated by spaces, you want to build images for, and deploy.
# By default, only basic components are deployed
export TFS_COMPONENTS="device"

# If not already set, set the tag you want to use for your images.
export TFS_IMAGE_TAG=${TFS_IMAGE_TAG:-"dev"}

# If not already set, set the name of the Kubernetes namespace to deploy TFS to.
export TFS_K8S_NAMESPACE=${TFS_K8S_NAMESPACE:-"tfs"}

# If not already set, set additional manifest files to be applied after the deployment
export TFS_EXTRA_MANIFESTS=${TFS_EXTRA_MANIFESTS:-""}

# If not already set, set the new Grafana admin password
export TFS_GRAFANA_PASSWORD=${TFS_GRAFANA_PASSWORD:-"admin123+"}

# If not already set, disable skip-build flag to rebuild the Docker images.
# If TFS_SKIP_BUILD is "YES", the containers are not rebuilt-retagged-repushed and existing ones are used.
export TFS_SKIP_BUILD=${TFS_SKIP_BUILD:-""}


# ----- CockroachDB ------------------------------------------------------------

# If not already set, set the namespace where CockroackDB will be deployed.
export CRDB_NAMESPACE=${CRDB_NAMESPACE:-"crdb"}

# If not already set, set the external port CockroackDB Postgre SQL interface will be exposed to.
export CRDB_EXT_PORT_SQL=${CRDB_EXT_PORT_SQL:-"26257"}

# If not already set, set the external port CockroackDB HTTP Mgmt GUI interface will be exposed to.
export CRDB_EXT_PORT_HTTP=${CRDB_EXT_PORT_HTTP:-"8081"}

# If not already set, set the database username to be used by Context.
export CRDB_USERNAME=${CRDB_USERNAME:-"tfs"}

# If not already set, set the database user's password to be used by Context.
export CRDB_PASSWORD=${CRDB_PASSWORD:-"tfs123"}

# If not already set, set the database name to be used by Context.
export CRDB_DATABASE=${CRDB_DATABASE:-"tfs"}


# ----- NATS -------------------------------------------------------------------

# If not already set, set the namespace where NATS will be deployed.
export NATS_NAMESPACE=${NATS_NAMESPACE:-"nats"}

# If not already set, set the external port NATS Client interface will be exposed to.
export NATS_EXT_PORT_CLIENT=${NATS_EXT_PORT_CLIENT:-"4222"}

# If not already set, set the external port NATS HTTP Mgmt GUI interface will be exposed to.
export NATS_EXT_PORT_HTTP=${NATS_EXT_PORT_HTTP:-"8222"}


# ----- QuestDB ----------------------------------------------------------------

# If not already set, set the namespace where QuestDB will be deployed.
export QDB_NAMESPACE=${QDB_NAMESPACE:-"qdb"}

# If not already set, set the external port QuestDB Postgre SQL interface will be exposed to.
export QDB_EXT_PORT_SQL=${QDB_EXT_PORT_SQL:-"8812"}

# If not already set, set the external port QuestDB Influx Line Protocol interface will be exposed to.
export QDB_EXT_PORT_ILP=${QDB_EXT_PORT_ILP:-"9009"}

# If not already set, set the external port QuestDB HTTP Mgmt GUI interface will be exposed to.
export QDB_EXT_PORT_HTTP=${QDB_EXT_PORT_HTTP:-"9000"}

# If not already set, set the database username to be used for QuestDB.
export QDB_USERNAME=${QDB_USERNAME:-"admin"}

# If not already set, set the database user's password to be used for QuestDB.
export QDB_PASSWORD=${QDB_PASSWORD:-"quest"}

# If not already set, set the table name to be used by Monitoring for KPIs.
export QDB_TABLE_MONITORING_KPIS=${QDB_TABLE_MONITORING_KPIS:-"tfs_monitoring_kpis"}

# If not already set, set the table name to be used by Slice for plotting groups.
export QDB_TABLE_SLICE_GROUPS=${QDB_TABLE_SLICE_GROUPS:-"tfs_slice_groups"}


# ----- K8s Observability ------------------------------------------------------

# If not already set, set the external port Prometheus Mgmt HTTP GUI interface will be exposed to.
export PROM_EXT_PORT_HTTP=${PROM_EXT_PORT_HTTP:-"9090"}

# If not already set, set the external port Grafana HTTP Dashboards will be exposed to.
export GRAF_EXT_PORT_HTTP=${GRAF_EXT_PORT_HTTP:-"3000"}


########################################################################################################################
# Automated steps start here
########################################################################################################################

# Constants
GITLAB_REPO_URL="labs.etsi.org:5050/tfs/controller"
TMP_FOLDER="./tmp"

# Create a tmp folder for files modified during the deployment
TMP_MANIFESTS_FOLDER="${TMP_FOLDER}/${TFS_K8S_NAMESPACE}/manifests"
mkdir -p $TMP_MANIFESTS_FOLDER
TMP_LOGS_FOLDER="${TMP_FOLDER}/${TFS_K8S_NAMESPACE}/logs"
mkdir -p $TMP_LOGS_FOLDER

echo "Deploying components and collecting environment variables..."
ENV_VARS_SCRIPT=tfs_runtime_env_vars.sh
echo "# Environment variables for TeraFlowSDN deployment" > $ENV_VARS_SCRIPT
PYTHONPATH=$(pwd)/src
echo "export PYTHONPATH=${PYTHONPATH}" >> $ENV_VARS_SCRIPT

DOCKER_BUILD="docker build"
DOCKER_MAJOR_VERSION=$(docker --version | grep -o -E "Docker version [0-9]+\." | grep -o -E "[0-9]+" | cut -c 1-3)
if [[ $DOCKER_MAJOR_VERSION -ge 23 ]]; then
    # If Docker version >= 23, build command was migrated to docker-buildx
    # In Ubuntu, in practice, means to install package docker-buildx together with docker.io
    # Check if docker-buildx plugin is installed
    docker buildx version 1>/dev/null 2>/dev/null
    if [[ $? -ne 0 ]]; then
        echo "Docker buildx command is not installed. Check: https://docs.docker.com/build/architecture/#install-buildx"
        echo "If you installed docker through APT package docker.io, consider installing also package docker-buildx"
        exit 1;
    fi
    DOCKER_BUILD="docker buildx build"
fi

for COMPONENT in $TFS_COMPONENTS; do
    echo "Processing '$COMPONENT' component..."

    if [ "$TFS_SKIP_BUILD" != "YES" ]; then
        echo "  Building Docker image..."
        BUILD_LOG="$TMP_LOGS_FOLDER/build_${COMPONENT}.log"

        if [ "$COMPONENT" == "ztp" ] || [ "$COMPONENT" == "policy" ]; then
            $DOCKER_BUILD -t "$COMPONENT:$TFS_IMAGE_TAG" -f ./src/"$COMPONENT"/Dockerfile ./src/"$COMPONENT"/ > "$BUILD_LOG"
        elif [ "$COMPONENT" == "pathcomp" ]; then
            BUILD_LOG="$TMP_LOGS_FOLDER/build_${COMPONENT}-frontend.log"
            $DOCKER_BUILD -t "$COMPONENT-frontend:$TFS_IMAGE_TAG" -f ./src/"$COMPONENT"/frontend/Dockerfile . > "$BUILD_LOG"

            BUILD_LOG="$TMP_LOGS_FOLDER/build_${COMPONENT}-backend.log"
            $DOCKER_BUILD -t "$COMPONENT-backend:$TFS_IMAGE_TAG" -f ./src/"$COMPONENT"/backend/Dockerfile . > "$BUILD_LOG"
            # next command is redundant, but helpful to keep cache updated between rebuilds
            IMAGE_NAME="$COMPONENT-backend:$TFS_IMAGE_TAG-builder"
            $DOCKER_BUILD -t "$IMAGE_NAME" --target builder -f ./src/"$COMPONENT"/backend/Dockerfile . >> "$BUILD_LOG"
        elif [ "$COMPONENT" == "dlt" ]; then
            BUILD_LOG="$TMP_LOGS_FOLDER/build_${COMPONENT}-connector.log"
            $DOCKER_BUILD -t "$COMPONENT-connector:$TFS_IMAGE_TAG" -f ./src/"$COMPONENT"/connector/Dockerfile . > "$BUILD_LOG"

            BUILD_LOG="$TMP_LOGS_FOLDER/build_${COMPONENT}-gateway.log"
            $DOCKER_BUILD -t "$COMPONENT-gateway:$TFS_IMAGE_TAG" -f ./src/"$COMPONENT"/gateway/Dockerfile . > "$BUILD_LOG"
        else
            $DOCKER_BUILD -t "$COMPONENT:$TFS_IMAGE_TAG" -f ./src/"$COMPONENT"/Dockerfile . > "$BUILD_LOG"
        fi

        echo "  Pushing Docker image to '$TFS_REGISTRY_IMAGES'..."

        if [ "$COMPONENT" == "pathcomp" ]; then
            IMAGE_URL=$(echo "$TFS_REGISTRY_IMAGES/$COMPONENT-frontend:$TFS_IMAGE_TAG" | sed 's,//,/,g' | sed 's,http:/,,g')

            TAG_LOG="$TMP_LOGS_FOLDER/tag_${COMPONENT}-frontend.log"
            docker tag "$COMPONENT-frontend:$TFS_IMAGE_TAG" "$IMAGE_URL" > "$TAG_LOG"

            PUSH_LOG="$TMP_LOGS_FOLDER/push_${COMPONENT}-frontend.log"
            docker push "$IMAGE_URL" > "$PUSH_LOG"

            IMAGE_URL=$(echo "$TFS_REGISTRY_IMAGES/$COMPONENT-backend:$TFS_IMAGE_TAG" | sed 's,//,/,g' | sed 's,http:/,,g')

            TAG_LOG="$TMP_LOGS_FOLDER/tag_${COMPONENT}-backend.log"
            docker tag "$COMPONENT-backend:$TFS_IMAGE_TAG" "$IMAGE_URL" > "$TAG_LOG"

            PUSH_LOG="$TMP_LOGS_FOLDER/push_${COMPONENT}-backend.log"
            docker push "$IMAGE_URL" > "$PUSH_LOG"
        elif [ "$COMPONENT" == "dlt" ]; then
            IMAGE_URL=$(echo "$TFS_REGISTRY_IMAGES/$COMPONENT-connector:$TFS_IMAGE_TAG" | sed 's,//,/,g' | sed 's,http:/,,g')

            TAG_LOG="$TMP_LOGS_FOLDER/tag_${COMPONENT}-connector.log"
            docker tag "$COMPONENT-connector:$TFS_IMAGE_TAG" "$IMAGE_URL" > "$TAG_LOG"

            PUSH_LOG="$TMP_LOGS_FOLDER/push_${COMPONENT}-connector.log"
            docker push "$IMAGE_URL" > "$PUSH_LOG"

            IMAGE_URL=$(echo "$TFS_REGISTRY_IMAGES/$COMPONENT-gateway:$TFS_IMAGE_TAG" | sed 's,//,/,g' | sed 's,http:/,,g')

            TAG_LOG="$TMP_LOGS_FOLDER/tag_${COMPONENT}-gateway.log"
            docker tag "$COMPONENT-gateway:$TFS_IMAGE_TAG" "$IMAGE_URL" > "$TAG_LOG"

            PUSH_LOG="$TMP_LOGS_FOLDER/push_${COMPONENT}-gateway.log"
            docker push "$IMAGE_URL" > "$PUSH_LOG"
        else
            IMAGE_URL=$(echo "$TFS_REGISTRY_IMAGES/$COMPONENT:$TFS_IMAGE_TAG" | sed 's,//,/,g' | sed 's,http:/,,g')

            TAG_LOG="$TMP_LOGS_FOLDER/tag_${COMPONENT}.log"
            docker tag "$COMPONENT:$TFS_IMAGE_TAG" "$IMAGE_URL" > "$TAG_LOG"

            PUSH_LOG="$TMP_LOGS_FOLDER/push_${COMPONENT}.log"
            docker push "$IMAGE_URL" > "$PUSH_LOG"
        fi
    fi

    echo "  Adapting '$COMPONENT' manifest file..."
    MANIFEST="$TMP_MANIFESTS_FOLDER/${COMPONENT}service.yaml"
    # cp ./manifests/"${COMPONENT}"service.yaml "$MANIFEST"
    cat ./manifests/"${COMPONENT}"service.yaml | linkerd inject - --proxy-cpu-request "10m" --proxy-cpu-limit "1" --proxy-memory-request "64Mi" --proxy-memory-limit "256Mi" > "$MANIFEST"

    if [ "$COMPONENT" == "pathcomp" ]; then
        IMAGE_URL=$(echo "$TFS_REGISTRY_IMAGES/$COMPONENT-frontend:$TFS_IMAGE_TAG" | sed 's,//,/,g' | sed 's,http:/,,g')
        VERSION=$(grep -i "${GITLAB_REPO_URL}/${COMPONENT}-frontend:" "$MANIFEST" | cut -d ":" -f4)
        sed -E -i "s#image: $GITLAB_REPO_URL/$COMPONENT-frontend:${VERSION}#image: $IMAGE_URL#g" "$MANIFEST"

        IMAGE_URL=$(echo "$TFS_REGISTRY_IMAGES/$COMPONENT-backend:$TFS_IMAGE_TAG" | sed 's,//,/,g' | sed 's,http:/,,g')
        VERSION=$(grep -i "${GITLAB_REPO_URL}/${COMPONENT}-backend:" "$MANIFEST" | cut -d ":" -f4)
        sed -E -i "s#image: $GITLAB_REPO_URL/$COMPONENT-backend:${VERSION}#image: $IMAGE_URL#g" "$MANIFEST"
    elif [ "$COMPONENT" == "dlt" ]; then
        IMAGE_URL=$(echo "$TFS_REGISTRY_IMAGES/$COMPONENT-connector:$TFS_IMAGE_TAG" | sed 's,//,/,g' | sed 's,http:/,,g')
        VERSION=$(grep -i "${GITLAB_REPO_URL}/${COMPONENT}-connector:" "$MANIFEST" | cut -d ":" -f4)
        sed -E -i "s#image: $GITLAB_REPO_URL/$COMPONENT-connector:${VERSION}#image: $IMAGE_URL#g" "$MANIFEST"

        IMAGE_URL=$(echo "$TFS_REGISTRY_IMAGES/$COMPONENT-gateway:$TFS_IMAGE_TAG" | sed 's,//,/,g' | sed 's,http:/,,g')
        VERSION=$(grep -i "${GITLAB_REPO_URL}/${COMPONENT}-gateway:" "$MANIFEST" | cut -d ":" -f4)
        sed -E -i "s#image: $GITLAB_REPO_URL/$COMPONENT-gateway:${VERSION}#image: $IMAGE_URL#g" "$MANIFEST"
    else
        if [ "$TFS_SKIP_BUILD" != "YES" ]; then
            IMAGE_URL=$(echo "$TFS_REGISTRY_IMAGES/$COMPONENT:$TFS_IMAGE_TAG" | sed 's,//,/,g' | sed 's,http:/,,g')
            VERSION=$(grep -i "${GITLAB_REPO_URL}/${COMPONENT}:" "$MANIFEST" | cut -d ":" -f4)
        else
            VERSION=$(grep -i "${GITLAB_REPO_URL}/${COMPONENT}:" "$MANIFEST" | cut -d ":" -f4)
            IMAGE_URL=$(echo "$TFS_REGISTRY_IMAGES/$COMPONENT:$VERSION" | sed 's,//,/,g' | sed 's,http:/,,g')
        fi
        sed -E -i "s#image: $GITLAB_REPO_URL/$COMPONENT:${VERSION}#image: $IMAGE_URL#g" "$MANIFEST"
    fi

    sed -E -i "s#imagePullPolicy: .*#imagePullPolicy: Always#g" "$MANIFEST"

    # TODO: harmonize names of the monitoring component

    echo "  Deploying '$COMPONENT' component to Kubernetes..."
    DEPLOY_LOG="$TMP_LOGS_FOLDER/deploy_${COMPONENT}.log"
    kubectl --namespace $TFS_K8S_NAMESPACE apply -f "$MANIFEST" > "$DEPLOY_LOG"
    COMPONENT_OBJNAME=$(echo "${COMPONENT}" | sed "s/\_/-/")
    #kubectl --namespace $TFS_K8S_NAMESPACE scale deployment --replicas=0 ${COMPONENT_OBJNAME}service >> "$DEPLOY_LOG"
    #kubectl --namespace $TFS_K8S_NAMESPACE scale deployment --replicas=1 ${COMPONENT_OBJNAME}service >> "$DEPLOY_LOG"

    echo "  Collecting env-vars for '$COMPONENT' component..."

    SERVICE_DATA=$(kubectl get service ${COMPONENT_OBJNAME}service --namespace $TFS_K8S_NAMESPACE -o json)
    if [ -z "${SERVICE_DATA}" ]; then continue; fi

    # Env vars for service's host address
    SERVICE_HOST=$(echo ${SERVICE_DATA} | jq -r '.spec.clusterIP')
    if [ -z "${SERVICE_HOST}" ]; then continue; fi
    ENVVAR_HOST=$(echo "${COMPONENT}service_SERVICE_HOST" | tr '[:lower:]' '[:upper:]')
    echo "export ${ENVVAR_HOST}=${SERVICE_HOST}" >> $ENV_VARS_SCRIPT

    # Env vars for service's 'grpc' port (if any)
    SERVICE_PORT_GRPC=$(echo ${SERVICE_DATA} | jq -r '.spec.ports[] | select(.name=="grpc") | .port')
    if [ -n "${SERVICE_PORT_GRPC}" ]; then
        ENVVAR_PORT_GRPC=$(echo "${COMPONENT}service_SERVICE_PORT_GRPC" | tr '[:lower:]' '[:upper:]')
        echo "export ${ENVVAR_PORT_GRPC}=${SERVICE_PORT_GRPC}" >> $ENV_VARS_SCRIPT
    fi

    # Env vars for service's 'http' port (if any)
    SERVICE_PORT_HTTP=$(echo ${SERVICE_DATA} | jq -r '.spec.ports[] | select(.name=="http") | .port')
    if [ -n "${SERVICE_PORT_HTTP}" ]; then
        ENVVAR_PORT_HTTP=$(echo "${COMPONENT}service_SERVICE_PORT_HTTP" | tr '[:lower:]' '[:upper:]')
        echo "export ${ENVVAR_PORT_HTTP}=${SERVICE_PORT_HTTP}" >> $ENV_VARS_SCRIPT
    fi

    printf "\n"
done

echo "Deploying extra manifests..."
for EXTRA_MANIFEST in $TFS_EXTRA_MANIFESTS; do
    echo "Processing manifest '$EXTRA_MANIFEST'..."
    if [[ "$EXTRA_MANIFEST" == *"servicemonitor"* ]]; then
        if kubectl get namespace monitoring &> /dev/null; then
            echo ">>> Namespace monitoring is present, applying service monitors..."
            kubectl apply -f $EXTRA_MANIFEST
        else
            echo ">>> Namespace monitoring is NOT present, skipping service monitors..."
        fi
    else
        kubectl --namespace $TFS_K8S_NAMESPACE apply -f $EXTRA_MANIFEST
    fi
    printf "\n"
done
printf "\n"

for COMPONENT in $TFS_COMPONENTS; do
    echo "Waiting for '$COMPONENT' component..."
    COMPONENT_OBJNAME=$(echo "${COMPONENT}" | sed "s/\_/-/")
    kubectl wait --namespace $TFS_K8S_NAMESPACE \
        --for='condition=available' --timeout=90s deployment/${COMPONENT_OBJNAME}service
    WAIT_EXIT_CODE=$?
    if [[ $WAIT_EXIT_CODE != 0 ]]; then
        echo "  Failed to deploy '${COMPONENT}' component, exit code '${WAIT_EXIT_CODE}', exiting..."
        kubectl logs --namespace $TFS_K8S_NAMESPACE deployment/${COMPONENT_OBJNAME}service --all-containers=true
        exit $WAIT_EXIT_CODE
    fi
    printf "\n"
done