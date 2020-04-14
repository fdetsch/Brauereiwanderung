# Brauereiwanderung

[![Join the chat at https://gitter.im/Brauereiwanderung/Lobby](https://badges.gitter.im/Brauereiwanderung/Lobby.svg)](https://gitter.im/Brauereiwanderung/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


### Get Started

```sh
# download osm data of interest
wget http://download.geofabrik.de/europe/germany/bayern/oberfranken-latest.osm.pbf ./data/oberfranken-latest.osm.pbf

# retrieve latest docker image from github as images on [dockerhub](https://hub.docker.com/r/graphhopper/graphhopper/tags) are outdated
cd ../
git clone https://github.com/graphhopper/graphhopper.git
cd graphhopper
docker build -t graphhopper:master .

# run docker with custom settings
cd ../Brauereiwanderung
docker-compose up -d graphhopper
```

Then, open in browser

```sh
http://localhost:8989/route?point=49.89223%2C10.88484&point=49.89734%2C10.89281&points_encoded=false
```


### Troubleshooting

* On Linux, you possibly need admin rights (`sudo`) when receiving this error:

```sh
ERROR: Couldn't connect to Docker daemon at http+docker://localunixsocket - is it running?

If it's at a non-standard location, specify the URL with the DOCKER_HOST environment variable.
```


* On Windows, if encountering something like 

> status code not OK but 500: {"Message":"Unhandled exception: Drive has not been shared"}

make sure to check the required drive via Settings -> Resources -> File Sharing in Docker Desktop.


### Useful resources

* For those running Docker through Windows' subsystem for linux (WSU), you might want to follow this [Medium tutorial](https://medium.com/@sebagomez/installing-the-docker-client-on-ubuntus-windows-subsystem-for-linux-612b392a44c4).