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

```
---
---
