#!/bin/bash

##########################################################################################
#  Stop of Spark items
##########################################################################################

echo "stopping spark worker..."
/opt/spark/sbin/stop-worker.sh spark://$(hostname -f):7077
echo
sleep 5

echo "stopping spark master..."
/opt/spark/sbin/stop-master.sh
echo
sleep 5

##########################################################################################
#  Stop of panda items
##########################################################################################


echo "stopping redpanda..."
sudo systemctl stop redpanda
echo
sleep 5

echo "stopping redpanda console..."
sudo systemctl stop redpanda-console
echo
sleep 5

##########################################################################################
#  stop of minio
##########################################################################################

echo "stopping minio.service..."
sudo systemctl stop minio.service
echo
sleep 5

##########################################################################################
#  Start of Spark items
##########################################################################################

echo "starting spark master..."
/opt/spark/sbin/start-master.sh
echo
sleep 5
echo "starting spark worker..."
/opt/spark/sbin/start-worker.sh spark://$(hostname -f):7077
echo
sleep 5

##########################################################################################
#  Start of panda items
##########################################################################################


echo "starting redpanda..."
sudo systemctl start redpanda
echo
sleep 5

echo "starting redpanda console..."
sudo systemctl start redpanda-console
echo
sleep 5
##########################################################################################
#  start of minio
##########################################################################################

echo "starting minio.service..."
sudo systemctl start minio.service
echo
sleep 5
echo "services have been restarted..."
