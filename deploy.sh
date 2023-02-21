#!/bin/bash
NGINX_CONTAINER_CONF_DIR=/etc/nginx

NGINX_CONF_VOLUME=nginx-config-volume
HOST_NGINX_CONF_DIR=~/nginx-config

NGINX_CONF_FILE_DIR=~

DOCKER_CONTAINER_NAME_PREFIX=springboot

# 받아올 변수
# INTERNAL_PORT
# EXTERNAL_PORT_GREEN
# EXTERNAL_PORT_BLUE
# DOCKER_IMAGE_NAME
# OPERATION_ENV

# nginx 컨테이너가 정상 작동하는지 확인
IS_NGINX_RUNNING=$(docker inspect -f '{{.State.Status}}' nginx | grep running)
if [ -z "$IS_NGINX_RUNNING" ]; then
  # 정상 작동하지 않을 시 nginx를 완전히 내린 후 다시 구동
  echo "nginx container is not running. run nginx container"
  docker rm -f nginx
  docker run -d --name nginx \
          -v ${NGINX_CONF_VOLUME}:${NGINX_CONTAINER_CONF_DIR} \
          -p 80:80 nginx:latest
  sleep 3
else
  echo "nginx is already running"
fi



IS_BLUE_RUNNING=$(docker inspect -f '{{.State.Status}}' ${DOCKER_CONTAINER_NAME_PREFIX}-blue | grep running)

if [ -n "$IS_BLUE_RUNNING" ]; then
  echo "green up"

  docker rm -f ${DOCKER_CONTAINER_NAME_PREFIX}-green
  docker run -d --name ${DOCKER_CONTAINER_NAME_PREFIX}-green \
          -p ${EXTERNAL_PORT_GREEN}:${INTERNAL_PORT} \
          -e "SPRING_PROFILES_ACTIVE=${OPERATION_ENV}" \
          ${DOCKER_IMAGE_NAME}:latest

  BEFORE_COLOR=blue
  AFTER_COLOR=green

  EXTERNAL_PORT=${EXTERNAL_PORT_GREEN}
else
  echo "blue up"

  docker rm -f ${DOCKER_CONTAINER_NAME_PREFIX}-blue
  docker run -d --name ${DOCKER_CONTAINER_NAME_PREFIX}-blue \
          -p ${EXTERNAL_PORT_BLUE}:${INTERNAL_PORT} \
          -e "SPRING_PROFILES_ACTIVE=${OPERATION_ENV}" \
          ${DOCKER_IMAGE_NAME}:latest

  BEFORE_COLOR=green
  AFTER_COLOR=blue

  EXTERNAL_PORT=${EXTERNAL_PORT_BLUE}
fi

sleep 3

echo "Health Check Start!"
for i in {1..10}
do
  sleep 3
  RESPONSE=$(curl -I http://localhost:${EXTERNAL_PORT} | grep HTTP)

  if [ -n "${RESPONSE}" ]; then
    echo "> Health check 성공"
    sed -i "2s/.*/server 172.17.0.1:${EXTERNAL_PORT};/g" ${NGINX_CONF_FILE_DIR}/nginx.conf
    yes | cp -rf ${NGINX_CONF_FILE_DIR}/nginx.conf ${HOST_NGINX_CONF_DIR}/conf.d/default.conf

    docker exec nginx nginx -s reload

    sleep 3

    docker rm -f ${DOCKER_CONTAINER_NAME_PREFIX}-${BEFORE_COLOR}
    echo ${BEFORE_COLOR} down

    echo "배포를 성공적으로 종료합니다"
    exit 0
  fi
done

echo "Health Check 실패"

docker rm -f ${DOCKER_CONTAINER_NAME_PREFIX}-${AFTER_COLOR}
echo "이전 컨테이너가 유지됩니다."
exit 1

