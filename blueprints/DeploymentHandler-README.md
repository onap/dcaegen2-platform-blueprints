## Deployment Handler Installation Blueprint
[`DeploymentHandler.yaml`](./DeploymentHandler.yaml) is a Cloudify blueprint that can be used to deploy an instance of the DCAE Deployment Handler (DH) as a Docker container in the DCAE Docker environment.

### Input parameters
Some deployment parameters can be controlled via inputs supplied to Cloudify at the time a deployment is created from the blueprint.
The table below describes the available input parameters.

Parameter|Description|Required?|Default
---------|-----------|---------|-------
`location_id`|Location where DH is to be deployed; should point to a central site|Yes|None
`docker_host_override`|Registered service name of the Docker host where DH should be deployed|Yes|`platform_dockerhost`
`deployment_handler_image`|Fully qualified name of the Docker image to use for DH|Yes|Current stable version of image
`application_config`|Application-specific configuration parameters (see below)|No|`{}`
`host_log_root`|root directory for logs in the Docker host file system|Yes|`/opt/onap/log`

### Application configuration
The DH has sensible defaults for its configuration.  The `application_config` input can be used to supply additional configuration information to override defaults and/or to set values for optional parameters.  The content of this input is a dictionary with parameter names as keys and parameter values as values. See the documentation for the DH for the available configuration parameters.

### Additional configuration
`DeploymentHandler.yaml` relies on the DCAE Docker plugin to carry out the actual deployment.  The plugin gathers information from the blueprint and the inputs and uses this information to make API calls to a Docker Engine running in the DCAE environment.

Certain aspects of Docker behavior are controlled through inputs to the plugin's `create` operation.  This includes mapping directories and files from the host file system into the Docker container's file system.  It is also possible to pass environment variables to the container.  The inputs to the `create` operation are specified inside the blueprint in the `interfaces` section of node definition for the deployment handler.

