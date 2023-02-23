#!/bin/bash

# Author: Yongpeng Zhang - zhangyp6603@outlook.com
#
# Description:  install WPS,WRF,WRFDA,WRF-Chem.
#               If you have any questions, send an e-mail or open an issue.
# Start by
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/jokervTv/auto-install-WRFV4/master/autoInstall.sh)"
# Or (faster in China)
# bash -c "$(curl -fsSL https://gitee.com/jokervTv/auto-install-WRFV4/raw/master/autoInstall.sh)"

# System info
OS_RELEASE="ubuntu"
PACKAGE_MANAGER="apt-get"
MAKE_OPENMP="-j4"
WRF_WPS_OPENMP='-j 4'
TEST_FLAG="0"
SERVER_FLAG="0"
LIB_INSTALL_DIR="$HOME/.WRF_MPAS_LIB"
LOG_DIR="$HOME/log-wrf-mpas"
SRC_DIR="$HOME/src-wrf-mpas"
DOWNLOAD_URL="http://wrflib.jokervtv.top"

CC_VERSION="gcc"
FC_VERSION="gfortran"
CXX_VERSION="g++"
# for ubuntu 2004, there are some bug with openmpi 4.0.3, so change to mpich
MPICC_VERSION="mpicc.mpich"
MPIFC_VERSION="mpifort.mpich"
MPICXX_VERSION="mpic++.mpich"

# Version
OPENMPI_VERSION="openmpi-4.1.1"
ZLIB_VERSION="zlib-1.2.11"
JASPER_VERSION="jasper-2.0.14"
HDF5_VERSION="hdf5-1.13.1"
NETCDF_VERSION="NETCDF-4.7.0"
NETCDF_FORTRAN_VERSION="netcdf-fortran-4.4.5"
BISON_VERSION="bison-3.5.4" #http://ftpmirror.gnu.org/bison/
FLEX_VERSION="flex-2.6.4" #https://github.com/westes/flex
WPS_VERSION="WPS-4.3" #https://github.com/wrf-model/WPS
WRF_VERSION="WRF-4.3" #https://github.com/wrf-model/WRF
WRFplus_VERSION="WRFplus-4.2" #https://github.com/wrf-model/WRF
WRFDA_VERSION="WRFDA-4.2" #https://github.com/wrf-model/WRF
PIO_VERSION="pio-1.7.4" #https://github.com/NCAR/ParallelIO/
PNETCDF_VERSION="pnetcdf-1.11.2" #https://github.com/Parallel-NetCDF/PnetCDF
MPAS_VERSION="MPAS-Model-7.0" #https://github.com/MPAS-Dev/MPAS-Model

# check flag
WRF_INSTALL_FLAG=1
WRF_INSTALL_SUCCESS_FLAG=0
WRF_CHEM_SETTING=0
WRF_KPP_SETTING=0

# download src of lib
wgetSource() {
    cd $SRC_DIR
    rm -rf $SRC_DIR/$1
    rm -f $SRC_DIR/$1.tar.gz*
    echo " Download $1"
    wget_flag=$(wget -cnv $DOWNLOAD_URL/$1.tar.gz)
    echo " Extract $1"
    tar -xf $1.tar.gz
    cd $SRC_DIR/$1
    echo " Configure & make $1"
}

# receivec a lib name as $1 to install or install with testing
makeInstall() {
    make $MAKE_OPENMP &>$LOG_DIR/$1.make.log
    if [ "$TEST_FLAG" -eq "1" ];then
        make check        &>$LOG_DIR/$1.check.log
        make test         &>$LOG_DIR/$1.test.log
    fi
    make install      &>$LOG_DIR/$1.install.log
}

#-------functions start--------

getInfo() {
    clear
    echo ""
    echo " ============================================================== "
    echo " \                  Autoinstall WRF or MPAS                   / "
    echo " \     URL: https://github.com/jokervTv/auto-install-WRFV4    / "
    echo " \              Script Created by Yongpeng Zhang              / "
    echo " ============================================================== "
    echo ""
}

# Check authority
checkRoot() {
    [[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}]: Please run this script with ${red}sudo${plain}!" && exit 1
}

checkSystemInfo() {
    if [ -f /etc/redhat-release ]; then
        OS_RELEASE="centos"
        PACKAGE_MANAGER="yum"
    elif cat /etc/issue | grep -Eqi "debian"; then
        OS_RELEASE="ubuntu"
        PACKAGE_MANAGER="apt-get"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        OS_RELEASE="ubuntu"
        PACKAGE_MANAGER="apt-get"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        OS_RELEASE="centos"
        PACKAGE_MANAGER="yum"
    elif cat /proc/version | grep -Eqi "debian"; then
        OS_RELEASE="ubuntu"
        PACKAGE_MANAGER="apt-get"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        OS_RELEASE="ubuntu"
        PACKAGE_MANAGER="apt-get"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        OS_RELEASE="centos"
        PACKAGE_MANAGER="apt-get"
        PACKAGE_MANAGER="yum"
    fi
}

getDir() {
    echo "========================================================="
    echo "Please enter the library installation directory:"
    echo ""
    echo "(defualt: $LIB_INSTALL_DIR)"
    echo ""
    read read_install_dir
    if [ -n "$read_install_dir" ]; then
        LIB_INSTALL_DIR="$read_install_dir"
    fi
    mkdir $LIB_INSTALL_DIR
}

checkMem() {
    echo ""
    echo "========================================================="
    echo "Checking the memory size:"

    memTotal=`free -gt | grep "Total:" | awk '{print $2}'`
    if [[ $memTotal -lt 5 ]]; then
        echo "your memory is too small, now add swap file"
        swapSize=$((5-$memTotal))
        dd if=/dev/zero of=$LIB_INSTALL_DIR/swapfile bs=1G count=$swapSize
        mkswap $LIB_INSTALL_DIR/swapfile
        sudo chmod 0600 $LIB_INSTALL_DIR/swapfile
        sudo swapon $LIB_INSTALL_DIR/swapfile
    elif [[ $memTotal -ge 5 ]]; then
        echo "Sufficient memory size"
    fi
}

getWRFVersion() {
    echo "============================================================"
    echo "Which version of ${red}WRF${plain} do you want to use ? (defualt: 2)"
    echo ""
    echo "  0. 3.9.1.1"
    echo "  1. 4.2"
    echo "  2. 4.3"
    read compier_index
    if [ -n "$compier_index" ]; then
        if [[ $compier_index -eq 0 ]]; then
            WRF_VERSION="WRF-3.9.1.1"
            WRFplus_VERSION="WRFplus-3.9.1.1"
            WRFDA_VERSION="WRFDA-3.9.1.1"
        elif [[ $compier_index -eq 1 ]]; then
            WRF_VERSION="WRF-4.2"
            WRFplus_VERSION="WRFplus-4.2"
            WRFDA_VERSION="WRFDA-4.2"
        elif [[ $compier_index -eq 2 ]]; then
            WRF_VERSION="WRF-4.3"
            WRFplus_VERSION="WRFplus-4.3"
            WRFDA_VERSION="WRFDA-4.3"
        fi
    fi
}

