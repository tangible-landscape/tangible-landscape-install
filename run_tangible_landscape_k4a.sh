#!/bin/bash

# Runs the docker container to start tangible landscape

cd ~/tangible-landscape-install
sudo xhost +local:docker && sudo docker compose up --build k4a
