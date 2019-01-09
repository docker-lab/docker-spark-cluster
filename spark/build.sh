
echo "Y" | ssh-keygen -t rsa -P '' -f config/id_rsa

if [ ! -d "deps" ]; then
  mkdir -p deps
  echo "Downloading hadoop, spark dependencies"
  wget http://mirror.bit.edu.cn/apache/hadoop/common/hadoop-3.1.1/hadoop-3.1.1.tar.gz -P ./deps
  wget http://mirrors.hust.edu.cn/apache/spark/spark-2.4.0/spark-2.4.0-bin-without-hadoop.tgz -P ./deps
else
  echo "Dependencies found, skipping retrieval..."
fi

docker build --build-arg http_proxy=http://172.17.18.84:8080 --build-arg https_proxy=http://172.17.18.84:8080 --build-arg no_proxy=dockeropen.paas.x,dockerproxy.paas.x,dockerg.paas.x,dockergroup.paas.x . -t sparkbase
