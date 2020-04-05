## TARGETS

A target is basically a landing zone infrastructure for a deployment. It can have one or many stages (but typically will be a single stage) and almost always has more than one team's deployments. This folder should contain multiple target environments. 

For each environment the following files should exist:

- <target>.env - Applied to all deployments for target environment
- <target>.<team>.env - Applied for specific team's deployment into target environment

Additionally, there are cloud specific variables which may be loaded as well:

- cloud.<cloud>.env