getWPSVersion() {
    echo "============================================================"
    echo "Which version of ${red}WPS${plain} do you want to use ? (defualt: 2)"
    echo ""
    echo "  0. 3.9.1"
    echo "  1. 4.2"
    echo "  2. 4.3"
    read compier_index
    if [ -n "$compier_index" ]; then
        if [[ $compier_index -eq 0 ]]; then
            WPS_VERSION="WPS-3.9.1"
        elif [[ $compier_index -eq 1 ]]; then
            WPS_VERSION="WPS-4.2"
        elif [[ $compier_index -eq 2 ]]; then
            WPS_VERSION="WPS-4.3"
        fi
    fi
}

getCompiler() {
    echo "============================================================"
    echo "Which compiler do you want to use ? (defualt: 1)"
    echo ""
    echo "  1. GUN (gcc/gfortran)"
    echo "  2. Intel oneAPI"
    read compier_index
    if [ -n "$compier_index" ]; then
        if [[ $compier_index -eq 2 ]]; then
            CC_VERSION="icc"
            FC_VERSION="ifort"
            CXX_VERSION="icpc"
            MPICC_VERSION="mpiicc"
            MPIFC_VERSION="mpiifort"
            MPICXX_VERSION="mpiicpc"

            export CC=$CC_VERSION
            export CXX=$CXX_VERSION
            export FC=$FC_VERSION
        fi
    fi
    }

getOpenmp() {
    echo "============================================================"
    echo "How many physical cores do you wan to use ? (defualt: 4)"
    echo "If you know nothing about this, please input 0 or just hit enter."
    echo ""
    read cores_number
    if [ -n "$cores_number" ]; then
        if [ $cores_number -ne 0 ]; then
            MAKE_OPENMP="-j$cores_number"
            WRF_WPS_OPENMP="-j $cores_number"
        fi
    fi
}

reSetEnv() {
    echo '' >> $HOME/.bashrc
    echo "###############################################" >> $HOME/.bashrc
    echo "# START for WRF or MPAS automatic installation" >> $HOME/.bashrc
    echo '' >> $HOME/.bashrc

    echo "#for $ZLIB_VERSION" >> $HOME/.bashrc
    echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$ZLIB_VERSION'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
    echo '' >> $HOME/.bashrc

    echo "#for $JASPER_VERSION" >> $HOME/.bashrc
    echo "export JASPER=$LIB_INSTALL_DIR/$JASPER_VERSION" >> $HOME/.bashrc
    echo "export JASPERLIB=$TEMP_JASPER_LIB_DIR" >> $HOME/.bashrc
    echo "export JASPERINC=$LIB_INSTALL_DIR/$JASPER_VERSION/include" >> $HOME/.bashrc
    echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$JASPER_VERSION'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc

    echo '' >> $HOME/.bashrc
    echo "#for $HDF5_VERSION" >> $HOME/.bashrc
    echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$HDF5_VERSION'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc

    echo '' >> $HOME/.bashrc
    echo "#for $NETCDF_VERSION" >> $HOME/.bashrc
    echo 'export PATH='$LIB_INSTALL_DIR'/'$NETCDF_VERSION'/bin:$PATH' >> $HOME/.bashrc
    echo "export NETCDF=$LIB_INSTALL_DIR/$NETCDF_VERSION" >> $HOME/.bashrc
    echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$NETCDF_VERSION'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
}

getTest() {
    echo "============================================================"
    echo "do you wanna make test or check ? (defualt: no)"
    echo "0.no"
    echo "1.yes"
    read read_test_flag
    if [ -n "$read_test_flag" ]; then
        if [[ $read_test_flag -eq 1 ]];then
            TEST_FLAG="$read_test_flag"
        fi
    fi
}

# Change sources
setSources() {
    echo "=============================================="
    echo "Do you wanna change software sources (Recommended for Mainland China)?"
    echo ""
    echo "  1. yes"
    echo "  0. no, nothing to change (default)"
    echo ""
    echo "If you know nothing about this, please input 0"
    willness="0"
    read willness
    if  [ -n "$willness" ] ;then
        if [[ $willness -eq 1 ]];then
            sudo -s bash -c "/bin/bash <(curl -sSL https://gitee.com/SuperManito/LinuxMirrors/raw/main/ChangeMirrors.sh)"
        fi
    fi
    echo "==============================================="
}

chooseFeatures() {
    echo "=============================================="
    echo "Which option do you wanna choose ?"
    echo ""
    echo "  1. WPS, WRF:em_real"
    if [ "$OS_RELEASE" == "centos" ];then
        echo "  2. WPS, WRF:em_real, WRF-chem (with Kpp)"
        echo "  3. WPS, WRF:em_real, WRF-hydro (support soon, NOT currently supported)"
    elif [ "$OS_RELEASE" == "ubuntu" ];then
        echo "  2. WPS, WRF:em_real, WRF-chem (without Kpp)"
        echo "  3. WPS, WRF:em_real, WRF-hydro"
    fi
    echo "  4. WPS, WRF:em_real, WRFDA:4dvar"
    echo "  5. MPAS-A 7.0 (Experimental)"
    echo "  0. Building Libraries Only"
    echo "=============================================="
    read read_test_flag
    if [ $read_test_flag -eq 0 ];then
        WRF_INSTALL_FLAG=0
        WRF_INSTALL_SUCCESS_FLAG_SHOULD_BE=0
    elif [ $read_test_flag -eq 1 ];then
        WRF_INSTALL_FLAG=1
        WRF_INSTALL_SUCCESS_FLAG_SHOULD_BE=2
    elif [ $read_test_flag -eq 2 ];then
        WRF_INSTALL_FLAG=2
        WRF_INSTALL_SUCCESS_FLAG_SHOULD_BE=2
    elif [ $read_test_flag -eq 3 ];then
        WRF_INSTALL_FLAG=3
        WRF_INSTALL_SUCCESS_FLAG_SHOULD_BE=2
    elif [ $read_test_flag -eq 4 ];then
        WRF_INSTALL_FLAG=4
        WRF_INSTALL_SUCCESS_FLAG_SHOULD_BE=4
    elif [ $read_test_flag -eq 5 ];then
        WRF_INSTALL_FLAG=5
        #WRF_INSTALL_SUCCESS_FLAG_SHOULD_BE=4
    else
        echo "input error: please input"
        exit 1
    fi
    echo $WRF_INSTALL_FLAG
}

