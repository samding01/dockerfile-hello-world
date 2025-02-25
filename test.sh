!/bin/bash

# Enable Kubedock
export KUBEDOCK_ENABLED=true
echo "KUBEDOCK_ENABLED=$KUBEDOCK_ENABLED"

# Run entrypoint script
/entrypoint.sh

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
