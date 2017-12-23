# Brauereiwanderung

[![Join the chat at https://gitter.im/Brauereiwanderung/Lobby](https://badges.gitter.im/Brauereiwanderung/Lobby.svg)](https://gitter.im/Brauereiwanderung/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


```sh

wget http://download.geofabrik.de/europe/germany/bayern-latest.osm.bz2 ./data/osm-latest.osm.bz2

# Do manual preprocessing. Unfortunately this is necessary right now
docker run -t -v $(pwd)/data:/data osrm/osrm-backend osrm-extract -p /opt/car.lua /data/osm-latest.osm.pbf
docker run -t -v $(pwd)/data:/data osrm/osrm-backend osrm-partition /data/osm-latest.osrm
docker run -t -v $(pwd)/data:/data osrm/osrm-backend osrm-customize /data/osm-latest.osrm

docker network create osrm
docker-compose up osrm-backend
# osrm-frontend official image broken....

```