checkInfo() {
    clear
    echo ""
    echo "Please check the info:"
    echo "=========================================================="
    echo ""
    echo "the following software will be installed in"
    echo "             ${red} $LIB_INSTALL_DIR ${plain} :"
    echo ""
    echo $ZLIB_VERSION
    echo $JASPER_VERSION
    echo $HDF5_VERSION
    echo $NETCDF_VERSION
    echo $NETCDF_FORTRAN_VERSION
    if [[ $WRF_INSTALL_FLAG -eq 2 ]];then
        echo $BISON_VERSION
        echo $FLEX_VERSION
    fi
    if [[ $WRF_INSTALL_FLAG -eq 5 ]];then
        echo $PIO_VERSION
        echo $PNETCDF_VERSION
    fi
    #echo $WRF_VERSION
    #echo $WPS_VERSION
    echo ""
    echo "=========================================================="
    echo ""

    if [[ $WRF_INSTALL_FLAG -eq 5 ]];then
        echo "MPAS-atmosphere           will be installed in ${red} $HOME/MPAS-atmosphere ${plain}"
        echo "MPAS-init_atmosphere      will be installed in ${red} $HOME/MPAS-init_atmosphere ${plain}"
    elif [[ $WRF_INSTALL_FLAG -ne 0 ]];then
        echo "WPS       will be installed in ${red} $HOME/$WPS_VERSION ${plain}"
        echo "WRF       will be installed in ${red} $HOME/$WRF_VERSION ${plain}"
        if [[ $WRF_INSTALL_FLAG -eq 4 ]];then
            echo "WPFplus   will be installed in ${red} $HOME/$WRFplus_VERSION ${plain}"
            echo "WPFDA     will be installed in ${red} $HOME/$WRFDA_VERSION ${plain}"
        fi
    fi
    echo ""
}

# Install essential components
getLibrary() {
    echo "=========================================================="
    echo -e "\nInstall essential components"
    echo "=========================================================="
    if [ "$OS_RELEASE" = "ubuntu" ]; then
        sudo $PACKAGE_MANAGER -yqq install glibc* libgrib2c0d libgrib2c-dev libjpeg8* libpng16* perl curl
        sudo $PACKAGE_MANAGER -yqq install libpng-tools
        sudo $PACKAGE_MANAGER -yqq install libpng-devel
        sudo $PACKAGE_MANAGER -yqq install libpng-dev
        sudo $PACKAGE_MANAGER -yqq install tcsh samba cpp m4 quota
        sudo $PACKAGE_MANAGER -yqq install cmake make wget tar
        sudo $PACKAGE_MANAGER -yqq install autoconf libtool automake
        sudo $PACKAGE_MANAGER -yqq install autopoint gettext
        sudo $PACKAGE_MANAGER -yqq install gcc g++ gfortran
        sudo $PACKAGE_MANAGER -yqq install libcurl4-openssl-dev libcurl4
        sudo $PACKAGE_MANAGER -yqq install git
    elif [ "$OS_RELEASE" = "centos" ]; then
        sudo $PACKAGE_MANAGER -yqq install libjpeg-turbo libjpeg-turbo-devel
        sudo $PACKAGE_MANAGER -yqq install libpng-devel libpng16*
        sudo $PACKAGE_MANAGER -yqq install tcsh samba cpp m4 quota
        sudo $PACKAGE_MANAGER -yqq install gcc gcc-c++ gcc-gfortran
        sudo $PACKAGE_MANAGER -yqq install cmake make wget tar
        sudo $PACKAGE_MANAGER -yqq install autoconf libtool automake
        sudo $PACKAGE_MANAGER -yqq install gettext-devel gettext
        sudo $PACKAGE_MANAGER -yqq install libcurl-devel libcurl curl
        sudo $PACKAGE_MANAGER -yqq install git perl
        sudo $PACKAGE_MANAGER -yqq install freeglut-devel freeglut
    fi
}

# Creat logs and backupfiles
creatLogs() {
    mkdir $LOG_DIR
    mkdir $SRC_DIR
    if [ ! -s $HOME/.bashrc.autoInstall.bak ];then
        cp $HOME/.bashrc $HOME/.bashrc.autoInstall.bak.temp
        echo '' >> $HOME/.bashrc
        echo "###############################################" >> $HOME/.bashrc
        echo "# START for WRF or MPAS automatic installation" >> $HOME/.bashrc
    fi
}

# Install openMPI
getOpenMPI() {
    if [ ! -s "$LIB_INSTALL_DIR/$1/lib/libmpi.so" ]; then
        wgetSource $1
        CC=$CC_VERSION CXX=$CXX_VERSION FC=$FC_VERSION  \
        ./configure --prefix=$LIB_INSTALL_DIR/$1 &>$LOG_DIR/$1.conf.log
        makeInstall $1
        if [ ! -s $HOME/.bashrc.autoInstall.bak ];then
            echo '' >> $HOME/.bashrc
            echo "#for $1" >> $HOME/.bashrc
            echo 'export PATH='$LIB_INSTALL_DIR'/'$1'/bin:$PATH' >> $HOME/.bashrc
            echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$1'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
        fi
    fi
    export LD_LIBRARY_PATH=$LIB_INSTALL_DIR/$1/lib:$LD_LIBRARY_PATH
}

# Install zlib
getZilb() {
    if [ ! -s "$LIB_INSTALL_DIR/$1/lib/libz.a" ]; then
        wgetSource $1
        CC=$CC_VERSION CXX=$CXX_VERSION FC=$FC_VERSION  \
        ./configure --prefix=$LIB_INSTALL_DIR/$1 &>$LOG_DIR/$1.conf.log
        makeInstall $1
        if [ ! -s $HOME/.bashrc.autoInstall.bak ];then
            echo '' >> $HOME/.bashrc
            echo "#for $1" >> $HOME/.bashrc
            echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$1'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
        fi
    fi
    export LD_LIBRARY_PATH=$LIB_INSTALL_DIR/$1/lib:$LD_LIBRARY_PATH
}

# Install jasper
getJasper() {
    if [ "$OS_RELEASE" = "ubuntu" ]; then
        TEMP_JASPER_LIB_DIR="$LIB_INSTALL_DIR/$1/lib"
    elif [ "$OS_RELEASE" = "centos" ]; then
        TEMP_JASPER_LIB_DIR="$LIB_INSTALL_DIR/$1/lib64"
    fi
    if [ ! -s "$TEMP_JASPER_LIB_DIR/libjasper.so" ]; then
        wgetSource $1
        CC=$CC_VERSION CXX=$CXX_VERSION FC=$FC_VERSION \
        cmake -G "Unix Makefiles" \
            -DALLOW_IN_SOURCE_BUILD=TRUE \
            -DCMAKE_BUILD_TYPE=Release \
            -DJAS_ENABLE_DOC=false \
            -DCMAKE_INSTALL_PREFIX=$LIB_INSTALL_DIR/$1 \
            &>$LOG_DIR/$1.conf.log
        makeInstall $1
        if [ ! -s $HOME/.bashrc.autoInstall.bak ];then
            echo '' >> $HOME/.bashrc
            echo "#for $1" >> $HOME/.bashrc
            echo "export JASPER=$LIB_INSTALL_DIR/$1" >> $HOME/.bashrc
            echo "export JASPERLIB=$TEMP_JASPER_LIB_DIR" >> $HOME/.bashrc
            echo "export JASPERINC=$LIB_INSTALL_DIR/$1/include" >> $HOME/.bashrc
            echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$1'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
        fi
    fi
    export JASPER=$LIB_INSTALL_DIR/$1
    export JASPERLIB=$TEMP_JASPER_LIB_DIR
    export JASPERINC=$LIB_INSTALL_DIR/$1/include
    export LD_LIBRARY_PATH=$TEMP_JASPER_LIB_DIR:$LD_LIBRARY_PATH
}

