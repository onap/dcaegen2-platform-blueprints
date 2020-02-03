# DCAE Bootstrap Container
This container is responsible for loading plugins and wagons onto the
DCAE Cloudify Manager instance and for launching DCAE components.

The Docker image build process loads plugins and blueprints into the
image's file system.   At run time, the main script in the container
(`bootstrap.sh`) uploads the plugins to Cloudify Manager, then installs
components using the blueprints.

The container expects to be started with two environment variables:
  - `CMADDR` -- the address of the target Cloudify Manager
  - `CMPASS` -- the password for Cloudify Manager

The container expects input files to use when deploying the blueprints.
It expects to find them in /inputs.   The normal method for launching
the container is via a Helm Chart launched by OOM.  That chart creates
a Kubernetes ConfigMap containing the input files.  The ConfigMap is
mounted as a volume at /inputs.

