# ============LICENSE_START=======================================================
# org.onap.dcae
# ================================================================================
# Copyright (c) 2018-2020 AT&T Intellectual Property. All rights reserved.
# Copyright (c) 2021 J. F. Lucas.  All rights reserved.
# ================================================================================
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============LICENSE_END=========================================================

# cloudify CLI requires python 3.6
# won't work with 3.7 or later, hence won't work
# with the ONAP integration-python base images
FROM python:3.6-alpine
LABEL maintainer="ONAP DCAE Team"
LABEL Description="DCAE bootstrap image"

ARG user=onap
ARG group=onap

# Install packages needed for cloudify and for running bootstrap script
RUN apk --no-cache add build-base libffi-dev openssl-dev curl bash

# Install jq
RUN curl -Ssf -L "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64"  > /bin/jq \
&& chmod +x /bin/jq

# Install rust (needed for "cryptography", needed for "cloudify"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /rustinstall \
&& chmod +x /rustinstall \
&& /rustinstall -y

# Install pip and Cloudify CLI
RUN source /root/.cargo/env \
&& pip install --upgrade pip \
&& pip install cloudify==5.1.1

# Copy scripts
RUN mkdir scripts
COPY scripts/ /scripts

# Load blueprints and input templates
COPY blueprints/  /blueprints

# Set up runtime script
ENTRYPOINT exec "/scripts/bootstrap.sh"

# Make scripts executable & set up a non-root user
RUN chmod +x /scripts/*.sh \
  && mkdir -p /opt/bootstrap \
  && addgroup -S $group \
  && adduser -S -D -h /opt/bootstrap -s /bin/bash $user $group \
  && chown -R $user:$group /opt/bootstrap \
  && chown -R $user:$group /scripts \
  && chown -R $user:$group /blueprints

USER $user
