# docker101

Docker Introduction: <https://docs.microsoft.com/en-us/dotnet/architecture/microservices/container-docker-introduction>

## Getting a Docker Image

```bash
# See local images
docker images

# Pull an image of the ngsa-app from the GitHub registry
docker pull ghcr.io/retaildevcrews/ngsa-app:beta

# See the pulled image locally
docker images

# Tag the image to used a shortened name (ngsa-app:beta)
docker tag ghcr.io/retaildevcrews/ngsa-app:beta ngsa-app:beta

# View the tagged image which references a source image
docker images
```

## Running a Container

```bash
# See created containers
# -a - Show all containers (default shows just running)
docker ps -a

# Start a container with a running image
# -d - Detached
# --name - Naming the container
# --in-memory - Not a docker option. Passed in flag to the ngsa-app via Dockerfile entrypoint
docker run -d --name ngsa ngsa-app:beta --in-memory

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

# Fetch the logs of the container
docker logs ngsa
```

## Ports

```bash
# Remove the container because we can't expose ports on a running container
docker rm ngsa

# Force the removal of a running container
# -f - Force the removal of a running container
docker rm -f ngsa

# Verify the container was removed
docker ps -a

# Start a container with an exposed port
# -d - Detached
# --name - Naming the container
# --rm - Automatically remove container when stopped
# -p - Publish a container's port(s) to the host (HOST_PORT:CONTAINER_PORT)
# --in-memory - Not a docker option. Passed in flag to ngsa-app via image's ENTRYPOINT
docker run -d --name ngsa --rm -p 80:8080 ngsa-app:beta --in-memory

# Verify app on exposed port
http localhost:80/version
```

## Network

```bash
# Start a container
# -d - Detached
# --name - Naming the container
# --rm - Automatically remove container when stopped
# --entrypoint - Overwrites the image's default ENTRYPOINT which states the start of a command and tacks on the rest from docker run
docker run -d --name loderunner --rm --entrypoint sh ghcr.io/joheec/ngsa-lr:spark -c "sleep 999999d"

# Show networks
docker network ls

# Create a network
docker network create web

# Connect containers to the network
docker network connect web ngsa
docker network connect web loderunner

# Verify containers were added to network
docker network inspect web

# Execute LodeRunner load test on ngsa-app via network call
# -s - Not a docker option. Passed in flag to LodeRunner via image's ENTRYPOINT.
#      ngsa is the container on the network.
#      8080 is the port ngsa-app is listening on in the ngsa container.
# -f - Not a docker option. Passed in flag to LodeRunner via image's ENTRYPOINT
docker exec loderunner dotnet ../aspnetapp.dll -s http://ngsa:8080 -f benchmark.json

# Output should show load test "Failed: * Errors"
# benchmark.json file on the loderunner container needs to be updated
```

## Volumes

```bash
# Kill container
docker kill loderunner

# Verify container was removed when stopped
docker ps -a

# Run the container and mount the file we want to edit
# -d - Detached
# --name - Naming the container
# --rm - Automatically remove container when stopped
# --entrypoint - Overwrites the image's default ENTRYPOINT which states the start of a command and tacks on the rest from docker run
# --net - Connect a container to a network
# -v - Bind mount a volume
docker run -d --name loderunner --rm --entrypoint sh --net web -v $(pwd)/loderunner/benchmark.json:/app/TestFiles/benchmark.json ghcr.io/joheec/ngsa-lr:spark -c "sleep 999999d"

# Update the loderunner/benchmark.json in loderunner container
# Replace 'zzz' with 'api'

# Execute LodeRunner load test on ngsa-app with updated benchmark.json
docker exec loderunner dotnet ../aspnetapp.dll -s http://ngsa:8080 -f benchmark.json

# Output should no longer show "Failed: * Errors"
```

## Commit Image Layer

```bash
# Try running new container with image to see fixed load test
# -d - Detached
# --name - Naming the container
# --rm - Automatically remove container when stopped
# --entrypoint - Overwrites the image's default ENTRYPOINT which states the start of a command and tacks on the rest from docker run
# --net - Connect a container to a network
docker run -d --name loderunner-fix --rm --entrypoint sh --net web ghcr.io/joheec/ngsa-lr:spark -c "sleep 99999d"

# Try to execute fixed load test
docker exec loderunner-fix dotnet ../aspnetapp.dll -s http://ngsa:8080 -f benchmark.json

# benchmark.json only changed in container
# benchmark.json wasn't updated in image
# New containers from that image won't have the fix

# **NOTE**
# Can commit changes in a container to an image
# The commit operation will not include any data contained in volumes mounted inside the container
# In the loderunner container, the benchmark.json was mounted, and its changes cannot be commited
# Will make change directly in loderunner-fix container to commit change

# Open shell in container
# -i - Interactive. Keep STDIN open even if not attached
# -t - Allocate a pseudo-TTY
docker exec -it loderunner-fix sh

# Open file in container
vi benchmark.json

# Edit file in container
:%s/zzz/api/g

# Save file in container
:wq

# Leave the container
exit

# Verify successful load test
docker exec loderunner-fix dotnet ../aspnetapp.dll -s http://ngsa:8080 -f benchmark.json

# Commit container change to image
docker commit loderunner-fix ngsa-lr:sparkfix

# Verify new image
docker images

# Kill container to re-use name
docker kill loderunner-fix

# Run newly create image in container
# -d - Detached
# --name - Naming the container
# --rm - Automatically remove container when stopped
# --entrypoint - Overwrites the image's default ENTRYPOINT which states the start of a command and tacks on the rest from docker run
# --net - Connect a container to a network
docker run -d --name loderunner-fix --rm --entrypoint sh --net web ngsa-lr:sparkfix -c "sleep 99999d"

# Verify fixed load test
docker exec loderunner-fix dotnet ../aspnetapp.dll -s http://ngsa:8080 -f benchmark.json
```
