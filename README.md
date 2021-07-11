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
# --in-memory - Not a docker option. Passed in flag to the ngsa-app via Dockerfile entrypoint
docker run -d --name ngsa --rm -p 80:8080 ngsa-app:beta --in-memory

# Verify app on exposed port
http localhost:80/version
```
