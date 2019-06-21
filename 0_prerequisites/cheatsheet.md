## Docker cheatsheet
Those commands work propery on git bash or powershell. Do not use simple windows terminal.


Kill all containers: `docker stop $(docker ps -a -q)`
 
Remove all containers: `docker rm $(docker ps -a -q)`

Remove all images: `docker rmi $(docker images -q)`

Remove all unused stuff (beware!): `docker system prune`


- `docker create` creates a container but does not start it.
- `docker rename` allows the container to be renamed.
- `docker run` creates and starts a container in one operation.
- `docker rm` deletes a container.
- `docker update` updates a container's resource limits.