#!/bin/bash

kubectl delete pods -n tfs $(kubectl get pods -n tfs --no-headers -o custom-columns=":metadata.name" | grep device)

sleep 80

source my_deploy.sh

export TFS_COMPONENTS="device"

GITLAB_REPO_URL="labs.etsi.org:5050/tfs/controller"
TMP_FOLDER="./tmp"

TMP_MANIFESTS_FOLDER="${TMP_FOLDER}/${TFS_K8S_NAMESPACE}/manifests"
TMP_LOGS_FOLDER="${TMP_FOLDER}/${TFS_K8S_NAMESPACE}/logs"

for COMPONENT in $TFS_COMPONENTS; do
    echo "Processing '$COMPONENT' component..."

    echo "  Adapting '$COMPONENT' manifest file..."
    MANIFEST="$TMP_MANIFESTS_FOLDER/${COMPONENT}service.yaml"
    # cp ./manifests/"${COMPONENT}"service.yaml "$MANIFEST"
    cat ./manifests/"${COMPONENT}"service.yaml | linkerd inject - --proxy-cpu-request "10m" --proxy-cpu-limit "1" --proxy-memory-request "64Mi" --proxy-memory-limit "256Mi" > "$MANIFEST"

    VERSION=$(grep -i "${GITLAB_REPO_URL}/${COMPONENT}:" "$MANIFEST" | cut -d ":" -f4)
    IMAGE_URL=$(echo "$TFS_REGISTRY_IMAGES/$COMPONENT:$VERSION" | sed 's,//,/,g' | sed 's,http:/,,g')
    sed -E -i "s#image: $GITLAB_REPO_URL/$COMPONENT:${VERSION}#image: $IMAGE_URL#g" "$MANIFEST"

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