---
---
# Temp items for my setup  (Delete before releasing):
```

##########################################################################################
#  notes:
##########################################################################################
-- I built a new standalone ubuntu 20 server to install this onto:

#  create a clone from the template
qm clone 9400 670 --name ice-integration

#  put your ssh key into a file:  `~/cloud_images/ssh_stuff`
qm set 670 --sshkey ~/cloud_images/ssh_stuff/id_rsa.pub

# change the default username:
qm set 670 --ciuser centos

#  Let's setup dhcp for the network in this image:
qm set 670 --ipconfig0 ip=dhcp

#   start the image from gui
qm start 670

####  Working !!!  ####

##########################################################################################
#  If I need to stop and destroy
##########################################################################################
qm stop 670 && qm destroy 670

##########################################################################################
#  ssh to our new host:
##########################################################################################

ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -o UserKnownHostsFile=/dev/null -i ~/fishermans_wharf/proxmox/id_rsa centos@192.168.1.43

##########################################################################################
#  create an osuser datagen and add to sudo file
##########################################################################################
sudo useradd -m -s /usr/bin/bash datagen

echo supersecret1 > passwd.txt
echo supersecret1 >> passwd.txt

sudo passwd datagen < passwd.txt

rm -f passwd.txt
sudo usermod -aG sudo datagen
##########################################################################################
#  let's complete this install as this user:
##########################################################################################
su - datagen 

##########################################################################################
# install github cli and setup cli access to a private repo
##########################################################################################
type -p curl >/dev/null || sudo apt install curl -y
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y

gh auth login

https://github.com/login/device
 
git config --global user.email "rtlepple@gmail.com"
git config --global user.name tlepple

```
---
---
