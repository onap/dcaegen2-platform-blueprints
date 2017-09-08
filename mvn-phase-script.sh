#!/bin/bash

# ================================================================================
# Copyright (c) 2017 AT&T Intellectual Property. All rights reserved.
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
# ECOMP is a trademark and service mark of AT&T Intellectual Property.


echo "running script: [$0] for module [$1] at stage [$2]"

MVN_PROJECT_MODULEID="$1"
MVN_PHASE="$2"


FQDN="${MVN_PROJECT_GROUPID}.${MVN_PROJECT_ARTIFACTID}"
if [ "$MVN_PROJECT_MODULEID" == "__" ]; then
  MVN_PROJECT_MODULEID=""
fi

if [[ "$MVN_PROJECT_VERSION" == *SNAPSHOT ]]; then
  echo "=> for SNAPSHOT artifact build"
  MVN_DEPLOYMENT_TYPE='SNAPSHOT'
else
  echo "=> for STAGING/RELEASE artifact build"
  MVN_DEPLOYMENT_TYPE='STAGING'
fi
echo "MVN_DEPLOYMENT_TYPE is             [$DEPLOYMENT_TYPE]"


TIMESTAMP=$(date +%C%y%m%dT%H%M%S)

# expected environment variables
if [ -z "${MVN_NEXUSPROXY}" ]; then
    echo "MVN_NEXUSPROXY environment variable not set.  Cannot proceed"
    exit
fi

MVN_NEXUSPROXY_HOST=$(echo "$MVN_NEXUSPROXY" |cut -f3 -d'/' | cut -f1 -d':')
echo "=> Nexus Proxy at $MVN_NEXUSPROXY_HOST, $MVN_NEXUSPROXY"

if [ -z "$WORKSPACE" ]; then
    WORKSPACE=$(pwd)
fi

# mvn phase in life cycle
MVN_PHASE="$2"


echo "MVN_PROJECT_MODULEID is            [$MVN_PROJECT_MODULEID]"
echo "MVN_PHASE is                       [$MVN_PHASE]"
echo "MVN_PROJECT_GROUPID is             [$MVN_PROJECT_GROUPID]"
echo "MVN_PROJECT_ARTIFACTID is          [$MVN_PROJECT_ARTIFACTID]"
echo "MVN_PROJECT_VERSION is             [$MVN_PROJECT_VERSION]"
echo "MVN_NEXUSPROXY is                  [$MVN_NEXUSPROXY]"
echo "MVN_RAWREPO_BASEURL_UPLOAD is      [$MVN_RAWREPO_BASEURL_UPLOAD]"
echo "MVN_RAWREPO_BASEURL_DOWNLOAD is    [$MVN_RAWREPO_BASEURL_DOWNLOAD]"
MVN_RAWREPO_HOST=$(echo "$MVN_RAWREPO_BASEURL_UPLOAD" | cut -f3 -d'/' |cut -f1 -d':')
echo "MVN_RAWREPO_HOST is                [$MVN_RAWREPO_HOST]"
echo "MVN_RAWREPO_SERVERID is            [$MVN_RAWREPO_SERVERID]"
echo "MVN_DOCKERREGISTRY_DAILY is        [$MVN_DOCKERREGISTRY_DAILY]"
echo "MVN_DOCKERREGISTRY_RELEASE is      [$MVN_DOCKERREGISTRY_RELEASE]"

