# Start from nvidia/vulkan-cuda ubuntu 18.04 base
FROM nvidia/vulkan:1.1.121-cuda-10.1--ubuntu18.04

# Install requirements
RUN packages='libsdl2-2.0 xserver-xorg libvulkan1 xdg-user-dirs xdg-utils build-essential=12.4ubuntu1 libxerces-c-dev \
	wget=1.19.4-1ubuntu2.2 python3.6 python3.6-dev python3-pip screen=4.6.2-1 sysstat=11.6.1-1 docker-ce-cli' \
	&& apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common \
	&& curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && add-apt-repository \
	"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
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
	&& rm -rf /var/lib/apt/lists/* && pip3 install --user setuptools==46.3.0 wheel==0.34.2 && pip3 install py_trees==0.8.3 networkx==2.2 pygame==1.9.6 \
	six==1.14.0 numpy==1.18.4 psutil==5.7.0 shapely==1.7.0 xmlschema==1.1.3 ephem==3.7.6.0 tabulate==0.8.7 matplotlib==3.3.2 Flask==1.1.2 gpustat==0.6.0

# setup environment :
# 
#   CARLA_HOST :    uri for carla package without trailing slash. 
#                   For example, "https://carla-releases.s3.eu-west-3.amazonaws.com/Linux".
#
#   CARLA_RELEASE : Name of the package to be used. For example, "CARLA_0.9.9".
# 
#
#  It's expected that $(CARLA_HOST)/$(CARLA_RELEASE).tar.gz is a downloadable resource.
#

ENV CARLA_HOST "https://carla-releases.s3.eu-west-3.amazonaws.com/Linux"
ENV CARLA_RELEASE "CARLA_0.9.10"

# install CARLA and its PythonAPI
RUN useradd -m carla && groupadd docker && usermod -aG docker carla && newgrp docker && \
    echo "$CARLA_HOST/$CARLA_RELEASE.tar.gz" && mkdir -p /app/carla && chown -R carla:carla /app && \
    wget -qO- "$CARLA_HOST/$CARLA_RELEASE.tar.gz" | tar --owner=carla --group=carla -xzv -C /app/carla && \
    python3 -m easy_install --no-find-links --no-deps "$(find /app/carla -iname '*py3.*.egg' )" && echo "logfile screenlog-%S" > /home/carla/.screenrc

COPY --chown=carla:carla . /app

USER carla
WORKDIR /app

# Setup working environment
ENV LC_ALL="C.UTF-8" LANG="C.UTF-8" PYTHONPATH="${PYTHONPATH}:/app/carla/PythonAPI/carla/agents:/app/carla/PythonAPI/carla" \
    CARLA_ROOT="/app/carla" SCENARIO_RUNNER_ROOT="/app/scenario_runner" FLASK_APP="/app/web.py" SDL_VIDEODRIVER=offscreen

CMD flask run
