# Start from nvidia/vulkan-cuda ubuntu 18.04 base
FROM nvidia/vulkan:1.1.121-cuda-10.1--ubuntu18.04

# Install requirements
RUN packages='libsdl2-2.0=2.0.8+dfsg1-1ubuntu1.18.04.4 xserver-xorg=1:7.7+19ubuntu7 libvulkan1 \
	xdg-user-dirs=0.17-1ubuntu1 xdg-utils=1.1.2-1ubuntu2.3 build-essential=12.4ubuntu1 libxerces-c-dev=3.2.0+debian-2 \
	libpng16-16=1.6.34-1ubuntu0.18.04.2 libjpeg8=8c-2ubuntu8 libtiff5=4.0.9-5 wget=1.19.4-1ubuntu2.2 \
	python3.6=3.6.9-1~18.04ubuntu1.3 python3.6-dev=3.6.9-1~18.04ubuntu1.3 python3-pip=9.0.1-2.3~ubuntu1.18.04.4 \
	screen=4.6.2-1ubuntu1 sysstat=11.6.1-1 docker-ce-cli=5:19.03.13~3-0~ubuntu-bionic ' \ 
#carla-simulator=0.9.10-2' \ 
	&& apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common locales \
	&& locale-gen en_US.UTF-8 && export LC_CTYPE="en_US.UTF-8" LANG="en_US.UTF-8" \
	&& curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && add-apt-repository \
	"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
#	&& apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1AF1527DE64CB8D9 && add-apt-repository \
#	"deb [arch=amd64] http://dist.carla.org/carla $(lsb_release -sc) main" \
	&& apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y $packages --no-install-recommends \
     && VULKAN_API_VERSION=`dpkg -s libvulkan1 | grep -oP 'Version: [0-9|\.]+' | grep -oP '[0-9|\.]+'` && \
	mkdir -p /etc/vulkan/icd.d/ && \
	echo \
	"{\
		\"file_format_version\" : \"1.0.0\",\
		\"ICD\": {\
			\"library_path\": \"libGLX_nvidia.so.0\",\
			\"api_version\" : \"${VULKAN_API_VERSION}\"\
		}\
	}" > /etc/vulkan/icd.d/nvidia_icd.json \
	&& rm -rf /var/lib/apt/lists/* && pip3 install --user setuptools==50.3.2 wheel==0.30.0 && pip3 install py_trees==0.8.3 networkx==2.5 \
	six==1.15.0 numpy==1.19.4 shapely==1.7.0 xmlschema==1.1.3 ephem==3.7.7.1 tabulate==0.8.7 matplotlib==3.3.2 Flask==1.1.2 gpustat==0.6.0

# install CARLA and its PythonAPI
RUN useradd -m carla && groupadd docker && usermod -aG docker carla && newgrp docker && echo "logfile screenlog-%S" > /home/carla/.screenrc

COPY --chown=carla:carla . /app

USER carla
WORKDIR /app

# Setup working environment
ENV CARLA_ROOT="/opt/carla-simulator" SCENARIO_RUNNER_ROOT="/app/scenario_runner" FLASK_APP="/app/web.py" SDL_VIDEODRIVER=offscreen \
    LC_CTYPE="en_US.UTF-8" LANG="en_US.UTF-8"
ENV PYTHONPATH="${CARLA_ROOT}/PythonAPI/carla/dist/carla-0.9.10-py3.7-linux-x86_64.egg"
ENV PYTHONPATH="${PYTHONPATH}:${CARLA_ROOT}/PythonAPI/carla/agents"
ENV PYTHONPATH="${PYTHONPATH}:${CARLA_ROOT}/PythonAPI/carla"
ENV PYTHONPATH="${PYTHONPATH}:${CARLA_ROOT}/PythonAPI"

CMD flask run
