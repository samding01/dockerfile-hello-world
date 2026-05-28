!/bin/bash

# Enable Kubedock
export KUBEDOCK_ENABLED=true
echo "KUBEDOCK_ENABLED=$KUBEDOCK_ENABLED"

# Run entrypoint script
#/entry.sh
if [[ "${KUBEDOCK_ENABLED:-false}" == "true" ]]; then
    echo
    echo "Kubedock is enabled (env variable KUBEDOCK_ENABLED is set to true)."

    SECONDS=0
    KUBEDOCK_TIMEOUT=${KUBEDOCK_TIMEOUT:-10}
    until [ -f $KUBECONFIG ]; do
        if (( SECONDS > KUBEDOCK_TIMEOUT )); then
            break
        fi
        echo "Kubeconfig doesn't exist yet. Waiting..."
        sleep 1
    done

    if [ -f $KUBECONFIG ]; then
      echo "Kubeconfig found."

      KUBEDOCK_PARAMS=${KUBEDOCK_PARAMS:-"--reverse-proxy --kubeconfig $KUBECONFIG"}

      echo "Starting kubedock with params \"${KUBEDOCK_PARAMS}\"..."

      kubedock server ${KUBEDOCK_PARAMS} > /tmp/kubedock.log 2>&1 &

      echo "Done."

      echo "Replacing podman with podman-wrapper.sh..."

      ln -f -s /usr/bin/podman-wrapper.sh /home/tooling/.local/bin/podman

      export TESTCONTAINERS_RYUK_DISABLED="true"
      export TESTCONTAINERS_CHECKS_DISABLE="true"

      echo "Done."
      echo
    else
        echo "Could not find Kubeconfig at $KUBECONFIG"
        echo "Giving up..."
    fi
else
    echo
    echo "Kubedock is disabled. It can be enabled with the env variable \"KUBEDOCK_ENABLED=true\""
    echo "set in the workspace Devfile or in a Kubernetes ConfigMap in the developer namespace."
    echo
    ln -f -s /usr/bin/podman.orig /home/tooling/.local/bin/podman
fi

# Navigate to the project source directory
cd "$PROJECT_SOURCE"

# Create Dockerfile
cat <<EOF > Dockerfile.$(uname -m)
FROM scratch
COPY hello /
CMD ["/hello"]
EOF

echo "Dockerfile created"

# Create hello.go file
cat <<EOF > hello.go
package main
import "fmt"
func main() {
    fmt.Println("hello world")
}
EOF

echo "Go source file created"

# Compile hello.go
go build hello.go

if [ $? -eq 0 ]; then
    echo "Go file compiled successfully"
else
    echo "Error compiling Go file"
    exit 1
fi


# Enable Kubedock
KUBEDOCK_ENABLED="true"
/entrypoint.sh

export USER=$(oc whoami)
export TKN=$(oc whoami -t)
export REG="10.0.158.178:5000"
export PROJECT=$(oc project -q)
export IMG="${REG}/${PROJECT}/hello"

 podman login --tls-verify=false --username ${USER} --password ${TKN} ${REG}
 podman build -t ${IMG} -f Dockerfile* .
 podman push --tls-verify=false ${IMG}
 podman run --rm ${IMG}