expand_templates() 
{
  # set up env variables, get ready for template resolution
  export ONAPTEMPLATE_RAWREPOURL_org_onap_ccsdk_platform_plugins_releases="$MVN_RAWREPO_BASEURL_DOWNLOAD/org.onap.ccsdk.plugins/releases"
  export ONAPTEMPLATE_RAWREPOURL_org_onap_ccsdk_platform_plugins_snapshots="$MVN_RAWREPO_BASEURL_DOWNLOAD/org.onap.ccsdk.plugins/snapshots"
  export ONAPTEMPLATE_RAWREPOURL_org_onap_ccsdk_platform_blueprints_releases="$MVN_RAWREPO_BASEURL_DOWNLOAD/org.onap.ccsdk.blueprints/releases"
  export ONAPTEMPLATE_RAWREPOURL_org_onap_ccsdk_platform_blueprints_snapshots="$MVN_RAWREPO_BASEURL_DOWNLOAD/org.onap.ccsdk.blueprints/snapshots"  export ONAPTEMPLATE_RAWREPOURL_org_onap_dcaegen2_releases="$MVN_RAWREPO_BASEURL_DOWNLOAD/org.onap.dcaegen2/releases"
  export ONAPTEMPLATE_RAWREPOURL_org_onap_dcaegen2_snapshots="$MVN_RAWREPO_BASEURL_DOWNLOAD/org.onap.dcaegen2/snapshots"  export ONAPTEMPLATE_RAWREPOURL_org_onap_dcaegen2_platform_plugins_releases="$MVN_RAWREPO_BASEURL_DOWNLOAD/org.onap.dcaegen2.platform.plugins/releases"
  export ONAPTEMPLATE_RAWREPOURL_org_onap_dcaegen2_platform_plugins_snapshots="$MVN_RAWREPO_BASEURL_DOWNLOAD/org.onap.dcaegen2.platform.plugins/snapshots"
  export ONAPTEMPLATE_RAWREPOURL_org_onap_dcaegen2_platform_blueprints_releases="$MVN_RAWREPO_BASEURL_DOWNLOAD/org.onap.dcaegen2.platform.blueprints/releases"
  export ONAPTEMPLATE_RAWREPOURL_org_onap_dcaegen2_platform_blueprints_snapshots="$MVN_RAWREPO_BASEURL_DOWNLOAD/org.onap.dcaegen2.platform.blueprints/snapshots"

  export ONAPTEMPLATE_PYPIURL_org_onap_dcaegen2="${MVN_NEXUSPROXY}/content/sites/pypi"

  export ONAPTEMPLATE_DOCKERREGURL_org_onap_dcaegen2_releases="$MVN_DOCKERREGISTRY_DAILY"
  export ONAPTEMPLATE_DOCKERREGURL_org_onap_dcaegen2_snapshots="$MVN_DOCKERREGISTRY_DAILY/snapshots"


  TEMPLATES=$(env |grep ONAPTEMPLATE)
  echo "====> Resolving the following temaplate from environment variables "
  echo "[$TEMPLATES]"
  SELFFILE=$(echo "$0" | rev | cut -f1 -d '/' | rev)
  for TEMPLATE in $TEMPLATES; do
    KEY=$(echo "$TEMPLATE" | cut -f1 -d'=')
    VALUE=$(echo "$TEMPLATE" | cut -f2 -d'=')
    VALUE2=$(echo "$TEMPLATE" | cut -f2 -d'=' |sed 's/\//\\\//g')
    FILES=$(grep -rl "$KEY")

    # assuming FILES is not longer than 2M bytes, the limit for variable value max size on this VM
    for F in $FILES; do
       if [[ $F == *"$SELFFILE" ]]; then
          continue
       fi
       echo "======> Resolving template $KEY to value $VALUE for file $F"
       sed -i "s/{{[[:space:]]*$KEY[[:space:]]*}}/$VALUE2/g" "$F"

       #cat "$F"
    done

    #if [ ! -z "$FILES" ]; then
    #   echo "====> Resolving template $VALUE to value $VALUE"
    #   #CMD="grep -rl \"$VALUE\" | tr '\n' '\0' | xargs -0 sed -i \"s/{{[[:space:]]*$VALUE[[:space:]]*}}/$VALUE/g\""
    #   grep -rl "$KEY" | tr '\n' '\0' | xargs -0 sed -i 's/$KEY/$VALUE2/g'
    #   #echo $CMD
    #   #eval $CMD
    #fi
  done
  echo "====> Done template reolving"
}


run_tox_test() 
{ 
  set -x
  CURDIR=$(pwd)
  TOXINIS=$(find . -name "tox.ini")
  for TOXINI in "${TOXINIS[@]}"; do
    DIR=$(echo "$TOXINI" | rev | cut -f2- -d'/' | rev)
    cd "${CURDIR}/${DIR}"
    rm -rf ./venv-tox ./.tox
    virtualenv ./venv-tox
    source ./venv-tox/bin/activate
    pip install --upgrade pip
    pip install --upgrade tox argparse
    pip freeze
    tox
    deactivate
    rm -rf ./venv-tox ./.tox
  done
}

