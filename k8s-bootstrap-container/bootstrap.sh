#!/bin/bash
# ================================================================================
# Copyright (c) 2018-2020 AT&T Intellectual Property. All rights reserved.
# ================================================================================
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============LICENSE_END=========================================================

# Install DCAE via Cloudify Manager
# Expects:
#   CM address (IP or DNS) in CMADDR environment variable
#   CM password in CMPASS environment variable (assumes user is "admin")
#   ONAP common Kubernetes namespace in ONAP_NAMESPACE environment variable
#   If DCAE components are deployed in a separate Kubernetes namespace, that namespace in DCAE_NAMESPACE variable.
#   Consul address with port in CONSUL variable
#   Plugin wagon files in /wagons
# 	Blueprints for components to be installed in /blueprints
#   Input files for components to be installed in /inputs
#   Configuration JSON files that need to be loaded into Consul in /dcae-configs
#   Consul is installed in /opt/consul/bin/consul, with base config in /opt/consul/config/00consul.json
# Optionally, allows:
#   CM protocol in CMPROTO environment variable (defaults to HTTP)
#   CM port in CMPORT environment variable (defaults to 80)
# If CMPROTO is set to "https", bootstrap will use HTTPS to communicate with CM.  Otherwise,
# it will use HTTP.
# If CMPROTO is set to "https", the script assumes the CA cert needed to verify the cert
# presented by CM is mounted at /certs/cacert.pem.

# Set defaults for CM protocol and port
CMPROTO=${CMPROTO:-http}
CMPORT=${CMPORT:-80}

# Set up additional parameters for using HTTPS
CFYTLS=""
CURLTLS=""
if [ $CMPROTO = "https" ]
then
    CFYTLS="--rest-certificate /certs/cacert.pem --ssl"
    CURLTLS="--cacert /certs/cacert.pem"
fi

### FUNCTION DEFINITIONS ###

# keep_running: Keep running after bootstrap finishes or after error
keep_running() {
    echo $1
    sleep infinity &
    wait
}

# cm_hasany: Query Cloudify Manager and return 0 (true) if there are any entities matching the query
# Used to see if something is already present on CM
# $1 -- query fragment, for instance "plugins?archive_name=xyz.wgn" to get
#  the number of plugins that came from the archive file "xyz.wgn"
function cm_hasany {
    # We use _include=id to limit the amount of data the CM sends back
    # We rely on the "metadata.pagination.total" field in the response
    # for the total number of matching entities
    COUNT=$(curl -Ss -H "Tenant: default_tenant" --user admin:${CMPASS} ${CURLTLS} "${CMPROTO}://${CMADDR}:${CMPORT}/api/v3.1/$1&_include=id" \
             | /bin/jq .metadata.pagination.total)
    if (( $COUNT > 0 ))
    then
        return 0
    else
        return 1
    fi
}

# deploy: Deploy components if they're not already deployed
# $1 -- name (for bp and deployment)
# $2 -- blueprint file name
# $3 -- inputs file name (optional)
function deploy {
    # Don't crash the script on error
    set +e

    # Upload blueprint if it's not already there
    if cm_hasany "blueprints?id=$1"
    then
        echo blueprint $1 is already installed on ${CMADDR}
    else
        cfy blueprints upload -b $1  /blueprints/$2
    fi

    # Create deployment if it doesn't already exist
    if cm_hasany "deployments?id=$1"
    then
       echo deployment $1 has already been created on ${CMADDR}
    else
        INPUTS=
        if [ -n "$3" ]
        then
            INPUTS="-i/inputs/$3"
        fi
        cfy deployments create -b $1 ${INPUTS} $1
    fi

    # Run the install workflow if it hasn't been run already
    # We don't have a completely certain way of determining this.
    # We check to see if the deployment has any node instances
    # that are in the 'uninitialized' or 'deleted' states.  (Note that
    # the & in the query acts as a logical OR for the multiple state values.)
    # We'll try to install when a deployment has node instances in those states
    if cm_hasany "node-instances?deployment_id=$1&state=uninitialized&state=deleted"
    then
        cfy executions start -d $1 install
    else
        echo deployment $1 appears to have had an install workflow executed already or is not ready for an install
    fi
}

