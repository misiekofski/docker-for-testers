## Run angular app with volumes (files which are accessible on your hard disk)

1. This time we hook up our source code on windows into docker container. First check with `docker images` if you have node image downloaded. If not use `docker pull node`

2. Go into `/co-by-tu-wypic` folder and run docker command (-it means interactive console with /bin/bash)

```posh
docker run -it -p 8015:4200 -v %cd%:/var/www -w "/var/www" node /bin/bash
```

3. Then linux console is opened. We need to run one by one

```bash
npm install
npm install -g @angular/cli
ng serve --host 0.0.0.0
```