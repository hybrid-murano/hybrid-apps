#!/bin/bash

# $1 - NAME
# $2 - IP

#service kube-proxy stop
service kube-scheduler stop
service kube-controller-manager stop
#service kubelet stop
service kube-apiserver stop

#Disable controller-manager for now
#chmod -x /etc/init.d/kube-controller-manager

#Create log folder for Kubernetes services
mkdir /var/log/kubernetes
mkdir -p /var/run/murano-kubernetes

sed -i.bkp "s/%%MASTER_IP%%/$2/g" default_scripts/kube-scheduler

cp -f default_scripts/kube-apiserver /etc/default/
cp -f default_scripts/kube-scheduler /etc/default/
cp -f default_scripts/kube-controller-manager /etc/default/

cp -f initd_scripts/getCpuLoad /usr/bin/

cp init_conf/kube-apiserver.conf /etc/init/
cp init_conf/kube-controller-manager.conf /etc/init/
cp init_conf/kube-scheduler.conf /etc/init/

chmod +x initd_scripts/*
cp initd_scripts/kube-apiserver /etc/init.d/
cp initd_scripts/kube-controller-manager /etc/init.d/
cp initd_scripts/kube-scheduler /etc/init.d/

service kube-apiserver start
service kube-scheduler start
service kube-controller-manager start

sleep 1

RETRY=5
while [[ `ss -tln|grep 8080|wc -l` = 0 && $RETRY -gt 0 ]]; do
  sleep 1
  RETRY=`expr $RETRY - 1`
done

# $3 - REGISTRY
REGISTRY=$3
if [ ${REGISTRY}y = y ]; then REGISTRY='gcr.io'; fi
sed -i.bkp "s/##DOCKER_REGISTRY##/$REGISTRY/g" default_scripts/kube-ui-rc.yaml
/opt/bin/kubectl create -f default_scripts/kube-ui-rc.yaml
/opt/bin/kubectl create -f default_scripts/kube-ui-svc.yaml
/opt/bin/etcdctl mk /registry/services/endpoints/mapping/$2:8080 "8080"

#/opt/bin/kubectl delete node 127.0.0.1
