#!/usr/bin/env bash
#
# Tangible Landscape Installation Script
# Ubuntu 24.04 with Orbbec Femto Bolt (using Orbbec SDK v2)
#
# This script installs:
# - GRASS GIS (compiled from source)
# - PCL (Point Cloud Library)
# - Orbbec SDK v2 (for Femto Bolt sensor)
# - r.in.kinect GRASS  tool (femto-bolt branch)
# - Tangible Landscape GRASS plugin
#

set -e

export DEBIAN_FRONTEND=noninteractive
export TZ=UTC

# Configuration - adjust versions as needed
GRASS_RELEASE=8.4.2
PCL_RELEASE=1.15.1
ORBBEC_SDK_VERSION=2.5.5
NCORES=4
CDIR=$(pwd)

echo "=============================================="
echo "Tangible Landscape Installer"
echo "Ubuntu 24.04 + Orbbec Femto Bolt"
echo "=============================================="
echo "Using ${NCORES} cores for compilation"
echo ""


# Package dependencies
echo "Installing system dependencies..."
sudo apt-get update && sudo apt-get install -y software-properties-common && \
   sudo add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable && \
   sudo apt-get update && sudo apt-get install -y \
   build-essential cmake curl pkg-config git wget \
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
   libreadline-dev libfreetype-dev \
   libfftw3-double3 libfftw3-dev \
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
   libpdal-dev \
   libsdl2-dev

# wxPython
pip install -U -f https://extras.wxpython.org/wxPython4/extras/linux/gtk3/ubuntu-24.04 wxPython

# ============================================
# Orbbec SDK v2 Installation
# ============================================
echo ""
echo "Installing Orbbec SDK v2..."

# Download and install Orbbec SDK v2 .deb package
ORBBEC_DEB="OrbbecSDK_v${ORBBEC_SDK_VERSION}_amd64.deb"
if [ ! -f "${ORBBEC_DEB}" ]; then
    wget "https://github.com/orbbec/OrbbecSDK_v2/releases/download/v${ORBBEC_SDK_VERSION}/${ORBBEC_DEB}"
fi
sudo dpkg -i "${ORBBEC_DEB}" || sudo apt-get install -f -y

# ============================================
# PCL (Point Cloud Library)
# ============================================
echo ""
echo "Installing PCL ${PCL_RELEASE}..."

if [ ! -d "pcl-pcl-${PCL_RELEASE}" ]; then
    wget "https://github.com/PointCloudLibrary/pcl/archive/pcl-${PCL_RELEASE}.tar.gz"
    tar xvf "pcl-${PCL_RELEASE}.tar.gz"
    rm "pcl-${PCL_RELEASE}.tar.gz"
fi

cd "pcl-pcl-${PCL_RELEASE}"
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j${NCORES}
sudo make install
cd ../..

# ============================================
# GRASS GIS
# ============================================
echo ""
echo "Installing GRASS GIS ${GRASS_RELEASE}..."

if [ ! -d "grass" ]; then
    git clone --branch ${GRASS_RELEASE} --depth 1 https://github.com/OSGeo/grass
fi

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

# Determine GRASS version directory
GRASS_VERSION_SHORT=$(echo ${GRASS_RELEASE} | cut -d. -f1,2 | tr -d '.')

# ============================================
# r.in.kinect (GRASS tool for Orbbec Femto Bolt)
# ============================================
echo ""
echo "Installing r.in.kinect (femto-bolt branch)..."

if [ ! -d "r.in.kinect" ]; then
    git clone --branch femto-bolt https://github.com/tangible-landscape/r.in.kinect
else
    cd r.in.kinect
    git fetch
    git checkout femto-bolt
    git pull
    cd ..
fi

cd r.in.kinect
make MODULE_TOPDIR=../grass
make install MODULE_TOPDIR=../grass
cd ..

# ============================================
# Tangible Landscape GRASS Plugin
# ============================================
echo ""
echo "Installing Tangible Landscape plugin (latest master)..."

if [ ! -d "grass-tangible-landscape" ]; then
    git clone https://github.com/tangible-landscape/grass-tangible-landscape
else
    cd grass-tangible-landscape
    git fetch
    git checkout master
    git pull
    cd ..
fi

cd grass-tangible-landscape
make MODULE_TOPDIR=../grass
make install MODULE_TOPDIR=../grass
cd ..

# ============================================
# Desktop Entry for GRASS GIS
# ============================================
echo ""
echo "Creating desktop entry..."

cat << EOF > /tmp/grass.desktop
[Desktop Entry]
Version=1.0
Name=GRASS
Comment=Start GRASS
Exec=/usr/local/bin/grass
Icon=/usr/local/grass${GRASS_VERSION_SHORT}/share/icons/hicolor/scalable/apps/grass.svg
Terminal=true
Type=Application
Categories=GIS;Application;
EOF
sudo mv /tmp/grass.desktop /usr/share/applications/grass.desktop

# ============================================
# Final Configuration
# ============================================
echo ""
echo "Running ldconfig..."
sudo ldconfig

echo ""
echo "=============================================="
echo "Installation Complete!"
echo "=============================================="
echo ""
echo "IMPORTANT: Please log out and log back in for USB permissions to take effect."
echo ""
echo "To test the Orbbec Femto Bolt sensor:"
echo "  - Run OrbbecViewer to verify camera connection"
echo "  - Or run: lsusb | grep -i orbbec"
echo ""
echo "To start GRASS:"
echo "  - Run: grass"
echo "  - Or use the GRASS desktop shortcut"
echo ""