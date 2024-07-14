#!/bin/sh
#echo "WARNING, I AM USING BAREMETAL NODE"
#echo "hit a key"
#read a

curl -s https://raw.githubusercontent.com/joelapatatechaude/common-scripts/main/OCP-Demo/1.create-ocp-clusters.sh | bash -s -- "$@"
