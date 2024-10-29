CHANGELOG
=========

1.3.4 (2024-10-29)

* Added environment variable: PULUMI_AGENT_DEBUG_POD to allow users to keep pod behind for troubleshooting and inspection
* Added support for workerServiceAccount to kubernetes application

1.3.3 (2024-10-15)

* Adding in PULUMI_ENV to workflow-runner

1.3.2 (2024-09-30)

* Updating pulumi-service for PULUMI_AGENT_SERVICE_ACCOUNT_NAME

1.3.1 (2024-09-20)

* Fix delay before polling next deployment after job completion

1.3.0 (2024-09-11)

* Support pulling executor images using docker config credstore configuration

1.2.2 (2024-08-30)

* Improve error handling in the agent

1.2.1 (2024-07-24)

* Add platform to User-Agent

1.2.0 (2024-07-22)

* Add Kubernetes-native deployment mode and installer

1.1.3 (2024-07-22)

* Update build settings to avoid dynamic linking errors on Alpine Linux

1.1.2 (2024-07-18)

* Publish docker images on release

1.1.1 (2024-07-03)

* Add new configuration to skip pulling images from the docker registry

1.1.0 (2024-05-15)

* Add support for OIDC token exchange

1.0.2 (2024-03-13)

* Basic Kubernetes support

1.0.0 (2024-01-31)

* GA release
