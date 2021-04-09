#!/usr/bin/env bash
sudo docker build -f src/qawolfdockerfile ./src -t qabuild:latest --no-cache
sudo docker-compose -f docker-compose-e2e.yml up -d
sudo docker exec -it qawolf /usr/app/e2e.sh