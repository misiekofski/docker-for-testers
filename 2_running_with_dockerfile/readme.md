## Run postgres locally

### Prerequisites:
* Installed and running Docker on Windows 10

### Excercises:

1. This time we are gonna learn about Dockerfile. Let's say we have already created scripts by developers (which will create database, tables and populates them with test data). We can automate this with Dockerfile.

2. As you see there is no create database this time, because we are gonna use Dockerfile to do this. Create new file with name: Dockerfile (no extension) and copy this:

```Dockerfile
FROM mysql
ENV MYSQL_DATABASE company
# Add the content of the sql-scripts/ directory to your image
# All scripts in docker-entrypoint-initdb.d/ are automatically
# executed during container startup
COPY ./sqls/ /docker-entrypoint-initdb.d/
```

3. When you are in console in folder with second excercise you can run command:

```posh
docker build -t pijsql .
```

4. And then you need to run it with

```posh
docker run -d -p 3306:3306 --name pijsql -e MYSQL_ROOT_PASSWORD=#tylkopiwo pijsql
```

5. If you haven't stopped and removed previous container, you will have conflict with ports number. You need to use commands:

```posh
docker stop test-mysql
docker rm test-mysql
```
5. Then we can again run MySQL Workbench and connect to check if data was actually created in DB.