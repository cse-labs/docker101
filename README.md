# Docker101

- Docker Introduction: <https://docs.microsoft.com/en-us/dotnet/architecture/microservices/container-docker-introduction>
- Docker 101 [video walk through](https://microsoft.sharepoint.com/:v:/t/MicrosoftSPARKRecordings-MSFTInternal/EWCyeqByVWBAt8wDvNZdV-UB0BvU5YVbKm0UHgdrUlI6dg?e=QbPck6) (Microsoft SPARK- MS Internal)

## Key Docker Concepts

- [Getting Docker Images](#getting-docker-images)
- [Running a Container](#running-a-container)
- [Publishing Ports](#publishing-ports)
- [Networks Between Containers](#networks-between-containers)
- [Shared Volumes](#shared-volumes)
- [Commit Image Layer](#commit-image-layer)
- [Dockerfile to Build Images](#dockerfile-to-build-images)

## Getting Docker Images

```bash
# See local images
docker images

# Pull an image of the ngsa-app from the GitHub registry
docker pull ghcr.io/retaildevcrews/ngsa-app:beta

# See the pulled image locally
docker images

# Tag the image to use a shortened name (ngsa-app:beta)
docker tag ghcr.io/retaildevcrews/ngsa-app:beta ngsa-app:beta

# Verify the tagged image references the source image
# by having the same image ID
docker images
```

## Running a Container

```bash
# See created containers
# -a - Show all containers (default shows just running)
docker ps -a

# Start a container with the ngsa-app:beta image
# --name - Naming the container
# -d - Detached
# --in-memory - Not a docker option. Passed in flag to the ngsa-app via Dockerfile entrypoint
docker run --name ngsa -d ngsa-app:beta --in-memory

# See running containers
docker ps

# See running containers
# --no-trunc - Don't truncate output to be able to see COMMAND
docker ps --no-trunc

# Run a command in the running container
# -i - Interactive. Keep STDIN open even if not attached
# -t - Allocate a pseudo-TTY
docker exec -it ngsa sh

# The prompt changed
# We are now "in" the docker container

# Run some commands in the container
ls -al

# Leave the container
exit

# Verify that the container is still running
docker ps

# Fetch the logs of the container
docker logs ngsa
```

## Publishing Ports

- Publish: The port is automatically exposed as well. The port is accessible from anywhere.
- Expose : The port is accessible internally by other Docker containers.
- Neither Published nor Exposed: The port is accessible from within the container.

```bash
# Remove the container because we can't expose or publish ports on a running container
docker rm ngsa

# Force the removal of a running container
# -f - Force the removal of a running container
docker rm -f ngsa

# Verify the container was removed
docker ps -a

# Start a container with a published port
# --name - Naming the container
# -d - Detached
# --rm - Automatically remove container when stopped
# -p - Publish a container's port(s) to the host (HOST_PORT:CONTAINER_PORT)
# --in-memory - Not a docker option. Passed in flag to ngsa-app via image's ENTRYPOINT
docker run --name ngsa -d --rm -p 80:8080 ngsa-app:beta --in-memory

# Verify app on published port
http localhost:80/version
```

## Networks Between Containers

```bash
# Start a container
# --name - Naming the container
# -d - Detached
# --rm - Automatically remove container when stopped
# --entrypoint - Overwrites the image's default ENTRYPOINT which states the start of a command and tacks on the rest from docker run
docker run --name webvalidate -d --rm --entrypoint sh ghcr.io/cse-labs/docker101-webv:bug -c "sleep 999999d"

# Verify the container is running
docker ps 

# Show networks
docker network ls

# Create a network
docker network create web

# Connect containers to the network
docker network connect web ngsa
docker network connect web webvalidate

# Verify containers were added to network
docker network inspect web

# Execute WebV load test on ngsa-app via network call
# -s - Not a docker option. Passed in flag to WebV via image's ENTRYPOINT.
#      ngsa is the container on the network.
#      8080 is the port ngsa-app is listening on in the ngsa container.
# -f - Not a docker option. Passed in flag to WebV via image's ENTRYPOINT
docker exec webvalidate dotnet ../webvalidate.dll -s http://ngsa:8080 -f benchmark.json

# Output should show that load tests failed via "Test Failed Errors *"
# benchmark.json file on the webvalidate container needs to be updated
```

## Shared Volumes

```bash
# Stop container
docker stop webvalidate

# Verify container was removed when stopped
docker ps -a

# Run the container and mount the file we want to edit
# --name - Naming the container
# -d - Detached
# --rm - Automatically remove container when stopped
# --entrypoint - Overwrites the image's default ENTRYPOINT which states the start of a command and tacks on the rest from docker run
# --net - Connect a container to a network
# -v - Bind mount a volume
docker run --name webvalidate -d --rm --entrypoint sh --net web -v $(pwd)/webvalidate/src/app/benchmark.json:/app/TestFiles/benchmark.json ghcr.io/cse-labs/docker101-webv:bug -c "sleep 999999d"

# Open webvalidate/src/app/benchmark.json
# Replace 'zzz' with 'api'
# This should also update the app/TestFiles/benchmark.json file in the webvalidate container
# because we mounted the file in a volume

# Execute WebV load test on ngsa-app with updated benchmark.json
docker exec webvalidate dotnet ../webvalidate.dll -s http://ngsa:8080 -f benchmark.json

# Output should no longer show "Test Failed Errors *"
```

> Data in mounted volumes cannot be committed to an image. This is useful for secrets, large amounts of data that do not need to be included in the image (data science), etc.

## Commit Image Layer

```bash
# Try running new container with image to see fixed load test
# --name - Naming the container
# -d - Detached
# --rm - Automatically remove container when stopped
# --entrypoint - Overwrites the image's default ENTRYPOINT which states the start of a command and tacks on the rest from docker run
# --net - Connect a container to a network
docker run --name webvalidate-fix -d --rm --entrypoint sh --net web ghcr.io/cse-labs/docker101-webv:bug -c "sleep 99999d"

# Try to execute fixed load test
docker exec webvalidate-fix dotnet ../webvalidate.dll -s http://ngsa:8080 -f benchmark.json

# benchmark.json only changed in the webvalidate container
# benchmark.json wasn't updated in the ghcr.io/cse-labs/docker101-webv:bug image
# New containers from that image won't have the fix

# **NOTE**
# Can commit changes in a container to an image
# The commit operation will not include any data contained in volumes mounted inside the container
# In the webvalidate container, the benchmark.json was mounted, and its changes cannot be commited
# Will make change directly in webvalidate-fix container to commit change

# Open shell in container
# -i - Interactive. Keep STDIN open even if not attached
# -t - Allocate a pseudo-TTY
docker exec -it webvalidate-fix sh

# Open file in container
vi benchmark.json

# Edit file in container
:%s/zzz/api/g

# Save file in container
:wq

# Leave the container
exit

# Verify successful load test
docker exec webvalidate-fix dotnet ../webvalidate.dll -s http://ngsa:8080 -f benchmark.json

# Commit container change to image
docker commit webvalidate-fix docker101-webv:fix

# Verify new image
docker images

# Stop container to re-use name
docker stop webvalidate-fix

# Run newly create image in container
# --name - Naming the container
# -d - Detached
# --rm - Automatically remove container when stopped
# --entrypoint - Overwrites the image's default ENTRYPOINT which states the start of a command and tacks on the rest from docker run
# --net - Connect a container to a network
docker run --name webvalidate-fix -d --rm --entrypoint sh --net web docker101-webv:fix -c "sleep 99999d"

# Verify fixed load test
docker exec webvalidate-fix dotnet ../webvalidate.dll -s http://ngsa:8080 -f benchmark.json
```

## Dockerfile to Build Images

```bash
# Make sure ./webvalidate/src/app/benchmark.json in Codespaces is update by replacing 'zzz' with 'api'

# Build image from Dockerfile
docker build ./webvalidate -t docker101-webv:dockerfile

# Verify new image
docker images

# Run newly create image in container
# -d - Detached
# --name - Naming the container
# --rm - Automatically remove container when stopped
# --entrypoint - Overwrites the image's default ENTRYPOINT which states the start of a command and tacks on the rest from docker run
# --net - Connect a container to a network
docker run -d --name webvalidate-dockerfile --rm --entrypoint sh --net web docker101-webv:dockerfile -c "sleep 99999d"

# Verify fixed load test
docker exec webvalidate-dockerfile dotnet ../webvalidate.dll -s http://ngsa:8080 -f benchmark.json --summary Tsv
```

## Notes

Volumes - virtual "discs" to store and share data

- persistent - shared between host and container
  - docker run -ti -v /Users/root/example:/shared-folder ubuntu bash
- ephemeral - sticks around while being used by container
  - docker run -ti -v /shared-data --name containerA ubuntu bash
  - docker run -ti --volumes-from containerA --name containerB ubuntu bash

docker system prune -a / docker system prune -f

- It often gets GBs of disk space back. Don't use if debugging big docker build as it will delete all of your cached build layers and you'll rebuild from scratch
- Remove all unused containers, networks, images (both dangling and unreferenced), and optionally, volumes.

Dockerfile Commands

- FROM - which image to download and start from
  - must be first command in dockerfile
  - multiple from commands means dockerfile produces more than one image
- MAINTAINER
- RUN - runs the command line, waits for finish, and saves result
- ADD - adds local files, add the contents of tar archives, and downloads from URLS
- ENV - sets environment variables and available during build in in resulting image
- ENTRYPOINT - start of command and tacks on rest of command from docker run
- CMD - specifies whole command
  - docker run command replaces CMD
- ENTRYPOINT + CMD - runs one after another
- Command syntax for ENTRYPOINT, RUN, and CMD
  - shell form: nano notes.txt
    - called surrounded by a shell, like bash
  - exec form: ["/bin/nano", "notes.txt"]
    - calls directly
    - slightly more efficient
- EXPOSE - exposes port to container
- VOLUME
  - shared volumes: VOLUME ["/host/path/" "/container/path/"]
  - ephemeral volumes: VOLUME ["/shared-data"]
- WORKDIR - sets directory for remainder of Dockerfile and resulting container when run
- USER - sets the user the container will run as

## Engineering Docs

- Team Working [Agreement](.github/WorkingAgreement.md)
- Team [Engineering Practices](.github/EngineeringPractices.md)
- CSE Engineering Fundamentals [Playbook](https://github.com/Microsoft/code-with-engineering-playbook)

## How to file issues and get help  

This project uses GitHub Issues to track bugs and feature requests. Please search the existing issues before filing new issues to avoid duplicates. For new issues, file your bug or feature request as a new issue.

For help and questions about using this project, please open a GitHub issue.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services.

Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).

Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.

Any use of third-party trademarks or logos are subject to those third-party's policies.
