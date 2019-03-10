## Run dotnet application

1. We need to create Docker file (this will be one Dockerfile but with two dockers). First we need to create docker which build our application. Create Dockerfile inside `/code` subfolder.

```Dockerfile
# We will name our build docker containter as "build-env"
FROM microsoft/dotnet:sdk AS build-env
WORKDIR /app

# Copy csproj and restore as distinct layers
COPY *.csproj ./
RUN dotnet restore

# Copy everything else and build
COPY . ./
RUN dotnet publish -c Release -o out
```

2. Then we can copy builded project to out another container (we will copy just binaries, without source code).

```Dockerfile
# Build runtime image
FROM microsoft/dotnet:aspnetcore-runtime
WORKDIR /app
COPY --from=build-env /app/out .
ENTRYPOINT ["dotnet", "myWebApp.dll"]
```

3. Then we will build it from the start

```posh
docker build -t mywebapp .
```

4. And run it

```posh
docker run -d -p 8080:80 --name pijakapp mywebapp
```