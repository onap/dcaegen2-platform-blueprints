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
# Load DCAE blueprints/inputs onto container
# $1 Blueprint repo base URL
# Expect blueprints to be at <base URL>/blueprints

set -x
set -e

BLUEPRINTS=\
"
k8s-holmes-engine.yaml \
k8s-holmes-rules.yaml \
k8s-pgaas-initdb.yaml \
k8s-tca.yaml \
k8s-ves.yaml \
k8s-prh.yaml \
k8s-hv-ves.yaml \
k8s-helm-override.yaml \
k8s-helm.yaml
"

BPDEST=blueprints
mkdir ${BPDEST}

# Download blueprints
for bp in ${BLUEPRINTS}
do
    curl -Ssf $1/blueprints/${bp} > ${BPDEST}/$(basename ${bp})
done
