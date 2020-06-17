#!/bin/bash
# ================================================================================
# Copyright (c) 2018 AT&T Intellectual Property. All rights reserved.
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

# Clean up DCAE during ONAP uninstall

set -x
set +e

# TLS setup
CACERT="/certs/cacert.pem"
CURLTLS=""
if [ $CMPROTO = "https" ]
then
    CURLTLS="--cacert $CACERT"
fi

# Uninstall components managed by Cloudify
# Get the list of deployment ids known to Cloudify via curl to Cloudify API.
# The output of the curl is JSON that looks like {"items" :[{"id": "config_binding_service"}, ...], "metadata" :{...}}
#
# jq gives us the just the deployment ids (e.g., "config_binding_service"), one per line
#
# xargs -I lets us run the cfy uninstall command once for each deployment id extracted by jq
curl -Ss --user admin:$CMPASS -H "Tenant: default_tenant" ${CURLTLS} "$CMPROTO://$CMADDR:$CMPORT/api/v3.1/deployments?_include=id" \
| /bin/jq .items[].id \
| xargs -I % sh -c 'cfy uninstall %'

# Delete blueprints (in case the uninstall didn't get them)
curl -Ss --user admin:$CMPASS -H "Tenant: default_tenant" ${CURLTLS} "$CMPROTO://$CMADDR:$CMPORT/api/v3.1/blueprints?_include=id" \
| /bin/jq .items[].id \
| xargs -I % sh -c 'cfy blueprints delete %'

# Delete plugins
curl -Ss --user admin:$CMPASS -H "Tenant: default_tenant" ${CURLTLS} "$CMPROTO://$CMADDR:$CMPORT/api/v3.1/plugins?_include=id" \
| /bin/jq .items[].id \
| xargs -I % sh -c 'cfy plugins delete %'
