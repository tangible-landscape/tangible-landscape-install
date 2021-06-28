#!/usr/bin/env bash

set -e

LIBFREENECT2_RELEASE=0.2.0
GRASS_RELEASE=7.8.5
PCL_RELEASE=1.11.1
TANGIBLE_RELEASE=1.1.0
RINKINECT_RELEASE=1.1.0
NCORES=2
CDIR=`pwd`

sudo add-apt-repository ppa:ubuntugis/ubuntugis-unstable
# package dependencies
sudo apt-get update && sudo apt-get install -y \
   build-essential cmake pkg-config git wget\
   libusb-1.0-0-dev libturbojpeg0-dev libglfw3-dev \
   libboost-all-dev libeigen3-dev libflann-dev libopencv-dev \
   flex make bison gcc libgcc1 g++ ccache \
   python3-dateutil libgsl-dev \
   python3-numpy python3-pil python3-matplotlib python3-watchdog \
   python3-wxgtk4.0 python3-wxgtk-webview4.0 \
   python-is-python3 \
   libncurses-dev \
   zlib1g-dev gettext \
   libtiff-dev libpnglite-dev \
   libcairo2 libcairo2-dev \
   sqlite3 libsqlite3-dev \
   libpq-dev \
   libreadline-dev libfreetype6-dev \
   libfftw3-3 libfftw3-dev \
   libboost-thread-dev libboost-program-options-dev \
   subversion \
   libavutil-dev \
   libavcodec-dev \
   libavformat-dev libswscale-dev \
   libglu1-mesa-dev libxmu-dev \
   ghostscript \
   libproj-dev proj-data proj-bin \
   libgeos-dev \
   libgdal-dev python3-gdal gdal-bin \
   libzstd-dev \
   libpdal-dev beignet-dev
   
 
# libfreenect2
wget https://github.com/OpenKinect/libfreenect2/archive/v${LIBFREENECT2_RELEASE}.tar.gz
tar xvf v${LIBFREENECT2_RELEASE}.tar.gz
rm v${LIBFREENECT2_RELEASE}.tar.gz
cd libfreenect2-${LIBFREENECT2_RELEASE}
mkdir build && cd build
cmake ..
make
sudo make install
sudo cp ../platform/linux/udev/90-kinect2.rules /etc/udev/rules.d/
cd ../..

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
Exec=/usr/local/bin/grass78
Icon=/usr/local/grass78/share/icons/hicolor/scalable/apps/grass.svg
Terminal=true
Type=Application
Categories=GIS;Application;
EOF
sudo mv /tmp/grass.desktop /usr/share/applications/grass.desktop

# set up kinect Protonect app in dash
cat << EOF > /tmp/kinect.desktop
[Desktop Entry]
Version=1.0
Name=Kinect Protonect
Comment=Start Kinect
Exec=${CDIR}/libfreenect2-${LIBFREENECT2_RELEASE}/build/bin/Protonect
Icon=
Terminal=true
Type=Application
Categories=GIS;Application;
EOF
sudo mv /tmp/kinect.desktop /usr/share/applications/kinect.desktop

