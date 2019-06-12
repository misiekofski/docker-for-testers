## docker run command

`docker run` basically downloads image and run it as a container
We will cover `-d -p HOST_PORT:DOCKER_PORT` later in the next chapter.

1. Run your container with:
```ps
docker run -d -p 81:8080 swaggerapi/swagger-editor
```
and go to localhost:81 - yay it works! underneath docker ran few commands

2. You can check running containers by using command:
`docker ps`

3. Now you can inspect the docker container (xx are the first two letters of CONTAINER ID)
```ps
docker inspect xx
```
You should see IPAdress somewhere at the bottom. That's IP of docker internal network.

4. Try to access it via IP:PORT. You probably won't be able to. That's because Docker creates different network.
It should be something like: http://172.17.0.2:8080/

5. Once we create route table between networks, we should be able to access it:
Run cmd as admin, and paste this command.
```ps
route /P add 172.17.0.0 MASK 255.255.0.0 10.0.75.2
```

5. Now you can access it, and read more about docker run command
[docker run](https://docs.docker.com/engine/reference/commandline/run/)