This is docker course for testers, and contains everything you need to set up your local environment and start testing application.

## Course content

0. [Prerequisites before you start this course](../master/0_prerequisites/README.md)   
1. [Running swagger-editor](../master/1_running_swagger/README.md)
2. [Running and configuring databases in docker](../master/2_running_mysql_in_docker/readme.md)   
3. [Running with Dockerfile](../master/3_using_dockerfile/readme.md)
4. [Running dotnet application](../master/4_running_dotnet_app/readme.md)
5. [Docker volumes with Angular application](../master/5_running_angular_app/readme.md)
6. [Communication between containers](../master/6_automating_previous_job/README.md)
7. [docker-compose](../master/7_docker-compose/README.md)


## Docker cheatsheet
Those commands work propery on git bash or powershell. Do not use simple windows terminal.

## Tips and tricks
- Kill all containers: `docker stop $(docker ps -a -q)`
- Remove all containers (force kills all containers even running): `docker rm -f $(docker ps -a -q)`
- Remove all images: `docker rmi $(docker images -q)`
- Remove all unused stuff (beware!): `docker system prune`
- Delete stopped containers `docker rm -v $(docker ps -a -q -f status=exited)`
- First stop then delete containers: `docker stop $(docker ps -aq) && docker rm -v $(docker ps -aq)`


## Start and stop
- `docker create` creates a container but does not start it.
- `docker rename` allows the container to be renamed.
- `docker run` creates and starts a container in one operation.
- `docker rm` deletes a container.
- `docker update` updates a container's resource limits.

## Information
- `docker ps` shows running containers.
- `docker logs` gets logs from container. (You can use a custom log driver, but logs is only available for json-file and journald in 1.10).
- `docker inspect` looks at all the info on a container (including IP address).
- `docker port` shows public facing port of container.
- `docker top` shows running processes in container.
- `docker stats` shows containers' resource usage statistics.
- `docker ps -a` shows running and stopped containers.
- `docker stats --all` shows a list of all containers, default shows just running.

## Executing command
- `docker exec`

## Images
- `docker images` shows all images
- `docker build` builds image from Dockerfile
- `docker rmi` removes image



Author: Michal Dobrzycki
License: MIT