# Brauereiwanderung

[![Join the chat at https://gitter.im/Brauereiwanderung/Lobby](https://badges.gitter.im/Brauereiwanderung/Lobby.svg)](https://gitter.im/Brauereiwanderung/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

```sh
wget http://download.geofabrik.de/europe/germany/bayern/oberfranken-latest.osm.pbf ./data/oberfranken-latest.osm.pbf

docker-compose up graphhopper
```

Open in browser
```sh
http://localhost:11111/route?point=49.89223%2C10.88484&point=49.89734%2C10.89281&vehicle=hike&points_encoded=false
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