# Install hdf5
getHDF5() {
    if [ ! -s "$LIB_INSTALL_DIR/$1/lib/libhdf5.a" ]; then
        export LDFLAGS=-L$LIB_INSTALL_DIR/$ZLIB_VERSION/lib
        export CPPFLAGS=-I$LIB_INSTALL_DIR/$ZLIB_VERSION/include
        wgetSource $1
        CC=$CC_VERSION CXX=$CXX_VERSION FC=$FC_VERSION  \
            ./configure                                 \
                --prefix=$LIB_INSTALL_DIR/$HDF5_VERSION     \
                --with-zlib=$LIB_INSTALL_DIR/$ZLIB_VERSION  \
                --enable-fortran --enable-cxx \
                &>$LOG_DIR/$1.conf.log
            makeInstall $1
        if [ ! -s $HOME/.bashrc.autoInstall.bak ];then
            echo '' >> $HOME/.bashrc
            echo "#for $1" >> $HOME/.bashrc
            echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$1'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
            echo "export HDF5=$LIB_INSTALL_DIR/$HDF5_VERSION" >> $HOME/.bashrc
        fi
    fi
    export LD_LIBRARY_PATH=$LIB_INSTALL_DIR/$1/lib:$LD_LIBRARY_PATH
    export HDF5=$LIB_INSTALL_DIR/$HDF5_VERSION
}

# Install hdf5 with Parallel I/O Support
getHDF5withParallel() {
    if [ ! -s "$LIB_INSTALL_DIR/$1/lib/libhdf5.a" ]; then
        export LDFLAGS=-L$LIB_INSTALL_DIR/$ZLIB_VERSION/lib
        export CPPFLAGS=-I$LIB_INSTALL_DIR/$ZLIB_VERSION/include
        wgetSource $1
        CC=$MPICC_VERSION CXX=$MPICXX_VERSION FC=$MPIFC_VERSION  \
            ./configure                                 \
                --prefix=$LIB_INSTALL_DIR/$HDF5_VERSION     \
                --with-zlib=$LIB_INSTALL_DIR/$ZLIB_VERSION  \
                --enable-fortran --enable-parallel --enable-shared \
                &>$LOG_DIR/$1.conf.log
            makeInstall $1
        if [ ! -s $HOME/.bashrc.autoInstall.bak ];then
            echo '' >> $HOME/.bashrc
            echo "#for $1" >> $HOME/.bashrc
            echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$1'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
            echo "export HDF5=$LIB_INSTALL_DIR/$HDF5_VERSION" >> $HOME/.bashrc
        fi
    fi
    export LD_LIBRARY_PATH=$LIB_INSTALL_DIR/$1/lib:$LD_LIBRARY_PATH
    export HDF5=$LIB_INSTALL_DIR/$HDF5_VERSION
}

# Install netcdf
getNetCDF() {
    if [ ! -s "$LIB_INSTALL_DIR/$1/include/netcdf.inc" ]; then
        export CPPFLAGS=-I$LIB_INSTALL_DIR/$HDF5_VERSION/include
        export LDFLAGS=-L$LIB_INSTALL_DIR/$HDF5_VERSION/lib
        export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$LIB_INSTALL_DIR/$HDF5_VERSION/lib
        wgetSource $1

        CC=$CC_VERSION CXX=$CXX_VERSION FC=$FC_VERSION  \
        ./configure --prefix=$LIB_INSTALL_DIR/$NETCDF_VERSION --disable-dap &>$LOG_DIR/$1.conf.log

        makeInstall $1

        export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$LIB_INSTALL_DIR/$1/lib
        export CPPFLAGS=-I$LIB_INSTALL_DIR/$1/include
        export LDFLAGS=-L$LIB_INSTALL_DIR/$1/lib
        wgetSource $2

        if [ NETCDF_FORTRAN_VERSION == "netcdf-fortran-4.4.5" ]; then
            CC=$CC_VERSION CXX=$CXX_VERSION FC=$FC_VERSION  \
            FCFLAGS="-w -fallow-argument-mismatch -O2" \
            FFLAGS="-w -fallow-argument-mismatch -O2" \
            ./configure --prefix=$LIB_INSTALL_DIR/$NETCDF_VERSION &>$LOG_DIR/$2.conf.log
        else
            CC=$CC_VERSION CXX=$CXX_VERSION FC=$FC_VERSION  \
            ./configure --prefix=$LIB_INSTALL_DIR/$NETCDF_VERSION &>$LOG_DIR/$2.conf.log
        fi

        makeInstall $2
        if [ ! -s $HOME/.bashrc.autoInstall.bak ];then
            echo '' >> $HOME/.bashrc
            echo "#for $1" >> $HOME/.bashrc
            echo 'export PATH='$LIB_INSTALL_DIR'/'$1'/bin:$PATH' >> $HOME/.bashrc
            echo "export NETCDF=$LIB_INSTALL_DIR/$NETCDF_VERSION" >> $HOME/.bashrc
            echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$1'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
        fi
    fi
    export PATH=$LIB_INSTALL_DIR/$1/bin:$PATH
    export LD_LIBRARY_PATH=$LIB_INSTALL_DIR/$1/lib:$LD_LIBRARY_PATH
    export NETCDF=$LIB_INSTALL_DIR/$NETCDF_VERSION
}

# Install NetCDF with Parallel I/O Support
getNetCDFwithParallel() {
    if [ ! -s "$LIB_INSTALL_DIR/$1/include/netcdf.inc" ]; then
        export CPPFLAGS=-I$LIB_INSTALL_DIR/$HDF5_VERSION/include
        export LDFLAGS=-L$LIB_INSTALL_DIR/$HDF5_VERSION/lib
        export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}$LIB_INSTALL_DIR/$HDF5_VERSION/lib
        wgetSource $1

        CC=$MPICC_VERSION CXX=$MPICXX_VERSION FC=$MPIFC_VERSION  \
        ./configure --prefix=$LIB_INSTALL_DIR/$NETCDF_VERSION --enable-parallel --disable-dap \
        &>$LOG_DIR/$1.conf.log

        makeInstall $1

        export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$LIB_INSTALL_DIR/$1/lib
        export CPPFLAGS=-I$LIB_INSTALL_DIR/$1/include
        export LDFLAGS=-L$LIB_INSTALL_DIR/$1/lib
        wgetSource $2

        CC=$MPICC_VERSION CXX=$MPICXX_VERSION FC=$MPIFC_VERSION  \
        ./configure --prefix=$LIB_INSTALL_DIR/$NETCDF_VERSION &>$LOG_DIR/$2.conf.log

        makeInstall $2
        if [ ! -s $HOME/.bashrc.autoInstall.bak ];then
            echo '' >> $HOME/.bashrc
            echo "#for $1" >> $HOME/.bashrc
            echo 'export PATH='$LIB_INSTALL_DIR'/'$1'/bin:$PATH' >> $HOME/.bashrc
            echo "export NETCDF=$LIB_INSTALL_DIR/$NETCDF_VERSION" >> $HOME/.bashrc
            echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$1'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
        fi
    fi
    export PATH=$LIB_INSTALL_DIR/$1/bin:$PATH
    export LD_LIBRARY_PATH=$LIB_INSTALL_DIR/$1/lib:$LD_LIBRARY_PATH
    export NETCDF=$LIB_INSTALL_DIR/$NETCDF_VERSION
}

