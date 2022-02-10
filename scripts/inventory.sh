#!/bin/bash
# ================================================================================
# Copyright (c) 2020-2022 AT&T Intellectual Property. All rights reserved.
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
#
# Functions for uploading blueprints to DCAE inventory

# Inventory API endpoint
INVENTORY=https://inventory:8080/dcae-service-types
#INVENTORY=https://localhost:8080/dcae-service-types

# Default fixed values in service type definition
OWNER=dcaeorch
COMPONENT=dcae
APPLICATION=DCAE

function flatten {
  # Convert a blueprint file into a flattened, escaped string
  # that can stored into a DCAE inventory "service type"
  # $1: path to blueprint file to be flattened

  FLAT=$(sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/$/\\n/g' < $1 | tr -d '\n')
  echo "${FLAT}"
}

function create_service_type {
  # Create a DCAE service type object (JSON),
  # suitable for uploading to DCAE inventory.
  # Use the name of the blueprint file (minus
  # the .yaml suffix) as the type name.
  # Use date-time (to the minute) in numeric
  # form as the type version.
  # $1: path to blueprint file for the service type
  echo "
   {
    \"vnfTypes\": [],
    \"owner\": \"${OWNER}\",
    \"typeVersion\": $(date +%y%m%d%H),
    \"typeName\": \"$(basename $1 .yaml)\",
    \"component\": \"${COMPONENT}\",
    \"application\": \"${APPLICATION}\",
    \"blueprintTemplate\": \"$(flatten $1)\"
   }"
}

function upload_service_type {
  # Transform a blueprint into a DCAE service type
  # and upload to DCAE inventory
  # $1: path to the blueprint
  # $2: path to CA cert file (optional)
  if [ "$2" ]
  then
     TLSCURL="--cacert $2"
  fi
  create_service_type $1 | \
  curl  $TLSCURL -X POST -H "Content-Type: application/json" -d @- ${INVENTORY}
}