build_wagons() 
{
  rm -rf ./*.wgn venv-pkg

  SETUPFILES=$(find . -name "setup.py")
  for SETUPFILE in $SETUPFILES; do
    PLUGIN_DIR=$(echo "$SETUPFILE" |rev | cut -f 2- -d '/' |rev)
    PLUGIN_NAME=$(grep 'name' "$SETUPFILE" | cut -f2 -d'=' | sed 's/[^0-9a-zA-Z\.]*//g')
    PLUGIN_VERSION=$(grep 'version' "$SETUPFILE" | cut -f2 -d'=' | sed 's/[^0-9\.]*//g')

    echo "In $PLUGIN_DIR, $PLUGIN_NAME, $PLUGIN_VERSION"

    virtualenv ./venv-pkg
    source ./venv-pkg/bin/activate
    pip install --upgrade pip
    pip install wagon
    wagon create --format tar.gz "$PLUGIN_DIR"
    deactivate
    rm -rf venv-pkg

    PKG_FILE_NAMES=( "${PLUGIN_NAME}-${PLUGIN_VERSION}"*.wgn )
    echo Built package: "${PKG_FILE_NAMES[@]}"
  done
}


upload_raw_file() 
{
  # Extract the username and password to the nexus repo from the settings file
  USER=$(xpath -q -e "//servers/server[id='$MVN_RAWREPO_SERVERID']/username/text()" "$SETTINGS_FILE")
  PASS=$(xpath -q -e "//servers/server[id='$MVN_RAWREPO_SERVERID']/password/text()" "$SETTINGS_FILE")
  NETRC=$(mktemp)
  echo "machine $MVN_RAWREPO_HOST login $USER password $PASS" > "$NETRC"

  REPO="$MVN_RAWREPO_BASEURL_UPLOAD"

  OUTPUT_FILE=$1
  EXT=$(echo "$OUTPUT_FILE" | rev |cut -f1 -d '.' |rev)
  if [ "$EXT" == 'yaml' ]; then
    OUTPUT_FILE_TYPE='text/x-yaml'
  elif [ "$EXT" == 'gz' ]; then
    OUTPUT_FILE_TYPE='application/gzip'
  elif [ "$EXT" == 'wgn' ]; then
    OUTPUT_FILE_TYPE='application/gzip'
  else
    OUTPUT_FILE_TYPE='application/octet-stream'
  fi


  if [ "$MVN_DEPLOYMENT_TYPE" == 'SNAPSHOT' ]; then
    SEND_TO="${REPO}/${FQDN}/snapshots"
  elif [ "$MVN_DEPLOYMENT_TYPE" == 'STAGING' ]; then
    SEND_TO="${REPO}/${FQDN}/releases"
  else
    echo "Unreconfnized deployment type, quit"
    exit
  fi

  echo "Sending ${OUTPUT_FILE} to Nexus: ${SEND_TO}"
  curl -vkn --netrc-file "${NETRC}" --upload-file "${OUTPUT_FILE}" -X PUT -H "Content-Type: $OUTPUT_FILE_TYPE" "${SEND_TO}/${OUTPUT_FILE}-${MVN_PROJECT_VERSION}-${TIMESTAMP}"
  curl -vkn --netrc-file "${NETRC}" --upload-file "${OUTPUT_FILE}" -X PUT -H "Content-Type: $OUTPUT_FILE_TYPE" "${SEND_TO}/${OUTPUT_FILE}-${MVN_PROJECT_VERSION}"
  curl -vkn --netrc-file "${NETRC}" --upload-file "${OUTPUT_FILE}" -X PUT -H "Content-Type: $OUTPUT_FILE_TYPE" "${SEND_TO}/${OUTPUT_FILE}"
}



