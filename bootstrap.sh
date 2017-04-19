#waiting for yum to be ready
#TODO: use 'wait' instead
sleep 60
#installing updates, docker, docker-compose, and git
sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user #allowing ec2-user to run docker without sudo
sudo curl -L "https://github.com/docker/compose/releases/download/1.12.0/docker-compose-$(uname -s)-$(uname -m)" | sudo tee /usr/local/bin/docker-compose > /dev/null
sudo chmod +x /usr/local/bin/docker-compose
sudo yum install git-all -y
#stopgap for ohmyzsh
echo "alias ls='ls -lah --color'" >> ~/.bashrc
echo "alias l='ls'" >> ~/.bashrc
#downloading containers and starting them
cd ~
git clone --depth 1 --branch dev https://github.com/cbittencourt/Nagdom.git
cd Nagdom
sudo chmod +x start-nagdom.sh
./start-nagdom.sh