# Install bison
getBison() {
    if [ ! -s "$LIB_INSTALL_DIR/$1/bin/bison" ]; then
        wgetSource $1
        CC=$CC_VERSION CXX=$CXX_VERSION FC=$FC_VERSION  \
        ./configure --prefix=$LIB_INSTALL_DIR/$1 &>$LOG_DIR/$1.conf.log
        makeInstall $1
        if [ ! -s $HOME/.bashrc.autoInstall.bak ];then
            echo '' >> $HOME/.bashrc
            echo "#for $1" >> $HOME/.bashrc
            echo 'export PATH='$LIB_INSTALL_DIR'/'$1'/bin:$PATH' >> $HOME/.bashrc
            echo 'export PATH='$LIB_INSTALL_DIR'/'$1':$PATH' >> $HOME/.bashrc
            echo "export YACC='yacc -d'" >> $HOME/.bashrc
        fi
    fi
    export PATH=$LIB_INSTALL_DIR/$1:$PATH
    export PATH=$LIB_INSTALL_DIR/$1/bin:$PATH
    export YACC='yacc -d'
}

# Install flex
getFlex() {
    if [ ! -s "$LIB_INSTALL_DIR/$1/bin/flex" ];then
        wgetSource $1
        ./autogen.sh &>$LOG_DIR/$1.autogen.log
        # TODO Note: version 2.6.5
        # CFLAGS='-g -O2 -D_GNU_SOURCE' because a bug of version 2.6.4
        # and will be fixed in 2.6.5
        CC=$CC_VERSION CXX=$CXX_VERSION FC=$FC_VERSION  \
        ./configure CFLAGS='-g -O2 -D_GNU_SOURCE' --prefix=$LIB_INSTALL_DIR/$1 &>$LOG_DIR/$1.conf.log
        makeInstall $1
        if [ ! -s $HOME/.bashrc.autoInstall.bak ];then
            echo '' >> $HOME/.bashrc
            echo "#for $1" >> $HOME/.bashrc
            echo 'export PATH='$LIB_INSTALL_DIR'/'$1'/bin:$PATH' >> $HOME/.bashrc
            echo 'export FLEX='$LIB_INSTALL_DIR'/'$1'/bin/flex' >> $HOME/.bashrc
            echo "export FLEX_LIB_DIR=$LIB_INSTALL_DIR/$1/lib" >> $HOME/.bashrc
            echo "export LD_LIBRARY_PATH=$LIB_INSTALL_DIR/$1/lib:"'$LD_LIBRARY_PATH' >> $HOME/.bashrc
        fi
    fi
    export PATH=$LIB_INSTALL_DIR/$1/bin:$PATH
    export FLEX=$LIB_INSTALL_DIR/$1/bin/flex
    export FLEX_LIB_DIR=$LIB_INSTALL_DIR/$1/lib
    export LD_LIBRARY_PATH=$LIB_INSTALL_DIR/$1/lib:$LD_LIBRARY_PATH
}

# Install PnetCDF
getPnetCDF() {
    if [ ! -s "$LIB_INSTALL_DIR/$1/bin/ncmpidiff" ];then
        wgetSource $1
        autoreconf -i

        CC=$MPICC_VERSION CXX=$MPICXX_VERSION FC=$MPIFC_VERSION \
        ./configure --prefix=$LIB_INSTALL_DIR/$1                \
        CFLAGS=-fPIC --enable-shared &>$LOG_DIR/$1.conf.log
        #--enable-netcdf4           \
        #--with-netcdf4=$LIB_INSTALL_DIR/$NETCDF_VERSION         \

        makeInstall $1
        if [ ! -s $HOME/.bashrc.autoInstall.bak ];then
            echo '' >> $HOME/.bashrc
            echo "#for $1" >> $HOME/.bashrc
            echo "export PNETCDF=$LIB_INSTALL_DIR/$1" >> $HOME/.bashrc
            echo 'export PATH='$LIB_INSTALL_DIR'/'$1'/bin:$PATH' >> $HOME/.bashrc
            echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$1'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
        fi
    fi
    export PNETCDF=$LIB_INSTALL_DIR/$1
    export PATH=$LIB_INSTALL_DIR/$1/bin:$PATH
    export LD_LIBRARY_PATH=$LIB_INSTALL_DIR/$1/lib:$LD_LIBRARY_PATH
}

# Install PIO
getPIO() {
    if [ ! -s "$LIB_INSTALL_DIR/$1/lib/libpiof.a" ];then
        wgetSource $1

        # some bugs in openmpi-4.0.3 in ubuntu 2004
        #CC=mpicc.mpich CXX=mpic++.mpich FC=mpifort.mpich \
        #cmake . \
        #    -DNetCDF_C_PATH=$LIB_INSTALL_DIR/$NETCDF_VERSION \
        #    -DPnetCDF_PATH=$LIB_INSTALL_DIR/$PNETCDF_VERSION \
        #    -DPnetCDF_Fortran_INCLUDE_DIR=$LIB_INSTALL_DIR/$PNETCDF_VERSION/include \
        #    -DPIO_HDF5_LOGGING=On -DPIO_USE_MALLOC=On \
        #    -DCMAKE_INSTALL_PREFIX=$LIB_INSTALL_DIR/$1 \
        #    &>$LOG_DIR/$1.conf.log
        #    #-DNetCDF_Fortran_PATH=$LIB_INSTALL_DIR/$NETCDF_VERSION \

        export NETCDF_PATH=$LIB_INSTALL_DIR/$NETCDF_VERSION
        export PNETCDF_PATH=$LIB_INSTALL_DIR/$PNETCDF_VERSION
        export CPPFLAGS="-I$LIB_INSTALL_DIR/$PNETCDF_VERSION/include -I$LIB_INSTALL_DIR/$NETCDF_VERSION/include"
        export LDFLAGS="-L$LIB_INSTALL_DIR/$PNETCDF_VERSION/lib  -L$LIB_INSTALL_DIR/$NETCDF_VERSION/lib"
        CC=$MPICC_VERSION FC=$MPIFC_VERSION ./configure --enable-netcdf4 \
        --with-netcdf=$LIB_INSTALL_DIR/$NETCDF_VERSION --prefix=$LIB_INSTALL_DIR/$1 &>$LOG_DIR/$1.config.log

        make            &>$LOG_DIR/$1.make.log
        make install    &>$LOG_DIR/$1.install.log

        if [ ! -s $HOME/.bashrc.autoInstall.bak ];then
            echo '' >> $HOME/.bashrc
            echo "#for $1" >> $HOME/.bashrc
            echo "export PIO=$LIB_INSTALL_DIR/$1" >> $HOME/.bashrc
            echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$1'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
        fi
    fi
    export PIO=$LIB_INSTALL_DIR/$1
    export LD_LIBRARY_PATH=$LIB_INSTALL_DIR/$1/lib:$LD_LIBRARY_PATH
}

