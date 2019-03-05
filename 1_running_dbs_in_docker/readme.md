## Run databases locally

1. After installing docker, run command: 

```posh
docker run --name=test-mysql mysql
```

    It will pull mysql server (it will take some time) and tries to run it in docker. 
    It will also show you error message:
        
    error: database is uninitialized and password option is not specified
    You need to specify one of MYSQL_ROOT_PASSWORD, MYSQL_ALLOW_EMPTY_PASSWORD and MYSQL_RANDOM_ROOT_PASSWORD

2. As you see you need to set some passwords, or allow mysql to run without password. Seems like a good idea, right? Shall we proceed with setting environment variables?

```posh
docker run --name=test-mysql --env="MYSQL_ROOT_PASSWORD=mypassword" mysql
```

    Oops, another error. We tried to run another container with the same name as container already running.

3. We need to delete container and running it again with password set by running two commands:

```posh
docker rm test-mysql
docker run --name=test-mysql --env="MYSQL_ROOT_PASSWORD=mypassword" mysql
```

    And now we are stucked in terminal. We need to go out by pressing ctrl-c (in Windows 10).

4. We're out of inside terminal, but the docker is still running. You can check it by running
```posh
docker ps
```

5. Then you can learn more about this container by running:
```posh
docker logs test-mysql
docker inspect test-mysql
```

6. Now you can open MySQL Workbench or HeidiSQL and connect to database:

    host: 10.0.75.2 - on Windows 10
    user: root
    password: mypassword
    port: 3306 (default)