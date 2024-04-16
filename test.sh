# Enable Kubedock
KUBEDOCK_ENABLED="true"
/entrypoint.sh

export USER=$(oc whoami)
export TKN=$(oc whoami -t)
export REG="image-registry.openshift-image-registry.svc:5000"
export PROJECT=$(oc project -q)
export IMG="${REG}/${PROJECT}/hello"

$ podman login --tls-verify=false --username ${USER} --password ${TKN} ${REG}
Login Succeeded!
$ podman build -t ${IMG} .
(...)
$ podman push --tls-verify=false ${IMG}
(...)
$ podman run --rm ${IMG}
Hello from Kubedock!
(...)
