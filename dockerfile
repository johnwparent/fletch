# Fletch Dockerfile
# Installs the fletch binary to /opt/kitware/fletch

ARG BASE_IMAGE=ubuntu:18.04
FROM ${BASE_IMAGE}

ARG PY_MAJOR_VERSION=3
ARG ENABLE_CUDA=OFF

#
# Install System Dependencies
#
RUN apt-get update && \
    apt-get install --no-install-recommends -y build-essential \
                                               libgl1-mesa-dev \
                                               libexpat1-dev \
                                               libgtk2.0-dev \
                                               libxt-dev \
                                               libxml2-dev \
                                               libssl-dev \
                                               liblapack-dev \
                                               openssl \
                                               curl \
                                               git \
                                               libreadline-dev \
                                               zlib1g-dev \
                                               cmake
                                               
# conditional python package installation based on version
RUN if [ "$PY_MAJOR_VERSION" = "2" ]; then \
      apt-get install --no-install-recommends -y python2.7-dev \
                                                 python-pip && \
      pip install numpy; \
    else \
      apt-get install --no-install-recommends -y python3 \
                                                 python3-dev \
                                                 python3-pip && \
      pip3 install numpy && \
      ln -s /usr/bin/python3 /usr/local/bin/python; \
    fi
    
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*
    
#
# Build Fletch
#
ENV LD_LIBRARY_PATH=/opt/kitware/fletch/lib/:$LD_LIBRARY_PATH
COPY . /fletch
RUN mkdir -p /fletch/build /opt/kitware/fletch \
  && cd /fletch/build \
  && cmake -DCMAKE_BUILD_TYPE=Release \
    -Dfletch_ENABLE_ALL_PACKAGES=ON \
    -Dfletch_BUILD_WITH_PYTHON=ON \
    -Dfletch_BUILD_WITH_CUDA=${ENABLE_CUDA} \
    -Dfletch_PYTHON_MAJOR_VERSION=${PY_MAJOR_VERSION} \
    -Dfletch_BUILD_INSTALL_PREFIX=/opt/kitware/fletch \
    ../ \
  && make -j$(nproc) -k \
  && rm -rf /fletch