# Install WRF/WRF-chem
getWRF() {
    if [ ! -s $HOME/.bashrc.autoInstall.bak ];then
        echo '' >> $HOME/.bashrc
        echo "#for $WRF_VERSION" >> $HOME/.bashrc
        echo 'export WRFIO_NCD_LARGE_FILE_SUPPORT=1' >> $HOME/.bashrc
        echo "export WRF_CHEM=$WRF_CHEM_SETTING" >> $HOME/.bashrc
        echo "export WRF_KPP=$WRF_KPP_SETTING" >> $HOME/.bashrc
        mv $HOME/.bashrc.autoInstall.bak.temp $HOME/.bashrc.autoInstall.bak
    fi
    export WRFIO_NCD_LARGE_FILE_SUPPORT=1
    export WRF_CHEM=$WRF_CHEM_SETTING
    export WRF_KPP=$WRF_KPP_SETTING
    flag=0
    for file in $(ls $HOME/$WRF_VERSION/main/*.exe 2>/dev/null)
    do
        flag=$(( $flag + 1 ))
    done
    if [[ $flag -ne 4 ]];then
        echo "Download WRF"
        if [ ! -s $HOME/$WRF_VERSION/configure ];then
            if [ ! -s $SRC_DIR/$WRF_VERSION.tar.gz ];then
                wgetSource $1
                cd $HOME && mv $SRC_DIR/$1 $HOME/
            else
                tar -xf $1.tar.gz -C $HOME/
            fi
        fi
        cd $HOME/$1
        echo " ============================================================== "
        echo -e "\nClean\n"
        ./clean -a &>/dev/null
        ulimit -s unlimited

        if [ "$CC_VERSION" == "gcc" ];then
            echo " ============================================================== "
            echo -e "\nConfigure WRF: 34. (dmpar) GNU(gfortran/gcc)"
            echo -e '34\n1' | ./configure
            echo " ============================================================== "
            sed -i 's/-lnetcdff -lnetcdf/-lnetcdff -lnetcdf -lgomp -lpthread/g' ./configure.wrf
            sed -i '32s/-ffree-form -O -fno-second-underscore -fconvert=big-endian -frecord-marker=4/-ffree-form -O -fno-second-underscore -fconvert=big-endian -frecord-marker=4 -std=legacy/g' ./configure.wrf
        elif [ "$CC_VERSION" == "icc" ];then
            echo " ============================================================== "
            echo -e "\nConfigure WRF: 15. (dmpar) INTEL (ifort/icc)"
            echo -e '15\n1' | ./configure
            echo " ============================================================== "
            sed -i 's/-lnetcdff -lnetcdf/-lnetcdff -lnetcdf -lgomp -lpthread -liomp5/g' ./configure.wrf
        fi

        echo -e "\nCompile WRF"
        ./compile $WRF_WPS_OPENMP em_real &> $LOG_DIR/WRF_em_real.log
        flag=0
        for file in $(ls $HOME/$WRF_VERSION/main/*.exe)
        do
            flag=$(( $flag + 1 ))
        done
        if [[ $flag -eq 4 ]];then
            echo -e "\n\nWRF install ${green}successful${plain}\n"
            WRF_INSTALL_SUCCESS_FLAG=$(( $WRF_INSTALL_SUCCESS_FLAG + 1 ))
        else
            echo -e "\nInstall WRF ${red}failed${plain} please check errors in logs($LOG_DIR/)\n"
            exit 1
        fi
    else
        echo -e "\nWRF already installed\n"
        WRF_INSTALL_SUCCESS_FLAG=$(( $WRF_INSTALL_SUCCESS_FLAG + 1 ))
    fi
}

# Install WRFplus
getWRFplus() {
    flag=0
    for file in $(ls $HOME/$WRFplus_VERSION/run/*.exe 2>/dev/null)
    do
        flag=$(( $flag + 1 ))
    done
    if [[ $flag -ne 1 ]];then
        echo "Install WRFplus"
        if [ ! -s $HOME/$WRFplus_VERSION/configure ];then
            if [ ! -s $SRC_DIR/$WRF_VERSION.tar.gz ];then
                wgetSource $WRF_VERSION
                cd $HOME && cp -r $SRC_DIR/$WRF_VERSION $HOME/$WRFplus_VERSION
            else
                cp -r $HOME/$WRF_VERSION $HOME/$WRFplus_VERSION
            fi
        fi
        cd $HOME/$1
        echo " ============================================================== "
        echo -e "\nClean\n"
        ./clean -a &>/dev/null
        ulimit -s unlimited

        if [ "$CC_VERSION" == "gcc" ];then
            echo " ============================================================== "
            echo -e "\nConfigure wrfplus: 18. (dmpar)   GNU (gfortran/gcc)"
            echo '18' | ./configure wrfplus
            echo " ============================================================== "
        elif [ "$CC_VERSION" == "icc" ];then
            echo " ============================================================== "
            echo -e "\nConfigure wrfplus:  8. (dmpar)   INTEL (ifort/icc)"
            echo '8' | ./configure wrfplus
            echo " ============================================================== "
        fi

        echo -e "\nCompile wrfplus"
        sed -i 's/-lnetcdff -lnetcdf/-lnetcdff -lnetcdf -lgomp/g' ./configure.wrf
        ./compile $WRF_WPS_OPENMP wrfplus &> $LOG_DIR/WRFplus_compile.log
        export WRFPLUS_DIR=$HOME/$1
        echo "export WRFPLUS_DIR=$HOME/$1" >> $HOME/.bashrc
        flag=0
        for file in $(ls $HOME/$WRFplus_VERSION/run/*.exe)
        do
            flag=$(( $flag + 1 ))
        done
        if [[ $flag -eq 1 ]];then
            echo -e "\n\nWRFDA install ${green}successful${plain}\n"
            WRF_INSTALL_SUCCESS_FLAG=$(( $WRF_INSTALL_SUCCESS_FLAG + 1 ))
        else
            echo -e "\nInstall WRFplus ${red}failed${plain} please check errors in logs($LOG_DIR/)\n"
            exit 1
        fi
    else
        echo -e "\nWRFplus has been installed\n"
        WRF_INSTALL_SUCCESS_FLAG=$(( $WRF_INSTALL_SUCCESS_FLAG + 1 ))
    fi
}

# Install WRFDA
getWRFDA() {
    flag=0
    for file in $(ls $HOME/$WRFDA_VERSION/var/build/*.exe 2>/dev/null)
    do
        flag=$(( $flag + 1 ))
    done
    for file in $(ls $HOME/$WRFDA_VERSION/var/obsproc/src/*.exe 2>/dev/null)
    do
        flag=$(( $flag + 1 ))
    done
    if [[ $flag -ne 44 ]];then
        echo "Install WRFDA"
        if [ ! -s $HOME/$WRFDA_VERSION/configure ];then
            if [ ! -s $SRC_DIR/$WRF_VERSION.tar.gz ];then
                wgetSource $1
                cd $HOME && mv $SRC_DIR/$WRF_VERSION $HOME/$WRFDA_VERSION
            else
                cp -r $HOME/$WRF_VERSION $HOME/$1
            fi
        fi
        cd $HOME/$1
        echo " ============================================================== "
        echo -e "\nClean\n"
        ./clean -a &>/dev/null
        ulimit -s unlimited

        if [ "$CC_VERSION" == "gcc" ];then
            echo " ============================================================== "
            echo -e "\nConfigure WRFDA: 18. (dmpar)   GNU (gfortran/gcc)"
            echo '18' | ./configure 4dvar
            echo " ============================================================== "
        elif [ "$CC_VERSION" == "icc" ];then
            echo " ============================================================== "
            echo -e "\nConfigure WRFDA:  8. (dmpar)    INTEL (ifort/icc)"
            echo '8' | ./configure 4dvar
            echo " ============================================================== "
        fi

        echo -e "\nCompile WRFDA with wrfplus"
        ./compile $WRF_WPS_OPENMP all_wrfvar >& $LOG_DIR/WRFDA_compile.log
        flag=0
        for file in $(ls $HOME/$WRFDA_VERSION/var/build/*.exe)
        do
            flag=$(( $flag + 1 ))
        done
        for file in $(ls $HOME/$WRFDA_VERSION/var/obsproc/src/*.exe 2>/dev/null)
        do
            flag=$(( $flag + 1 ))
        done
        if [[ $flag -eq 44 ]];then
            echo -e "\n\nWRFDA install ${green}successful${plain}\n"
            WRF_INSTALL_SUCCESS_FLAG=$(( $WRF_INSTALL_SUCCESS_FLAG + 1 ))
        else
            echo -e "\nInstall WRF ${red}failed${plain} please check errors in logs($LOG_DIR/)\n"
            exit 1
        fi
    else
        echo -e "\nWRFDA has been installed\n"
        WRF_INSTALL_SUCCESS_FLAG=$(( $WRF_INSTALL_SUCCESS_FLAG + 1 ))
    fi
}

# Install WRFHydro
getWRFHydro() {
    if [ ! -s $HOME/.bashrc.autoInstall.bak ];then
        echo '' >> $HOME/.bashrc
        echo "#for $WRF_VERSION" >> $HOME/.bashrc
        echo 'export WRFIO_NCD_LARGE_FILE_SUPPORT=1' >> $HOME/.bashrc
        echo "export WRF_CHEM=$WRF_CHEM_SETTING" >> $HOME/.bashrc
        echo "export WRF_KPP=$WRF_KPP_SETTING" >> $HOME/.bashrc
        mv $HOME/.bashrc.autoInstall.bak.temp $HOME/.bashrc.autoInstall.bak
    fi
    export WRF_HYDRO=1
    export WRFIO_NCD_LARGE_FILE_SUPPORT=1
    flag=0
    for file in $(ls $HOME/$WRF_VERSION/main/*.exe 2>/dev/null)
    do
        flag=$(( $flag + 1 ))
    done
    if [[ $flag -ne 4 ]];then
        echo "Download WRF"
        if [ ! -s $HOME/$WRF_VERSION/configure ];then
            if [ ! -s $SRC_DIR/$WRF_VERSION.tar.gz ];then
                wgetSource $1
                cd $HOME && mv $SRC_DIR/$1 $HOME/
            else
                tar -xf $1.tar.gz -C $HOME/
            fi
        fi
        cd $HOME/$1
        source hydro/template/setEnvar.sh
        echo " ============================================================== "
        echo -e "\nClean\n"
        ./clean -a &>/dev/null
        ulimit -s unlimited

        if [ "$CC_VERSION" == "gcc" ];then
            echo " ============================================================== "
            echo -e "\nConfigure WRF: 34. (dmpar) GNU(gfortran/gcc)"
            echo -e '34\n1' | ./configure
            echo " ============================================================== "
        elif [ "$CC_VERSION" == "icc" ];then
            echo " ============================================================== "
            echo -e "\nConfigure WRF: 15. (dmpar) INTEL (ifort/icc)"
            echo -e '15\n1' | ./configure
            echo " ============================================================== "
        fi

        sed -i 's/-lnetcdff -lnetcdf/-lnetcdff -lnetcdf -lgomp/g' ./configure.wrf
        ./compile $WRF_WPS_OPENMP em_real &> $LOG_DIR/WRF_em_real.log
        flag=0
        for file in $(ls $HOME/$WRF_VERSION/main/*.exe)
        do
            flag=$(( $flag + 1 ))
        done
        if [[ $flag -eq 4 ]];then
            echo -e "\n\nWRF install ${green}successful${plain}\n"
            WRF_INSTALL_SUCCESS_FLAG=$(( $WRF_INSTALL_SUCCESS_FLAG + 1 ))
        else
            echo -e "\nInstall WRF ${red}failed${plain} please check errors in logs($LOG_DIR/)\n"
            exit 1
        fi
    else
        echo -e "\nWRF already installed\n"
        WRF_INSTALL_SUCCESS_FLAG=$(( $WRF_INSTALL_SUCCESS_FLAG + 1 ))
    fi
}

# Install WPS
getWPS() {
    flag=0
    export WRF_DIR=$HOME/$WRF_VERSION
    for file in $(ls $HOME/$WPS_VERSION/util/*.exe 2>/dev/null)
    do
        flag=$(( $flag + 1 ))
    done
    for file in $(ls $HOME/$WPS_VERSION/*.exe 2>/dev/null)
    do
        flag=$(( $flag + 1 ))
    done
    if [[ $flag -ne 11 ]];then
        echo -e "\nInstall WPS"
        if [ ! -s $HOME/$WPS_VERSION/configure ];then
            if [ ! -s $SRC_DIR/$WPS_VERSION.tar.gz ];then
                wgetSource $1
                cd $HOME && mv $SRC_DIR/$1 $HOME/
            fi
        fi
        cd $HOME/$1
        echo " ============================================================== "
        echo -e "\nClean\n"
        ./clean -a &>/dev/null

        sed -i 's/standard_wrf_dirs="WRF WRF-4.0.3 WRF-4.0.2 WRF-4.0.1 WRF-4.0 WRFV3 WRF-4.1.2"/standard_wrf_dirs="WRF WRF-4.2 WRF-4.3 WRF-4.0.3 WRF-4.0.2 WRF-4.0.1 WRF-4.0 WRFV3 WRF-4.1.2"/g' ./configure

        if [ "$CC_VERSION" == "gcc" ];then
            echo " ============================================================== "
            echo -e "\nConfigure WPS: 1. Linux x86_64,gfortran (serial)"
            echo '1' | ./configure &>$LOG_DIR/$1.config.log
            echo " ============================================================== "
            sed -i 's/-lnetcdff -lnetcdf/-lnetcdff -lnetcdf -lgomp/g' ./configure.wps
        elif [ "$CC_VERSION" == "icc" ];then
            echo " ============================================================== "
            echo -e "\nConfigure WPS: 19. Linux x86_64, Intel compiler (dmpar)"
            echo '19' | ./configure &>$LOG_DIR/$1.config.log
            echo " ============================================================== "
            sed -i 's/-lnetcdff -lnetcdf/-lnetcdff -lnetcdf -lgomp -lpthread -liomp5/g' ./configure.wps
            sed -i 's/DM_FC               = mpifort/DM_FC               = mpiifort/g' ./configure.wps
            sed -i 's/DM_CC               = mpicc/DM_CC               = mpiicc/g' ./configure.wps
        fi

        echo -e "\nCompile WPS"
        ./compile &> $LOG_DIR/$1.compile.log
        flag=0
        for file in $(ls $HOME/$WPS_VERSION/util/*.exe)
        do
            flag=$(( $flag + 1 ))
        done
        for file in $(ls $HOME/$WPS_VERSION/*.exe)
        do
            flag=$(( $flag + 1 ))
        done
        if [[ $flag -eq 11 ]];then
            echo -e "\n\nWPS install ${green}successful${plain}\n"
            WRF_INSTALL_SUCCESS_FLAG=$(( $WRF_INSTALL_SUCCESS_FLAG + 1 ))
        else
            echo -e "Install WPS ${red}failed${plain}, please check errors in logs($LOG_DIR/)\n"
        fi
    else
        echo -e "\nWPS already installed\n"
        WRF_INSTALL_SUCCESS_FLAG=$(( $WRF_INSTALL_SUCCESS_FLAG + 1 ))
    fi
}

checkFinishWRF() {
    echo "# END for WRF or MPAS automatic installation" >> $HOME/.bashrc
    echo "###############################################" >> $HOME/.bashrc

    if [ "$WRF_INSTALL_FLAG" -eq "5" ];then
        # TODO : finish this feature
        echo -e "\nAll install ${green}successful${plain}\n"
        echo -e "\nEnjoy it\n"
        echo -e "\n Check if the installation is correct \n"
        rm $HOME/.bashrc.autoInstall.bak.temp
    elif [ $WRF_INSTALL_SUCCESS_FLAG -eq $WRF_INSTALL_SUCCESS_FLAG_SHOULD_BE ];then
        echo -e "\nAll install ${green}successful${plain}\n"
        ls -d $HOME/$WPS_VERSION --color=auto
        ls -d $HOME/$WRF_VERSION --color=auto
        if [ $WRF_INSTALL_FLAG -eq 4 ];then
            ls -d $HOME/$WRFplus_VERSION --color=auto
            ls -d $HOME/$WRFDA_VERSION --color=auto
        fi
        echo -e "\nClean"
        rm $SRC_DIR -r
        rm $LOG_DIR -r
        echo -e "\nEnjoy it\n"
    else
        echo -e "\nInstall ${red}failed${plain} please check errors\n"
        cp $HOME/.bashrc $HOME/.bashrc.WRF.bak
        cp $HOME/.bashrc.autoInstall.bak $HOME/.bashrc
    fi
}

getMPAS() {
    cd $HOME
    echo " ============================================================== "
    echo -e "\nInstall MPAS\n"
    if [ ! -s $SRC_DIR/$MPAS_VERSION.tar.gz ];then
        echo -e "\nDownload MPAS\n"
        wgetSource $1
        cd $HOME && mv $SRC_DIR/$1 $HOME/
    fi
    cp $1 MPAS-init_atmosphere -r
    cp $1 MPAS-atmosphere -r

    export PIO=$LIB_INSTALL_DIR/$PIO_VERSION
    export PNETCDF_PATH=$LIB_INSTALL_DIR/$PNETCDF_VERSION

    echo -e "\nCompile MPAS-init_atmosphere\n"
    cd $HOME/MPAS-init_atmosphere
    make $FC_VERSION CORE=init_atmosphere OPENMP=true &>$LOG_DIR/MPAS-init_atmosphere.log

    echo -e "\nCompile MPAS-atmosphere\n"
    cd $HOME/MPAS-atmosphere
    make $FC_VERSION CORE=atmosphere OPENMP=true &>$LOG_DIR/MPAS-atmosphere.log
}

getRegRM4() {
    wget https://github.com/ictp-esp/RegCM/archive/refs/tags/4.7.9.tar.gz
}

# ---------------------------------------

envInstall() {
    getInfo
    # checkRoot
    getDir
    getWRFVersion
    getWPSVersion
    getCompiler
    getOpenmp
    # getTest
    setSources
    checkInfo
    if [ $SERVER_FLAG -eq 0 ];then
        checkMem
        getLibrary
    fi
    creatLogs
    getOpenMPI  $OPENMPI_VERSION
    getZilb     $ZLIB_VERSION
    getJasper   $JASPER_VERSION
    getHDF5     $HDF5_VERSION
    getNetCDF   $NETCDF_VERSION $NETCDF_FORTRAN_VERSION
}

wrfInstall() {
    envInstall
    getWRF      $WRF_VERSION
    getWPS      $WPS_VERSION
}

wrfChemInstall() {
    envInstall
    getBison    $BISON_VERSION
    getFlex     $FLEX_VERSION
    if [ "$OS_RELEASE" == "centos" ];then
        WRF_CHEM_SETTING=1
        WRF_KPP_SETTING=1
    elif [ "$OS_RELEASE" == "ubuntu" ];then
        WRF_CHEM_SETTING=1
        WRF_KPP_SETTING=0
    fi
    getWRF      $WRF_VERSION
    getWPS      $WPS_VERSION
}

wrfHydroInstall() {
    envInstall
    getWRFHydro $WRF_VERSION
    getWPS      $WPS_VERSION
}

wrfdaInstall() {
    wrfInstall
    getWRFplus  $WRFplus_VERSION
    getWRFDA    $WRFDA_VERSION
}

mpasInstall() {
    envInstall
    getPnetCDF  $PNETCDF_VERSION
    getPIO      $PIO_VERSION
    getMPAS     $MPAS_VERSION
}

wrfFeatureInstall() {
    if   [[ $WRF_INSTALL_FLAG -eq 0 ]];then
        envInstall
    elif [[ $WRF_INSTALL_FLAG -eq 1 ]];then
        wrfInstall
    elif [[ $WRF_INSTALL_FLAG -eq 2 ]];then
        wrfChemInstall
    elif [[ $WRF_INSTALL_FLAG -eq 3 ]];then
        wrfHydroInstall
    elif [[ $WRF_INSTALL_FLAG -eq 4 ]];then
        wrfdaInstall
    elif [[ $WRF_INSTALL_FLAG -eq 5 ]];then
        mpasInstall
    fi
}


#-------functions end--------

if [ "$1" == "resetEnv" ]; then
    reSetEnv
elif [ "$1" == "server" ]; then
    SERVER_FLAG="1"
    checkSystemInfo
    chooseFeatures
    wrfFeatureInstall
    checkFinishWRF
else
    checkSystemInfo
    chooseFeatures
    wrfFeatureInstall
    checkFinishWRF
fi