# Install plugin if it's not already installed
# $1 -- path to wagon file for plugin
function install_plugin {
    ARCHIVE=$(basename $1)
    # See if it's already installed
    if cm_hasany "plugins?archive_name=$ARCHIVE"
    then
        echo plugin $1 already installed on ${CMADDR}
    else
        cfy plugin upload $1
    fi
}

### END FUNCTION DEFINTIONS ###

set -x

# Make sure we keep the container alive after an error
trap keep_running ERR

set -e

# Consul service registration data
CBS_REG='{"ID": "dcae-cbs0", "Name": "config_binding_service", "Address": "config-binding-service", "Port": 10000}'

# Set up profile to access Cloudify Manager
cfy profiles use -u admin -t default_tenant -p "${CMPASS}" ${CFYTLS} "${CMADDR}"

# Output status, for debugging purposes
cfy status

# Check Consul readiness
# The readiness container waits for a "consul-server" container to be ready,
# but this isn't always enough.  We need the Consul API to be up and for
# the cluster to be formed, otherwise our Consul accesses might fail.
# (Note in ONAP R2, we never saw a problem, but occasionally in R3 we
# have seen Consul not be fully ready, so we add these checks, originally
# used in the R1 HEAT-based deployment.)
# Wait for Consul API to come up
until curl http://${CONSUL}/v1/agent/services
do
    echo Waiting for Consul API
    sleep 60
done
# Wait for a leader to be elected
until [[ "$(curl -Ss http://{$CONSUL}/v1/status/leader)" != '""' ]]
do
    echo Waiting for leader
    sleep 30
done

# Load configurations into Consul KV store
for config in /dcae-configs/*.json
do
    # The basename of the file is the Consul key
    key=$(basename ${config} .json)
    # Strip out comments, empty lines
    egrep -v "^#|^$" ${config} > /tmp/dcae-upload
    curl -v -X PUT -H "Content-Type: application/json" --data-binary @/tmp/dcae-upload ${CONSUL}/v1/kv/${key}
done

# Put service registrations into the local Consul configuration directory
for sr in CBS_REG
do
  echo '{"service" : ' ${!sr}  ' }'> /opt/consul/config/${sr}.json
done

# Start the local consul agent instance
/opt/consul/bin/consul agent --config-dir /opt/consul/config 2>&1 | tee /opt/consul/consul.log &

# Store the CM password into a Cloudify secret
cfy secret create -s ${CMPASS} cmpass

# Load plugins onto CM
for wagon in /wagons/*.wgn
do
    install_plugin ${wagon}
done

# In some oversubscribed cloud environments, we have
# observed that even though the plugin installations appear
# to have completed, there are background installation tasks
# that might still be running.  So we check for running system workflows
while cm_hasany "executions?is_system_workflow=true&status=pending&status=started&status=queued&status=scheduled"
do
    echo "Waiting for running system workflows to complete"
    sleep 15
done

# After this point, failures should not stop the script or block later commands
trap - ERR
set +e

# Initialize the DCAE postgres instance
deploy pgaas_initdb k8s-pgaas-initdb.yaml k8s-pgaas-initdb-inputs.yaml

# Deploy service components
# tca, ves, prh, hv-ves, datafile-collector can be deployed simultaneously
deploy tca k8s-tca.yaml k8s-tca-inputs.yaml &
deploy ves k8s-ves.yaml k8s-ves-inputs.yaml &
deploy prh k8s-prh.yaml k8s-prh-inputs.yaml &
deploy hv-ves k8s-hv-ves.yaml k8s-hv_ves-inputs.yaml &
# holmes_rules must be deployed before holmes_engine, but holmes_rules can go in parallel with other service components
deploy holmes_rules k8s-holmes-rules.yaml k8s-holmes_rules-inputs.yaml
deploy holmes_engine k8s-holmes-engine.yaml k8s-holmes_engine-inputs.yaml

# Display deployments, for debugging purposes
cfy deployments list

# Continue running
keep_running "Finished bootstrap steps."
echo "Exiting!"
