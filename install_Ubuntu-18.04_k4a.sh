#!/usr/bin/env bash

set -e

K4A_RELEASE=1.4
GRASS_RELEASE=8.2.0
RINKINECT_RELEASE=2.1.0
PCL_RELEASE=1.10.0
TANGIBLE_RELEASE=1.2.1
NUMTHREADS=2
CDIR=`pwd`

export DEBIAN_FRONTEND=noninteractive

# package dependencies
sudo apt-get update && sudo apt-get upgrade -y && \
    sudo apt-get install -y --no-install-recommends --no-install-suggests \
    build-essential \
    bison \
    bzip2 \
    cmake \
    curl \
    flex \
    g++ \
    gcc \
    gdal-bin \
    git \
    language-pack-en-base \
    libbz2-dev \
    libcairo2 \
    libcairo2-dev \
    libcurl4-gnutls-dev \
    libfftw3-bin \
    libfftw3-dev \
    libfreetype6-dev \
    libgdal-dev \
    libgeos-dev \
    libgsl0-dev \
    libjpeg-dev \
    libjsoncpp-dev \
    libnetcdf-dev \
    libncurses5-dev \
    libopenblas-base \
    libopenblas-dev \
    libopenjp2-7 \
    libopenjp2-7-dev \
    libpnglite-dev \
    libpq-dev \
    libpython3-all-dev \
    libsqlite3-dev \
    libtiff-dev \
    libzstd-dev \
    locales \
    make \
    mesa-common-dev \
    moreutils \
    ncurses-bin \
    netcdf-bin \
    python3 \
    python3-dateutil \
    python3-dev \
    python3-magic \
    python3-numpy \
    python3-pil \
    python3-pip \
    python3-ply \
    python3-setuptools \
    python3-venv \
    software-properties-common \
    sqlite3 \
    subversion \
    unzip \
    vim \
    wget \
    zip \
    zlib1g-dev \
    mesa-common-dev libglu1-mesa-dev

# K4A
sudo apt install -y --no-install-recommends --no-install-suggests gpg-agent debconf-utils
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo apt-add-repository https://packages.microsoft.com/ubuntu/18.04/prod
sudo apt-get update && echo "libk4a${K4A_RELEASE} libk4a${K4A_RELEASE}/accepted-eula-hash string 0f5d5c5de396e4fee4c0753a21fee0c1ed726cf0316204edda484f08cb266d76" | sudo debconf-set-selections && \
        echo "libk4a${K4A_RELEASE} libk4a${K4A_RELEASE}/accept-eula boolean true" | sudo debconf-set-selections && \
        sudo apt-get install -y libk4a${K4A_RELEASE} libk4a${K4A_RELEASE}-dev k4a-tools
sudo mkdir -p /etc/udev/rules.d
sudo wget https://raw.githubusercontent.com/microsoft/Azure-Kinect-Sensor-SDK/develop/scripts/99-k4a.rules -O /etc/udev/rules.d/99-k4a.rules

# GRASS
# download wxPython4 binary
sudo apt install -y --no-install-recommends --no-install-suggests libsdl1.2debian
sudo pip3 install -U -f https://extras.wxpython.org/wxPython4/extras/linux/gtk3/ubuntu-18.04 wxPython

# Configure compile and install GRASS GIS
git clone --depth=1 --branch $GRASS_RELEASE https://github.com/OSGeo/grass.git grass-${GRASS_RELEASE}
GRASS_PYTHON=/usr/bin/python3
cd grass-${GRASS_RELEASE}
./configure \
  --with-cxx \
  --enable-largefile \
  --with-proj --with-proj-share=/usr/share/proj \
  --with-gdal=/usr/bin/gdal-config \
  --with-geos \
  --with-sqlite \
  --with-cairo --with-cairo-ldflags=-lfontconfig \
  --with-freetype --with-freetype-includes="/usr/include/freetype2/" \
  --with-fftw \
  --with-postgres=yes --with-postgres-includes="/usr/include/postgresql" \
  --with-netcdf \
  --with-zstd \
  --with-bzlib \
  --without-mysql \
  --without-odbc \
  --with-openmp \
  --without-ffmpeg \
  --with-opengl-libs=/usr/include/GL \
    && make -j $NUMTHREADS \
    && sudo make install
cd ..

# PCL
sudo apt-get install -y --no-install-recommends --no-install-suggests libeigen3-dev libflann-dev
git clone --depth=1 --branch pcl-${PCL_RELEASE} https://github.com/PointCloudLibrary/pcl.git pcl-${PCL_RELEASE}
cd pcl-${PCL_RELEASE}
mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make -j$NUMTHREADS && \
    sudo make -j2 install
cd ../..

# r.in.kinect
git clone --single-branch --branch v${RINKINECT_RELEASE} https://github.com/tangible-landscape/r.in.kinect.git r.in.kinect.k4a
cd r.in.kinect.k4a
make MODULE_TOPDIR=../grass-${GRASS_RELEASE} && sudo make install MODULE_TOPDIR=../grass-${GRASS_RELEASE}
cd ..

# TL plugin
wget https://github.com/tangible-landscape/grass-tangible-landscape/archive/v${TANGIBLE_RELEASE}.tar.gz
tar xvf v${TANGIBLE_RELEASE}.tar.gz
cd grass-tangible-landscape-${TANGIBLE_RELEASE}
make MODULE_TOPDIR=../grass-${GRASS_RELEASE}
make install MODULE_TOPDIR=../grass-${GRASS_RELEASE}
cd ..

# set up GRASS GIS icon in dash
cat << EOF > /tmp/grass.desktop
[Desktop Entry]
Version=1.0
Name=GRASS GIS
Comment=Start GRASS GIS
Exec=`ls -d ${CDIR}/grass-${GRASS_RELEASE}/bin.x86_64-pc-linux-gnu/*`
Icon=${CDIR}/grass-${GRASS_RELEASE}/dist.x86_64-pc-linux-gnu/share/icons/hicolor/scalable/apps/grass.svg
Terminal=true
Type=Application
Categories=GIS;Application;
EOF
sudo mv /tmp/grass.desktop /usr/share/applications/grass.desktop
