#!/bin/bash
# ================================================================================
# Copyright (c) 2018-2021 AT&T Intellectual Property. All rights reserved.
# Copyright (c) 2021 J. F. Lucas. All rights reserved.
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

# Prior to the "H" release, this bootstrap script was used to deploy DCAE components
# during the initial DCAE installation process using Cloudify Manager with Cloudify
# blueprints.  Over the course of several releases, we have migrated these components to use Helm
# deployment, starting with the DCAE "platform components" and, in the "H" release, the 4
# DCAE microservices that are always launched when DCAE is deployed.
#
# For the "I" release, we are expecting to migrate all DCAE microservices to Helm deployment,
# including the microservices that are launched on demand after initial DCAE installation.
# We are continuing to provide support for Cloudify deployments during the "I" release.  This
# bootstrap script will deploy the Cloudify blueprint that initializes the Cloudify-based
# DCAE postgres instance and will upload all of the DCAE Cloudify blueprints to the DCAE
# inventory component.  The bootstrap container will continue to run after its deployment and
# upload work is complete.   User can "exec" into the bootstrap container and use the Cloudify
# "cfy" command to debug any issues related to Cloudify deployments.
#
# Expects:
#   CM address (IP or DNS) in CMADDR environment variable
#   CM password in CMPASS environment variable (assumes user is "admin")
#   Blueprints for components to be installed in /blueprints
#   Input files for components to be installed in /inputs
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
CACERT="/certs/cacert.pem"
CFYTLS=""
CURLTLS=""
if [ $CMPROTO = "https" ]
then
    CFYTLS="--rest-certificate $CACERT --ssl"
    CURLTLS="--cacert $CACERT"
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

### END FUNCTION DEFINTIONS ###

set -x

# Make sure we keep the container alive after an error
trap keep_running ERR

set -e

# Set up profile to access Cloudify Manager
cfy profiles use -u admin -t default_tenant -p "${CMPASS}" ${CFYTLS} "${CMADDR}"

# Output status, for debugging purposes
cfy status

# Store the CM password into a Cloudify secret
cfy secret create -s ${CMPASS} cmpass

# After this point, failures should not stop the script or block later commands
trap - ERR
set +e

# Initialize the DCAE postgres instance
deploy pgaas_initdb k8s-pgaas-initdb.yaml k8s-pgaas-initdb-inputs.yaml

# Display deployments, for debugging purposes
cfy deployments list

# Load blueprints into DCAE inventory as
# DCAE service types
. /scripts/inventory.sh
for BP in /blueprints/*.yaml
do
  upload_service_type $BP $CACERT
done

# Continue running
keep_running "Finished bootstrap steps."
echo "Exiting!"
