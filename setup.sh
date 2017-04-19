# run on aws box
sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo curl -L "https://github.com/docker/compose/releases/download/1.12.0/docker-compose-$(uname -s)-$(uname -m)" | sudo tee /usr/local/bin/docker-compose > /dev/null
sudo chmod +x /usr/local/bin/docker-compose
sudo yum install git-all

echo "alias ls='ls -lah --color'" >> ~/.bashrc
echo "alias l='ls'" >> ~/.bashrc

# # checkout container repo
git clone --depth 1 --branch dev https://github.com/cbittencourt/Nagdom.git
cd Nagdom
chmod +x setup.sh

# build containers
# docker-compose -f docker-compose.yml build
# start containers
sudo /usr/local/bin/docker-compose -f docker-compose.yml up -d

containers=$(sudo docker ps -a | awk '{if(NR>1) print $NF}')
for container in $containers
do
    docker exec -it $container /bin/sh -c "apt-get update -y && apt-get install vim -y"
done