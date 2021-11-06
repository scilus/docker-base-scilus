# docker-base-scilus
Base container containing dependencies that do not frequently change for SCIL flows.

Build commands:

Before build the Docker: `sudo docker image rm docker-base-scilus:latest`

To build the Docker: `sudo docker build . -t "docker-base-scilus:latest"`

Dependencies versions:

* FSL: 5.0.9-5~nd16.04+1
* ANTs: v2.3.1
* MRtrix: 3.0_RC3
