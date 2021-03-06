## Run mysql locally

### Prerequisites:

- MySQL Workbench, HeidiSQL or other SQL client

### Excercises:

1. After installing docker, run command which will download image of mysql and run container with this image:

```ps
docker run --name=test-mysql mysql
```

    It will pull mysql server (it will take some time) and tries to run it in docker.
    It will also show you error message:

    error: database is uninitialized and password option is not specified
    You need to specify one of MYSQL_ROOT_PASSWORD, MYSQL_ALLOW_EMPTY_PASSWORD and MYSQL_RANDOM_ROOT_PASSWORD

2. As you see you need to set some passwords, or allow mysql to run without password. Seems like a good idea, right? Shall we proceed with setting environment variables?

```ps
docker run --name=test-mysql --env="MYSQL_ROOT_PASSWORD=mypassword" mysql
```

    Oops, another error. We tried to run another container with the same name as container already running.

3. We need to delete container and running it again with password set by running two commands:

- -env is for environmental variable, which sets up mysql root password (which we use later to login to database)

```ps
docker rm test-mysql
docker run --name some-mysql -e MYSQL_ROOT_PASSWORD=mypassword mysql --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
```

    And now we are stucked in terminal. We need to go out by pressing ctrl-c (in Windows 10).

4. We're out of inside terminal, but the docker is still running. You can check it by running

```ps
docker ps
```

5. Then you can learn more about this container by running:

```ps
docker logs test-mysql
docker inspect test-mysql
```

6. Now we need to stop container and delete it to get our name back

```ps
docker stop test-mysql
docker rm test-mysql
```

7. And now to run it properly you should use `docker run -p <host_port>:<container_port>`:

```ps
 docker run -p 3306:3306 --name=test-mysql -e MYSQL_ROOT_PASSWORD=mypassword -d mysql
```

- -d is for detached run (that means run it and leave the docker image back to console)
- -p is for mapping ports (as docker has it's own network we need to map ports).

If you do this without mapping ports you won't be able to connect to localhost (and would need to find docker IP which on windows 10 will be: 10.0.75.2 - but then root must login from localhost because mysql demands it by default)

8.  Now you can open MySQL Workbench or HeidiSQL and try connect to database:

        host: localhost
        user: root
        password: mypassword
        port: 3306 (default)

9.  You should have access to root, and you can now run as many queries as you want. Some of examples you can see below:

```mysql
CREATE DATABASE psingwiny;

USE psingwiny;

CREATE TABLE psingwin (
    PsingwinID INT AUTO_INCREMENT PRIMARY KEY,
    firstname VARCHAR(200),
    color VARCHAR(50),
    version DOUBLE
);

INSERT INTO psingwin (firstname, color, version)
VALUES ('Pinky', 'Psingwin','21.37');
```

10. You can now stop container by it's name - check if connection is not available (server is down) and run it again (and the data is still there!)

```
docker stop test-mysql
docker start test-mysql
```

`docker rm test-mysql` would delete data though (because of the volumes which we will cover in next chapters)

11. Optional: you also can login to bash shell of container using this command:

```ps
docker exec -it test-mysql /bin/bash
```
