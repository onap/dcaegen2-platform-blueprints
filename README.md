# DCAE Blueprints and Bootstrap Container
This repository holds the source code needed to build the
Docker image for the DCAE bootstrap container.  The bootstrap
container runs at DCAE deployment time (via a Helm chart) and
does initial setup of the DCAE environment.  This includes
deploying several service components using Cloudify Manager.

This repository also holds Cloudify blueprints for service components.
The Docker build process copies these blueprints into the Docker image
for the bootstrap container.

_Note: Prior to the Frankfurt release (R6), this repository held blueprint templates
for components deployed using Cloudify Manager.   The build process for this
repository expanded the templates and pushed them to the Nexus raw
repository.  The DCAE bootstrap container was hosted in the `dcaegen2.deployments` repository.
The Docker build process for the bootstrap containter image pulled the blueprints it needed from the Nexus raw repository._

## DCAE Bootstrap Container
This container is responsible for loading blueprints onto the
DCAE Cloudify Manager instance and for launching DCAE components.

The Docker image build process loads  blueprints into the
image's file system.   The blueprints are copied from the `blueprints` directory in this repository.
At run time, the main script in the container
(`bootstrap.sh`) installs
components using the blueprints.

The container expects to be started with two environment variables:
  - `CMADDR` -- the address of the target Cloudify Manager
  - `CMPASS` -- the password for Cloudify Manager

The container expects input files to use when deploying the blueprints.
It expects to find them in /inputs.   The normal method for launching
the container is via a Helm Chart launched by OOM.  That chart creates
a Kubernetes ConfigMap containing the input files.  The ConfigMap is
mounted as a volume at /inputs.