upload_wagons_and_type_yamls()
{
  WAGONS=$(ls -1 ./*.wgn)
  for WAGON in "${WAGONS[@]}" ; do
    WAGON_NAME=$(echo "$WAGON" | cut -f1 -d '-')
    WAGON_VERSION=$(echo "$WAGON" | cut -f2 -d '-')
    WAGON_TYPEFILE=$(grep -rl "$WAGON_NAME" | grep yaml | head -1)
   
    upload_raw_file "$WAGON"
    upload_raw_file "$WAGON_TYPEFILE"
  done
}



build_and_push_docker()
{
  IMAGENAME="onap/${FQDN}.${MVN_PROJECT_MODULEID}"
  IMAGENAME=$(echo "$IMAGENAME" | sed -e 's/_*$//g' -e 's/\.*$//g')

  # use the major and minor version of the MVN artifact version as docker image version
  VERSION="${MVN_PROJECT_VERSION//[^0-9.]/}"
  VERSION2=$(echo "$VERSION" | cut -f1-2 -d'.')

  LFQI="${IMAGENAME}:${VERSION}-${TIMESTAMP}"
  BUILD_PATH="${WORKSPACE}"
  # build a docker image
  docker build --rm -f "${WORKSPACE}"/Dockerfile -t "${LFQI}" "${BUILD_PATH}"

  REPO=""
  if [ $MVN_DEPLOYMENT_TYPE == "SNAPSHOT" ]; then
     REPO=$MVN_DOCKERREGISTRY_DAILY
  elif [ $MVN_DEPLOYMENT_TYPE == "STAGING" ]; then
     # there seems to be no staging docker registry?  set to use SNAPSHOT also
     #REPO=$MVN_DOCKERREGISTRY_RELEASE
     REPO=$MVN_DOCKERREGISTRY_DAILY
  else
     echo "Fail to determine DEPLOYMENT_TYPE"
     REPO=$MVN_DOCKERREGISTRY_DAILY
  fi
  echo "DEPLOYMENT_TYPE is: $MVN_DEPLOYMENT_TYPE, repo is $REPO"

  if [ ! -z "$REPO" ]; then
    USER=$(xpath -e "//servers/server[id='$REPO']/username/text()" "$SETTINGS_FILE")
    PASS=$(xpath -e "//servers/server[id='$REPO']/password/text()" "$SETTINGS_FILE")
    if [ -z "$USER" ]; then
      echo "Error: no user provided"
    fi
    if [ -z "$PASS" ]; then
      echo "Error: no password provided"
    fi
    [ -z "$PASS" ] && PASS_PROVIDED="<empty>" || PASS_PROVIDED="<password>"
    echo docker login "$REPO" -u "$USER" -p "$PASS_PROVIDED"
    docker login "$REPO" -u "$USER" -p "$PASS"

    if [ $MVN_DEPLOYMENT_TYPE == "SNAPSHOT" ]; then
      REPO="$REPO/snapshots"
    elif [ $MVN_DEPLOYMENT_TYPE == "STAGING" ]; then
      # there seems to be no staging docker registry?  set to use SNAPSHOT also
      #REPO=$MVN_DOCKERREGISTRY_RELEASE
      REPO="$REPO"
    else
      echo "Fail to determine DEPLOYMENT_TYPE"
      REPO="$REPO/unknown"
    fi

    OLDTAG="${LFQI}"
    PUSHTAGS="${REPO}/${IMAGENAME}:${VERSION2}-${TIMESTAMP} ${REPO}/${IMAGENAME}:${VERSION2} ${REPO}/${IMAGENAME}:${VERSION2}-latest"
    for NEWTAG in ${PUSHTAGS}
    do
      echo "tagging ${OLDTAG} to ${NEWTAG}"
      docker tag "${OLDTAG}" "${NEWTAG}"
      echo "pushing ${NEWTAG}"
      docker push "${NEWTAG}"
      OLDTAG="${NEWTAG}"
    done
  fi

}





case $MVN_PHASE in
clean)
  echo "==> clean phase script"
  rm -rf ./venv-* ./*.wgn
  ;;
generate-sources)
  echo "==> generate-sources phase script"
  expand_templates
  ;;
compile)
  echo "==> compile phase script"
  ;;
test)
  echo "==> test phase script"
  run_tox_test
  ;;
package)
  echo "==> package phase script"
  build_wagons
  ;;
install)
  echo "==> install phase script"
  ;;
deploy)
  echo "==> deploy phase script"
  upload_wagons_and_type_yamls
  ;;
*)
  echo "==> unprocessed phase"
  ;;
esac

