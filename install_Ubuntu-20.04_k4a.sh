#!/usr/bin/env bash

set -e

GRASS_RELEASE=8.2.0
PCL_RELEASE=1.11.1
TANGIBLE_RELEASE=1.2.1
RINKINECT_RELEASE=2.1.0
NCORES=2
CDIR=`pwd`

sudo add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable
# package dependencies
sudo apt-get update && sudo apt-get install -y \
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
    mesa-common-dev libglu1-mesa-dev \
    libpdal-dev

# k4a
curl -sSL https://packages.microsoft.com/ubuntu/18.04/prod/pool/main/libk/libk4a1.4/libk4a1.4_1.4.1_amd64.deb > /tmp/libk4a1.4_1.4.1_amd64.deb
curl -sSL https://packages.microsoft.com/ubuntu/18.04/prod/pool/main/libk/libk4a1.4-dev/libk4a1.4-dev_1.4.1_amd64.deb > /tmp/libk4a1.4-dev_1.4.1_amd64.deb
echo 'libk4a1.4 libk4a1.4/accepted-eula-hash string 0f5d5c5de396e4fee4c0753a21fee0c1ed726cf0316204edda484f08cb266d76' | sudo debconf-set-selections 
echo 'libk4a1.4 libk4a1.4/accept-eula select true' | sudo debconf-set-selections
sudo dpkg -i /tmp/libk4a1.4_1.4.1_amd64.deb
sudo dpkg -i /tmp/libk4a1.4-dev_1.4.1_amd64.deb
sudo mkdir -p /etc/udev/rules.d
sudo wget https://raw.githubusercontent.com/microsoft/Azure-Kinect-Sensor-SDK/develop/scripts/99-k4a.rules -O /etc/udev/rules.d/99-k4a.rules

# PCL
wget https://github.com/PointCloudLibrary/pcl/archive/pcl-${PCL_RELEASE}.tar.gz
tar xvf pcl-${PCL_RELEASE}.tar.gz
rm pcl-${PCL_RELEASE}.tar.gz
cd pcl-pcl-${PCL_RELEASE}
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j${NCORES}
sudo make -j2 install
cd ../..

# GRASS GIS
git clone --branch ${GRASS_RELEASE} https://github.com/OSGeo/grass
cd grass
CFLAGS="-O2 -Wall" LDFLAGS="-s" ./configure \
  --enable-largefile=yes \
  --with-nls \
  --with-cxx \
  --with-readline \
  --with-pthread \
  --with-proj-share=/usr/share/proj \
  --with-geos=/usr/bin/geos-config \
  --with-cairo \
  --with-freetype=yes --with-freetype-includes="/usr/include/freetype2/" \
  --with-sqlite=yes \
  --with-odbc=no \
  --with-liblas=no \
  --with-opengl \
  --with-pdal
make -j${NCORES}
sudo make install
cd ..

# r.in.kinect
git clone --branch v${RINKINECT_RELEASE} https://github.com/tangible-landscape/r.in.kinect
cd r.in.kinect
make MODULE_TOPDIR=../grass
make install MODULE_TOPDIR=../grass
cd ..

# TL plugin
git clone --branch v${TANGIBLE_RELEASE} https://github.com/tangible-landscape/grass-tangible-landscape
cd grass-tangible-landscape
make MODULE_TOPDIR=../grass
make install MODULE_TOPDIR=../grass
cd ..

# set up GRASS GIS icon in dash
cat << EOF > /tmp/grass.desktop
[Desktop Entry]
Version=1.0
Name=GRASS GIS
Comment=Start GRASS GIS
Exec=/usr/local/bin/grass
Icon=/usr/local/grass82/share/icons/hicolor/scalable/apps/grass.svg
Terminal=true
Type=Application
Categories=GIS;Application;
EOF
sudo mv /tmp/grass.desktop /usr/share/applications/grass.desktop



