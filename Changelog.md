# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [3.2.0] - 2021-06-04
         - [DCAEGEN2-2617](https://jira.onap.org/browse/DCAEGEN2-2617) - Remove DCAE service component deployment from bootstrap container
         - [DCAEGEN2-2750](https://jira.onap.org/browse/DCAEGEN2-2750) - Update Dmaap plugin version to 1.5.1

## [3.1.0] - 2021-04-16
         - [DCAEGEN2-2420](https://jira.onap.org/browse/DCAEGEN2-2420) - PRH 1.6.0, PM-Mapper 1.6.0 and TCA-Gen2 1.3.0 integration base image alignemnt
         - [DCAEGEN2-2732](https://jira.onap.org/browse/DCAEGEN2-2732) - PM-Mapper 1.6.0 Utilize SDK/Dmaap client
         - [DCAEGEN2-2675](https://jira.onap.org/browse/DCAEGEN2-2675) - RESTConf 1.2.5 - xml parsing vulnerability
         - [DCAEGEN2-2590](https://jira.onap.org/browse/DCAEGEN2-2590) - TCA-Gen2 1.3.0 - vulnerability removal
         - [DCAEGEN2-2713](https://jira.onap.org/browse/DCAEGEN2-2713) - PMSH 1.3.1 - policy config consolidation under app-config
         - [DCAEGEN2-2420](https://jira.onap.org/browse/DCAEGEN2-2420) - Heartbeat MS 2.2.0 - py39 support + integration base image alignment

## [3.0.4] - 2021-03-10
         - [DCAEGEN2-2656](https://jira.onap.org/browse/DCAEGEN2-2656) - fix CRITICAL weak-cryptography issues identified in sonarcloud (hostname verification in DFC)
         - [DCAEGEN2-2659](https://jira.onap.org/browse/DCAEGEN2-2659) - PM-Mapper blueprint updated to 1.5.2 version (implement singleton cache for events being processed)
         - [DCAEGEN2-2700](https://jira.onap.org/browse/DCAEGEN2-2700) - Disable Holmes deployment from bootstrap & container revision on blueprint

## [3.0.3] - 2021-02-18
### Changed
         - [DCAEGEN2-2509](https://jira.onap.org/browse/DCAEGEN2-2509) - Avoid removal of data when insufficient PM data samples are present
         - [DCAEGEN2-2540](https://jira.onap.org/browse/DCAEGEN2-2540) - Slice-analysis-ms and Policy integration issue fixes
	 - [DCAEGEN2-2496](https://jira.onap.org/browse/DCAEGEN2-2496) - SNMPTrap collector blueprint updated to use ContainerizedServiceComponent and latest k8s plugin
	 - [DCAEGEN2-2496](https://jira.onap.org/browse/DCAEGEN2-2496) - DL feeder and DL-Admin blueprint updated to use ContainerizedServiceComponent and latest k8s plugin
	 - [DCAEGEN2-2600](https://jira.onap.org/browse/DCAEGEN2-2600) - PM-Mapper blueprint updated to 1.5.1 version (added files processing config and fixed vulnerabilities)
	 - [DCAEGEN2-2477](https://jira.onap.org/browse/DCAEGEN2-2477) - Updated Ves image version to 1.8.0 in ves blueprint (Ves validates IP addresses)
         - [DCAEGEN2-2585](https://jira.onap.org/browse/DCAEGEN2-2585) - Add new Kpi-Computation-ms
         - [DCAEGEN2-2536](https://jira.onap.org/browse/DCAEGEN2-2536) - Add JWT support in HTTP/HTTPS based locations
         - [DCAEGEN2-2599](https://jira.onap.org/browse/DCAEGEN2-2599) - Vulnerability removal for son-handler
         - [DCAEGEN2-2623](https://jira.onap.org/browse/DCAEGEN2-2623) - Add new fields to Slice-analysis-ms blueprint (AAI update)
         - [DCAEGEN2-2494](https://jira.onap.org/browse/DCAEGEN2-2494) - SNMPtrap collector version revision (pysnmp upgrade)
         - [DCAEGEN2-2551](https://jira.onap.org/browse/DCAEGEN2-2551) - Vulnerability removal for RESTConf collector


## [3.0.2] - 2021-02-15
### Changed
         - [DCAEGEN2-2628](https://jira.onap.org/browse/DCAEGEN2-2628) - Fix docker image build problem
         - [DCAEGEN2-2528](https://jira.onap.org/browse/DCAEGEN2-2528) - Add HTTPS as new protocol to collect files from xNFs

## [3.0.1] - 11/02/2021
### Changed
	 - [DCAEGEN2-2537](https://jira.onap.org/browse/DCAEGEN2-2537) - Upgrade prh.prh-app-server to 1.5.5
	 - [DCAEGEN2-2493](https://jira.onap.org/browse/DCAEGEN2-2493) - RCC blueprint updated to use latest k8s plugin & 1.2.3 version (vulnerability fixes)
	 - [DCAEGEN2-2496](https://jira.onap.org/browse/DCAEGEN2-2496) - VES-Mapper blueprint updated to 1.2.0 version (vulnerability fixes)
	 - [DCAEGEN2-2496](https://jira.onap.org/browse/DCAEGEN2-2496) - VES-Mapper blueprint updated to 1.2.0 version (vulnerability fixes)
