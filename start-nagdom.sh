
sudo /usr/local/bin/docker-compose -f docker-compose.yml build -d
# start containers
sudo /usr/local/bin/docker-compose -f docker-compose.yml up -d

# udpate containers and install vim (if not installed)
containers=$(sudo docker ps -a | awk '{if(NR>1) print $NF}')
for container in $containers
do
    sudo docker exec -it $container /bin/sh -c "apt-get update -y && apt-get install vim -y"
done