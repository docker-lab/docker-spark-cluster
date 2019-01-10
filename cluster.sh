#!/bin/bash

# Bring the services up
function startServices {
  docker start spark-cluster-master spark-cluster-node2 spark-cluster-node3
  sleep 5
  echo ">> Starting hdfs ..."
  docker exec -u hadoop -it spark-cluster-master hadoop/sbin/start-dfs.sh
  sleep 5
  echo ">> Starting yarn ..."
  docker exec -u hadoop -d spark-cluster-master hadoop/sbin/start-yarn.sh
  sleep 5
  echo ">> Starting Spark ..."
  docker exec -u hadoop -d spark-cluster-master /home/hadoop/sparkcmd.sh start
  docker exec -u hadoop -d spark-cluster-node2 /home/hadoop/sparkcmd.sh start
  docker exec -u hadoop -d spark-cluster-node3 /home/hadoop/sparkcmd.sh start
  echo "Hadoop info @ spark-cluster-master: http://172.18.1.1:8088/cluster"
  echo "Spark info @ nodemater  : http://172.18.1.1:8080/"
}

if [[ $1 = "start" ]]; then
  startServices
  exit
fi

if [[ $1 = "stop" ]]; then
  docker exec -u hadoop -d spark-cluster-master /home/hadoop/sparkcmd.sh stop
  docker exec -u hadoop -d spark-cluster-node2 /home/hadoop/sparkcmd.sh stop
  docker exec -u hadoop -d spark-cluster-node3 /home/hadoop/sparkcmd.sh stop
  docker stop spark-cluster-master spark-cluster-node2 spark-cluster-node3
  exit
fi

if [[ $1 = "deploy" ]]; then
  docker rm -f `docker ps -a|grep 'spark-cluster-node'|awk '{print $1}'` # delete old containers
  docker network rm sparknet
  docker network create --subnet=172.18.0.0/16 sparknet # create custom network

  # 3 nodes
  echo ">> Starting nodes master and worker nodes ..."
  docker run -d --net sparknet --ip 172.18.1.1 --hostname spark-cluster-master --add-host spark-cluster-node2:172.18.1.2 --add-host spark-cluster-node3:172.18.1.3 --name spark-cluster-master -it sparkbase
  docker run -d --net sparknet --ip 172.18.1.2 --hostname spark-cluster-node2  --add-host spark-cluster-master:172.18.1.1 --add-host spark-cluster-node3:172.18.1.3 --name spark-cluster-node2 -it sparkbase
  docker run -d --net sparknet --ip 172.18.1.3 --hostname spark-cluster-node3  --add-host spark-cluster-master:172.18.1.1 --add-host spark-cluster-node2:172.18.1.2 --name spark-cluster-node3 -it sparkbase

  # Format spark-cluster-master
  echo ">> Formatting hdfs ..."
  docker exec -u hadoop -it spark-cluster-master hadoop/bin/hdfs namenode -format
  startServices
  exit
fi

echo "Usage: cluster.sh deploy|start|stop"
echo "                 deploy - create a new Docker network"
echo "                 start  - start the existing containers"
echo "                 stop   - stop the running containers"  
