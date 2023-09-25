#!/bin/bash -ex

# docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo bash get-docker.sh
sudo usermod -aG docker admin

# aws-cli
sudo apt install -y python3-pip
sudo pip3 install --upgrade awscli
