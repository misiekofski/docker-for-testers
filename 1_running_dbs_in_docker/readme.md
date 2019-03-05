## Run databases locally

1. After installing docker, run command: `docker run --name=test-mysql mysql`

        It will pull mysql server (it will take some time) and tries to run it in docker. It will also show you error message:
        
        error: database is uninitialized and password option is not specified
        You need to specify one of MYSQL_ROOT_PASSWORD, MYSQL_ALLOW_EMPTY_PASSWORD and MYSQL_RANDOM_ROOT_PASSWORD

2. 