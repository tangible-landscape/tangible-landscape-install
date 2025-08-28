#!/usr/bin/env bash

set -e

GRASS_RELEASE=8.2.1
PCL_RELEASE=1.11.1
TANGIBLE_RELEASE=1.2.2
RINKINECT_RELEASE=2.1.0
NCORES=2
CDIR=`pwd`

sudo add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable
# package dependencies
sudo apt-get update && sudo apt install  \
   build-essential cmake curl pkg-config git wget\
   libusb-1.0-0-dev libturbojpeg0-dev libglfw3-dev \
   libboost-all-dev libeigen3-dev libflann-dev libopencv-dev \
   flex make bison gcc libgcc-s1 g++ ccache \
   python3-dateutil libgsl-dev \
   python3-numpy python3-pil python3-matplotlib python3-watchdog \
   python3-wxgtk4.0 python3-wxgtk-webview4.0 python3-pip \
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
   ghostscript wget \
   libproj-dev proj-data proj-bin \
   libgeos-dev \
   libgdal-dev python3-gdal gdal-bin \
   libzstd-dev checkinstall \
   libpdal-dev \
   libsdl2-dev -y

# Installing more dependencies for NVIZ
sudo apt-get install \
  ffmpeg ffmpeg2theora \
  libffmpegthumbnailer-dev -y

pip install -U -f https://extras.wxpython.org/wxPython4/extras/linux/gtk3/ubuntu-22.04 wxPython
# k4a
wget mirrors.kernel.org/ubuntu/pool/universe/libs/libsoundio/libsoundio1_1.1.0-1_amd64.deb
sudo dpkg -i libsoundio1_1.1.0-1_amd64.deb
curl -sSL https://packages.microsoft.com/ubuntu/18.04/prod/pool/main/libk/libk4a1.4/libk4a1.4_1.4.1_amd64.deb > /tmp/libk4a1.4_1.4.1_amd64.deb
curl -sSL https://packages.microsoft.com/ubuntu/18.04/prod/pool/main/libk/libk4a1.4-dev/libk4a1.4-dev_1.4.1_amd64.deb > /tmp/libk4a1.4-dev_1.4.1_amd64.deb
curl -sSL https://packages.microsoft.com/ubuntu/18.04/prod/pool/main/k/k4a-tools/k4a-tools_1.4.1_amd64.deb > /tmp/k4a-tools_1.4.1_amd64.deb
echo 'libk4a1.4 libk4a1.4/accepted-eula-hash string 0f5d5c5de396e4fee4c0753a21fee0c1ed726cf0316204edda484f08cb266d76' | sudo debconf-set-selections 
echo 'libk4a1.4 libk4a1.4/accept-eula select true' | sudo debconf-set-selections
sudo dpkg -i /tmp/libk4a1.4_1.4.1_amd64.deb
sudo dpkg -i /tmp/libk4a1.4-dev_1.4.1_amd64.deb
sudo dpkg -i /tmp/k4a-tools_1.4.1_amd64.deb
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
sudo apt-get install git
git clone --branch ${GRASS_RELEASE} https://github.com/OSGeo/grass
cd grass
# "configure" source code for local machine (checks for CPU type etc):
MYCFLAGS='-O2 -fPIC -fno-common -fexceptions -std=gnu99 -fstack-protector -m64'
#MYCXXFLAGS=''
MYLDFLAGS='-Wl,--no-undefined -Wl,-z,now'

LDFLAGS="$MYLDFLAGS" CFLAGS="$MYCFLAGS" CXXFLAGS="$MYCXXFLAGS" ./configure \
  --with-cxx \
  --enable-largefile \
  --with-proj --with-proj-share=/usr/share/proj \
  --with-gdal=/usr/bin/gdal-config \
  --with-python \
  --with-geos \
  --with-sqlite \
  --with-nls \
  --with-zstd \
  --with-pdal \
  --with-cairo --with-cairo-ldflags=-lfontconfig \
  --with-freetype=yes --with-freetype-includes="/usr/include/freetype2/" \
  --with-wxwidgets \
  --with-fftw \
  --with-openmp \
  --with-opengl-libs=/usr/include/GL \
  --with-postgres=yes --with-postgres-includes="/usr/include/postgresql" \
  --without-netcdf \
  --without-mysql \
  --without-odbc \
  --without-ffmpeg
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



