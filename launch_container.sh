#!/bin/sh
SCRIPT_DIR=$(cd $(dirname $0); pwd)

VNC_PASSWORD="on"
RESOLUTION="1920x1080"
NAME_IMAGE="cudagl_devenv_ws_${USER}"

# Make Container
if [ ! "$(docker image ls -q ${NAME_IMAGE})" ]; then
	if [ ! $# -ne 1 ]; then
		if [ "build" = $1 ]; then
		    # mkdir -p ssl
			# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ssl/nginx.key -out ssl/nginx.crt
			echo "Image ${NAME_IMAGE} does not exist."
			echo 'Now building image without proxy...'
			docker build --file=./Dockerfile -t $NAME_IMAGE . --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg UNAME=$USER
			exit
		fi
	else
		echo "Docker image not found. Please build first!"
		exit
  	fi
else
	if [ ! $# -ne 1 ]; then
		if [ "build" = $1 ]; then
			echo "Docker image is already built!"
			exit
		fi
	fi
fi

# Commit
if [ ! $# -ne 1 ]; then
	if [ "commit" = $1 ]; then
		echo 'Now commiting docker container...'
		docker commit cudagl_devenv_docker_${USER} cudagl_devenv_ws_${USER}:latest
		CONTAINER_ID=$(docker ps -a | grep cudagl_devenv_docker_${USER} | awk '{print $1}')
		docker stop $CONTAINER_ID
		docker rm $CONTAINER_ID
		exit
	fi
fi

# Stop
if [ ! $# -ne 1 ]; then
	if [ "stop" = $1 ]; then
		echo 'Now stopping docker container...'
		CONTAINER_ID=$(docker ps -a | grep cudagl_devenv_docker_${USER} | awk '{print $1}')
		docker stop $CONTAINER_ID
		docker rm $CONTAINER_ID -f
		exit
	fi
fi

XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
touch $XAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -

DOCKER_OPT=""
DOCKER_NAME="cudagl_devenv_docker_${USER}"
DOCKER_WORK_DIR="/home/${USER}"

## For XWindow
DOCKER_OPT="${DOCKER_OPT} \
		--volume=$XSOCK:/tmp/.X11-unix:rw \
		--volume=$XAUTH:/tmp/.docker.xauth:rw \
		--shm-size=1gb \
		--env="XAUTHORITY=${XAUTH}" \
		--env="DISPLAY=${DISPLAY}" \
		--env=TERM=xterm-256color \
		--env=QT_X11_NO_MITSHM=1 \
        --volume=/home/${USER}:/home/${USER}/host_home:rw \
        --env=DISPLAY=${DISPLAY} \
		-p $(id -u):443 -e SSL_PORT=443 -e RESOLUTION=${RESOLUTION} -e VNC_PASSWORD=${VNC_PASSWORD} \
        -w ${DOCKER_WORK_DIR} \
        -u ${USER} \
        --hostname `hostname`-Docker-${USER} \
        --add-host `hostname`-Docker-${USER}:127.0.1.1"

DOCKER_OPT="${DOCKER_OPT} --privileged -it "

## For nvidia-docker
DOCKER_OPT="${DOCKER_OPT} --gpus all "

# Device
if [ ! $# -ne 1 ]; then
	if [ "device" = $1 ]; then
		echo 'Enable host devices'
		DOCKER_OPT="${DOCKER_OPT} --volume=/dev:/dev:rw "
	fi
fi

## Allow X11 Connection
xhost +local:`hostname`-Docker-${USER}
CONTAINER_ID=$(docker ps -a | grep cudagl_devenv_ws_${USER}: | awk '{print $1}')

# Run Container
if [ ! "$CONTAINER_ID" ]; then
	if [ ! $# -ne 1 ]; then
		if [ "setup" = $1 ]; then
			docker run ${DOCKER_OPT} \
				--name=${DOCKER_NAME} \
				--entrypoint "/startup.sh" \
				cudagl_devenv_ws_${USER}:latest
			CONTAINER_ID=$(docker ps -a | grep cudagl_devenv_docker_${USER} | awk '{print $1}')
			docker stop $CONTAINER_ID
			docker rm $CONTAINER_ID -f
		else
			docker run ${DOCKER_OPT} \
				--name=${DOCKER_NAME} \
				--entrypoint "bash" \
				cudagl_devenv_ws_${USER}:latest
		fi
	else
		docker run ${DOCKER_OPT} \
			--name=${DOCKER_NAME} \
			--entrypoint "bash" \
			cudagl_devenv_ws_${USER}:latest
	fi
else
	docker start $CONTAINER_ID
	docker exec -it $CONTAINER_ID /bin/bash
fi

xhost -local:`hostname`-Docker-${USER}

