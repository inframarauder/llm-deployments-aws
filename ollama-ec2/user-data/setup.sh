#!/bin/bash

set -eux

# update packages
sudo apt-get update -y

# set hostname
sudo hostnamectl set-hostname "${hostname}"

# install docker
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
apt-cache policy docker-ce
sudo apt-get install docker-ce -y
sudo systemctl status docker

# add the ssh user to the docker group
sudo usermod -aG docker "${ssh_username}"

# check docker version installed - 
docker info

# pull ollama docker image
docker pull ollama/ollama

# run ollama image (cpu-only)
docker run -d -v ollama:/root/.ollama -p 1134:11434 --name ollama ollama/ollama

# pre-load all the required models on ollama
for i in ${pre_loaded_models};
do
    docker exec -t ollama ollama pull "$i"
done

# list all loaded models
docker exec -t ollama ollama list

# install nginx 
sudo apt-get install nginx -y

# SSL using certbot
sudo snap install --classic certbot
certbot certonly -n -m subhasisdas125@gmail.com --agree-tos --nginx -d ${ollama_domain}

# put nginx conf in required location
git clone https://gist.github.com/4f8c8b166137b3719621a84c4de67666.git nginx-gist
mv nginx-gist/ollama-nginx.conf /etc/nginx/sites-available/ollama-nginx.conf
sudo ln -s /etc/nginx/sites-available/ollama-nginx.conf /etc/nginx/sites-enabled/
 
# restart nginx
sudo systemctl reload nginx