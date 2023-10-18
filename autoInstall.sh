#!/bin/bash

# Author: Yongpeng Zhang - zhangyp6603@outlook.com
#
# Description:  install WPS,WRF,WRFDA,WRF-Chem.
#               If you have any questions, send an e-mail or open an issue.
# Start by
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/jokervTv/auto-install-WRFV4/master/autoInstall.sh)"
# Or (faster in China)
# bash -c "$(curl -fsSL https://gitee.com/jokervTv/auto-install-WRFV4/raw/master/autoInstall.sh)"

#--------------------------------------

# System info
OS_RELEASE="ubuntu"
PACKAGE_MANAGER="apt-get"
MAKE_OPENMP="-j4"
WRF_WPS_OPENMP='-j 4'
TEST_FLAG="0"
SERVER_FLAG="0"
LIB_INSTALL_DIR="$HOME/.WRF_LIB"
LOG_DIR="$HOME/log-wrf-mpas"
SRC_DIR="$HOME/src-wrf-mpas"
DOWNLOAD_URL="http://wrflib.jokervtv.top"

CC_VERSION="gcc"
FC_VERSION="gfortran"
CXX_VERSION="g++"
# For ubuntu 2004, there are some bug with openmpi 4.0.3, so change to mpich
MPICC_VERSION="mpicc"
MPIFC_VERSION="mpifort"
MPICXX_VERSION="mpic++"

# Version
OPENMPI_VERSION="mpich-4.1.1"
ZLIB_VERSION="zlib-1.2.11"
JASPER_VERSION="jasper-2.0.33"
HDF5_VERSION="hdf5-1.12.2"
NETCDF_VERSION="netcdf-c-4.9.1"
NETCDF_FORTRAN_VERSION="netcdf-fortran-4.6.0"
BISON_VERSION="bison-3.8.2" #http://ftpmirror.gnu.org/bison/
FLEX_VERSION="flex-2.5.39" #https://github.com/westes/flex
WPS_VERSION="WPS-4.2" #https://github.com/wrf-model/WPS
WRF_VERSION="WRF-4.2" #https://github.com/wrf-model/WRF
WRFplus_VERSION="WRFplus-4.2" #https://github.com/wrf-model/WRF
WRFDA_VERSION="WRFDA-4.2" #https://github.com/wrf-model/WRF
WRF_HYDRO_VERSION="wrf_hydro_nwm_public-5.2.0" #https://github.com/NCAR/wrf_hydro_nwm_public
PIO_VERSION="pio-1.7.4" #https://github.com/NCAR/ParallelIO/
PNETCDF_VERSION="pnetcdf-1.11.2" #https://github.com/Parallel-NetCDF/PnetCDF
MPAS_VERSION="MPAS-Model-7.0" #https://github.com/MPAS-Dev/MPAS-Model

# Check flag
WRF_INSTALL_FLAG=1
WRF_INSTALL_SUCCESS_FLAG=0
WRF_CHEM_SETTING=0
WRF_KPP_SETTING=0

# Read parameter
READ_INSTALL_DIR=""
READ_WRF_VERSION=999
READ_WPS_VERSION=999
READ_COMPILER_ID=999
READ_WRF_FEATURE=999
READ_SOFT_SOURCE=999
READ_CORE_NUMBER=999

#--------------------------------------
#-------functions start--------
#--------------------------------------

# download src of lib
wgetSource() {
    cd $SRC_DIR

    if [[ ! -f $1.tar.gz.sha256 ]]; then
        wget $DOWNLOAD_URL/$1.tar.gz.sha256
    fi

    if [[ -f $1.tar.gz ]]; then
        echo " check $1"
        sha256sum -c $1.tar.gz.sha256 --status
        status=$?
        if [[ status -ne 0 ]]; then
            rm -f $SRC_DIR/$1.tar.gz
            echo " Download $1"
            wget $DOWNLOAD_URL/$1.tar.gz
        fi
    else
        echo " Download $1"
        wget $DOWNLOAD_URL/$1.tar.gz

    fi

    rm -rf $SRC_DIR/$1
    echo " Extract $1"
    tar -xf $1.tar.gz
    cd $SRC_DIR/$1
    echo " Configure & make $1"
}

# receivec a lib name as $1 to install
makeInstall() {
    make $MAKE_OPENMP &>$LOG_DIR/$1.make.log
    make install      &>$LOG_DIR/$1.install.log
}

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

showHelp() {
    echo "Description:  install WPS,WRF,WRFDA,WRF-Chem."
    echo ""
    echo "Usage:"
    echo "test.sh [-j S_DIR] [-m D_DIR]"
    echo "Description:"
    echo "S_DIR,the path of source."
    echo "D_DIR,the path of destination."
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

    if [[ -z $READ_INSTALL_DIR ]]; then
        read READ_INSTALL_DIR
    fi

    if [[ -n $READ_INSTALL_DIR ]]; then
        LIB_INSTALL_DIR=$READ_INSTALL_DIR
    fi

    if [[ -z $LIB_INSTALL_DIR ]]; then
        echo -e "\n\n${red}Error${plain}: install path: $LIB_INSTALL_DIR is NULL, please check it!"
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
    echo "Which version of ${red}WRF${plain} do you want to use ? (defualt: 1)"
    echo ""
    echo "  0. 3.9.1.1"
    echo "  1. 4.2"
    echo "  2. 4.3"
    echo "  3. 4.4.2"
    echo "  4. 4.5"

    if [[ $READ_WRF_VERSION -eq 999 ]]; then
        read READ_WRF_VERSION
    fi

    if [[ -n $READ_WRF_VERSION ]]; then
        if [[ $READ_WRF_VERSION -eq 0 ]]; then
            WRF_VERSION="WRF-3.9.1.1"
            WRFplus_VERSION="WRFplus-3.9.1.1"
            WRFDA_VERSION="WRFDA-3.9.1.1"
        elif [[ $READ_WRF_VERSION -eq 1 ]]; then
            WRF_VERSION="WRF-4.2"
            WRFplus_VERSION="WRFplus-4.2"
            WRFDA_VERSION="WRFDA-4.2"
        elif [[ $READ_WRF_VERSION -eq 2 ]]; then
            WRF_VERSION="WRF-4.3"
            WRFplus_VERSION="WRFplus-4.3"
            WRFDA_VERSION="WRFDA-4.3"
        elif [[ $READ_WRF_VERSION -eq 3 ]]; then
            WRF_VERSION="WRF-4.4.2"
            WRFplus_VERSION="WRFplus-4.4.2"
            WRFDA_VERSION="WRFDA-4.4.2"
        elif [[ $READ_WRF_VERSION -eq 4 ]]; then
            WRF_VERSION="WRF-4.5"
            WRFplus_VERSION="WRFplus-4.5"
            WRFDA_VERSION="WRFDA-4.5"
        fi
    fi
}

getWPSVersion() {
    echo "============================================================"
    echo "Which version of ${red}WPS${plain} do you want to use ? (defualt: 1)"
    echo ""
    echo "  0. 3.9.1"
    echo "  1. 4.2"
    echo "  2. 4.3"
    echo "  3. 4.4"
    echo "  4. 4.5"

    if [[ $READ_WPS_VERSION -eq 999 ]]; then
        read READ_WPS_VERSION
    fi

    if [[ -n $READ_WPS_VERSION ]]; then
        if [[ $READ_WPS_VERSION -eq 0 ]]; then
            WPS_VERSION="WPS-3.9.1"
        elif [[ $READ_WPS_VERSION -eq 1 ]]; then
            WPS_VERSION="WPS-4.2"
        elif [[ $READ_WPS_VERSION -eq 2 ]]; then
            WPS_VERSION="WPS-4.3"
        elif [[ $READ_WPS_VERSION -eq 3 ]]; then
            WPS_VERSION="WPS-4.4"
        elif [[ $READ_WPS_VERSION -eq 4 ]]; then
            WPS_VERSION="WPS-4.5"
        fi
    fi
}

getCompiler() {
    echo "============================================================"
    echo "Which compiler do you want to use ? (defualt: 1)"
    echo ""
    echo "  1. GUN (gcc/gfortran)"
    echo "  2. Intel oneAPI"

    if [[ $READ_COMPILER_ID -eq 999 ]]; then
        read READ_COMPILER_ID
    fi

    if [[ -n $READ_COMPILER_ID ]]; then
        if [[ $READ_COMPILER_ID -eq 2 ]]; then
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

    if [[ $READ_CORE_NUMBER -eq 999 ]]; then
        read READ_CORE_NUMBER
    fi

    if [[ -n $READ_CORE_NUMBER ]]; then
        if [ $READ_CORE_NUMBER -ne 0 ]; then
            MAKE_OPENMP="-j$READ_CORE_NUMBER"
            WRF_WPS_OPENMP="-j $READ_CORE_NUMBER"
        fi
    fi
}

reSetEnv() {
    echo '' >> $HOME/.bashrc
    echo "###############################################" >> $HOME/.bashrc
    echo "# START for WRF or MPAS automatic installation" >> $HOME/.bashrc
    echo '' >> $HOME/.bashrc

    echo "#for $ZLIB_VERSION" >> $HOME/.bashrc
    if [ ! -n "$LD_LIBRARY_PATH" ]; then
        echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$ZLIB_VERSION'/lib' >> $HOME/.bashrc
    else
    echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$ZLIB_VERSION'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
    fi
    echo '' >> $HOME/.bashrc

    if [[ $WPS_VERSION < "WPS-4.4" ]]; then
        if [[ $OS_RELEASE == "centos" ]]; then
            TEMP_JASPER_LIB_DIR=$LIB_INSTALL_DIR'/'$JASPER_VERSION'/lib64:$LD_LIBRARY_PATH' >> $HOME/.bashrc
        else
            TEMP_JASPER_LIB_DIR=$LIB_INSTALL_DIR'/'$JASPER_VERSION'/lib' >> $HOME/.bashrc
        fi

        echo "#for $JASPER_VERSION" >> $HOME/.bashrc
        echo "export JASPER=$LIB_INSTALL_DIR/$JASPER_VERSION" >> $HOME/.bashrc
        echo "export JASPERLIB=$TEMP_JASPER_LIB_DIR" >> $HOME/.bashrc
        echo "export JASPERINC=$LIB_INSTALL_DIR/$JASPER_VERSION/include" >> $HOME/.bashrc
        echo "export LD_LIBRARY_PATH=$TEMP_JASPER_LIB_DIR" >> $HOME/.bashrc
    fi

    echo '' >> $HOME/.bashrc
    echo "#for $HDF5_VERSION" >> $HOME/.bashrc
    echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$HDF5_VERSION'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc

    echo '' >> $HOME/.bashrc
    echo "#for $NETCDF_VERSION" >> $HOME/.bashrc
    echo 'export PATH='$LIB_INSTALL_DIR'/'$NETCDF_VERSION'/bin:$PATH' >> $HOME/.bashrc
    echo "export NETCDF=$LIB_INSTALL_DIR/$NETCDF_VERSION" >> $HOME/.bashrc
    echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$NETCDF_VERSION'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc

    echo '' >> $HOME/.bashrc
    echo "#for $OPENMPI_VERSION" >> $HOME/.bashrc
    echo 'export PATH='$LIB_INSTALL_DIR'/'$OPENMPI_VERSION'/bin:$PATH' >> $HOME/.bashrc
    echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$OPENMPI_VERSION'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
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

    if [[ $READ_SOFT_SOURCE -eq 999 ]]; then
        read READ_SOFT_SOURCE
    fi

    if  [[ -n $READ_SOFT_SOURCE ]] ;then
        if [[ $READ_SOFT_SOURCE -eq 1 ]];then
            sudo -s bash -c "/bin/bash <(curl -sSL https://gitee.com/SuperManito/LinuxMirrors/raw/main/ChangeMirrors.sh)"
        fi
    fi
    echo "==============================================="
}

chooseFeatures() {
    echo "=============================================="
    echo "Which option do you wanna choose ? (defualt: 0)"
    echo ""
    echo "  1. WPS, WRF:em_real"
    echo "  2. WPS, WRF:em_real, WRF-chem (with Kpp)"
    if [ "$OS_RELEASE" == "centos" ];then
        echo "  3. WPS, WRF:em_real, WRF-hydro (support soon, NOT currently supported)"
    elif [ "$OS_RELEASE" == "ubuntu" ];then
        echo "  3. WPS, WRF:em_real, WRF-hydro"
    fi
    echo "  4. WPS, WRF:em_real, WRFDA:4dvar"
    echo "  5. MPAS-A 7.0 (Experimental)"
    echo "  0. Building Libraries Only"
    echo "=============================================="

    if [[ $READ_WRF_FEATURE -eq 999 ]]; then
        read READ_WRF_FEATURE
    fi
    
    if [[ $READ_WRF_FEATURE -eq 0 ]];then
        WRF_INSTALL_FLAG=0
        WRF_INSTALL_SUCCESS_FLAG_SHOULD_BE=0
    elif [[ $READ_WRF_FEATURE -eq 1 ]];then
        WRF_INSTALL_FLAG=1
        WRF_INSTALL_SUCCESS_FLAG_SHOULD_BE=2
    elif [[ $READ_WRF_FEATURE -eq 2 ]];then
        WRF_INSTALL_FLAG=2
        WRF_INSTALL_SUCCESS_FLAG_SHOULD_BE=2
    elif [[ $READ_WRF_FEATURE -eq 3 ]];then
        WRF_INSTALL_FLAG=3
        WRF_INSTALL_SUCCESS_FLAG_SHOULD_BE=2
    elif [[ $READ_WRF_FEATURE -eq 4 ]];then
        WRF_INSTALL_FLAG=4
        WRF_INSTALL_SUCCESS_FLAG_SHOULD_BE=4
    elif [[ $READ_WRF_FEATURE -eq 5 ]];then
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

        sudo $PACKAGE_MANAGER -yqq install libjpeg8*
        sudo $PACKAGE_MANAGER -yqq install perl
        sudo $PACKAGE_MANAGER -yqq install curl
        sudo $PACKAGE_MANAGER -yqq install glibc*
        sudo $PACKAGE_MANAGER -yqq install libgrib2c0d
        sudo $PACKAGE_MANAGER -yqq install libgrib2c-dev
        sudo $PACKAGE_MANAGER -yqq install libpng16*
        sudo $PACKAGE_MANAGER -yqq install libpng-tools
        sudo $PACKAGE_MANAGER -yqq install zlib1g
        sudo $PACKAGE_MANAGER -yqq install zlib1g-dev
        sudo $PACKAGE_MANAGER -yqq install libpng-devel
        sudo $PACKAGE_MANAGER -yqq install libpng-dev
        sudo $PACKAGE_MANAGER -yqq install tcsh
        sudo $PACKAGE_MANAGER -yqq install samba
        sudo $PACKAGE_MANAGER -yqq install cpp
        sudo $PACKAGE_MANAGER -yqq install m4
        sudo $PACKAGE_MANAGER -yqq install quota
        sudo $PACKAGE_MANAGER -yqq install cmake
        sudo $PACKAGE_MANAGER -yqq install make
        sudo $PACKAGE_MANAGER -yqq install wget
        sudo $PACKAGE_MANAGER -yqq install tar
        sudo $PACKAGE_MANAGER -yqq install autoconf
        sudo $PACKAGE_MANAGER -yqq install libtool
        sudo $PACKAGE_MANAGER -yqq install automake
        sudo $PACKAGE_MANAGER -yqq install autopoint
        sudo $PACKAGE_MANAGER -yqq install gettext
        sudo $PACKAGE_MANAGER -yqq install gcc
        sudo $PACKAGE_MANAGER -yqq install g++
        sudo $PACKAGE_MANAGER -yqq install gfortran
        sudo $PACKAGE_MANAGER -yqq install libcurl4-openssl-dev
        sudo $PACKAGE_MANAGER -yqq install libcurl4
        sudo $PACKAGE_MANAGER -yqq install libxml2-dev
        sudo $PACKAGE_MANAGER -yqq install libxml2
        sudo $PACKAGE_MANAGER -yqq install git

    elif [ "$OS_RELEASE" = "centos" ]; then

        sudo $PACKAGE_MANAGER -yqq install libjpeg-turbo
        sudo $PACKAGE_MANAGER -yqq install libjpeg-turbo-devel
        sudo $PACKAGE_MANAGER -yqq install libpng-devel
        sudo $PACKAGE_MANAGER -yqq install libpng16*
        sudo $PACKAGE_MANAGER -yqq install tcsh
        sudo $PACKAGE_MANAGER -yqq install samba
        sudo $PACKAGE_MANAGER -yqq install cpp
        sudo $PACKAGE_MANAGER -yqq install m4
        sudo $PACKAGE_MANAGER -yqq install quota
        sudo $PACKAGE_MANAGER -yqq install gcc
        sudo $PACKAGE_MANAGER -yqq install gcc-c++
        sudo $PACKAGE_MANAGER -yqq install gcc-gfortran
        sudo $PACKAGE_MANAGER -yqq install cmake
        sudo $PACKAGE_MANAGER -yqq install make
        sudo $PACKAGE_MANAGER -yqq install wget
        sudo $PACKAGE_MANAGER -yqq install tar
        sudo $PACKAGE_MANAGER -yqq install autoconf
        sudo $PACKAGE_MANAGER -yqq install libtool
        sudo $PACKAGE_MANAGER -yqq install automake
        sudo $PACKAGE_MANAGER -yqq install gettext-devel
        sudo $PACKAGE_MANAGER -yqq install gettext
        sudo $PACKAGE_MANAGER -yqq install libcurl-devel
        sudo $PACKAGE_MANAGER -yqq install libcurl
        sudo $PACKAGE_MANAGER -yqq install curl
        sudo $PACKAGE_MANAGER -yqq install git
        sudo $PACKAGE_MANAGER -yqq install perl
        sudo $PACKAGE_MANAGER -yqq install libxml2-devel
        sudo $PACKAGE_MANAGER -yqq install libxml2
        sudo $PACKAGE_MANAGER -yqq install freeglut-devel
        sudo $PACKAGE_MANAGER -yqq install freeglut
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
    mpi_fc=`which mpifc || which mpiifort`
    mpi_cc=`which mpicc || which mpiicc`
    mpi_cc_flag=$?
    if [ $mpi_cc_flag -eq 1 ];then
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
        export PATH=$LIB_INSTALL_DIR/$1/bin:$PATH
        export LD_LIBRARY_PATH=$LIB_INSTALL_DIR/$1/lib:$LD_LIBRARY_PATH
    else
        echo "=============================================="
        echo ""
        echo "Use MPI CC: $mpi_cc"
        echo "Use MPI FC: $mpi_fc"
        echo ""
        echo "=============================================="
    fi
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
            if [ ! -n "$LD_LIBRARY_PATH" ]; then
                echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$ZLIB_VERSION'/lib' >> $HOME/.bashrc
            else
                echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$ZLIB_VERSION'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
            fi
        fi
    fi
    export LD_LIBRARY_PATH=$LIB_INSTALL_DIR/$1/lib:$LD_LIBRARY_PATH
}

# Install jasper
getJasper() {
    if [[ $WPS_VERSION < "WPS-4.4" ]]; then
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
    fi
}

getFreeglut3() {
    if [ ! -s "$LIB_INSTALL_DIR/$1/lib/libglut.so" ]; then
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
        ./configure --prefix=$LIB_INSTALL_DIR/$NETCDF_VERSION --enable-netcdf4 --disable-dap &>$LOG_DIR/$1.conf.log

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
            echo 'export YACC='"'"$LIB_INSTALL_DIR'/'$1'/yacc -d'"'" >> $HOME/.bashrc
        fi
    fi
    export PATH=$LIB_INSTALL_DIR/$1:$PATH
    export PATH=$LIB_INSTALL_DIR/$1/bin:$PATH
    export YACC="$LIB_INSTALL_DIR/$1/yacc -d"
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
            echo -e '34\n1' | bash ./configure
            echo " ============================================================== "
            sed -i 's/-lnetcdff -lnetcdf/-lnetcdff -lnetcdf -lgomp -lpthread/g' ./configure.wrf
            sed -i '32s/-ffree-form -O -fno-second-underscore -fconvert=big-endian -frecord-marker=4/-ffree-form -O -fno-second-underscore -fconvert=big-endian -frecord-marker=4 -std=legacy/g' ./configure.wrf
        elif [ "$CC_VERSION" == "icc" ];then
            echo " ============================================================== "
            echo -e "\nConfigure WRF: 15. (dmpar) INTEL (ifort/icc)"
            echo -e '15\n1' | bash ./configure
            echo " ============================================================== "
            sed -i 's/-lnetcdff -lnetcdf/-lnetcdff -lnetcdf -lgomp -lpthread -liomp5/g' ./configure.wrf
        fi

        echo -e "\nCompile WRF"
        tcsh ./compile $WRF_WPS_OPENMP em_real &> $LOG_DIR/WRF_em_real.log
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
            echo '18' | bash ./configure wrfplus
            echo " ============================================================== "
        elif [ "$CC_VERSION" == "icc" ];then
            echo " ============================================================== "
            echo -e "\nConfigure wrfplus:  8. (dmpar)   INTEL (ifort/icc)"
            echo '8' | bash ./configure wrfplus
            echo " ============================================================== "
        fi

        echo -e "\nCompile wrfplus"
        sed -i 's/-lnetcdff -lnetcdf/-lnetcdff -lnetcdf -lgomp/g' ./configure.wrf
        tcsh ./compile $WRF_WPS_OPENMP wrfplus &> $LOG_DIR/WRFplus_compile.log
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
            echo '18' | bash ./configure 4dvar
            echo " ============================================================== "
        elif [ "$CC_VERSION" == "icc" ];then
            echo " ============================================================== "
            echo -e "\nConfigure WRFDA:  8. (dmpar)    INTEL (ifort/icc)"
            echo '8' | bash ./configure 4dvar
            echo " ============================================================== "
        fi

        echo -e "\nCompile WRFDA with wrfplus"
        tcsh ./compile $WRF_WPS_OPENMP all_wrfvar >& $LOG_DIR/WRFDA_compile.log
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
        echo "Download latest WRF-hydro"
        if [ ! -s $SRC_DIR/$WRF_HYDRO_VERSION/trunk/NDHMS/configure ];then
            wgetSource $2
        fi
        cd $HOME
        rm -r $HOME/$WRF_VERSION/hydro
        cp -r $SRC_DIR/$WRF_HYDRO_VERSION/trunk/NDHMS $HOME/$WRF_VERSION/hydro


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
        tcsh ./compile $WRF_WPS_OPENMP em_real &> $LOG_DIR/WRF_em_real.log
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

        sed -i 's/standard_wrf_dirs="WRF WRF-4.0.3 WRF-4.0.2 WRF-4.0.1 WRF-4.0 WRFV3 WRF-4.1.2"/standard_wrf_dirs="WRF WRF-4.2 WRF-4.3 WRF-4.4.2 WRFV3"/g' ./configure

        if [ "$CC_VERSION" == "gcc" ];then
            echo " ============================================================== "
            echo -e "\nConfigure WPS: 1. Linux x86_64,gfortran (serial)"

            if [[ $WPS_VERSION < "WPS-4.4" ]]; then
                echo '1' | bash ./configure &>$LOG_DIR/$1.config.log
            else
                echo '1' | bash ./configure --build-grib2-libs &>$LOG_DIR/$1.config.log
            fi

            sed -i 's/-lnetcdff -lnetcdf/-lnetcdff -lnetcdf -lgomp/g' ./configure.wps
            sed -i 's/-ffree-form -O -fconvert=big-endian -frecord-marker=4/-ffree-form -O -fconvert=big-endian -frecord-marker=4 -std=legacy/g' ./configure.wps
            sed -i 's/-ffixed-form -O -fconvert=big-endian -frecord-marker=4/-ffixed-form -O -fconvert=big-endian -frecord-marker=4 -std=legacy/g' ./configure.wps
            echo " ============================================================== "
        elif [ "$CC_VERSION" == "icc" ];then
            echo " ============================================================== "
            echo -e "\nConfigure WPS: 19. Linux x86_64, Intel compiler (dmpar)"
            echo '19' | bash ./configure &>$LOG_DIR/$1.config.log
            sed -i 's/-lnetcdff -lnetcdf/-lnetcdff -lnetcdf -lgomp -lpthread -liomp5/g' ./configure.wps
            sed -i 's/DM_FC               = mpifort/DM_FC               = mpiifort/g' ./configure.wps
            sed -i 's/DM_CC               = mpicc/DM_CC               = mpiicc/g' ./configure.wps
            echo " ============================================================== "
        fi

        echo -e "\nCompile WPS"
        tcsh ./compile &> $LOG_DIR/$1.compile.log

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

        exit 0

    elif [ $WRF_INSTALL_SUCCESS_FLAG -eq $WRF_INSTALL_SUCCESS_FLAG_SHOULD_BE ];then
        echo -e "\nAll install ${green}successful${plain}\n"
        ls -d $HOME/$WPS_VERSION --color=auto
        ls -d $HOME/$WRF_VERSION --color=auto
        if [ $WRF_INSTALL_FLAG -eq 4 ];then
            ls -d $HOME/$WRFplus_VERSION --color=auto
            ls -d $HOME/$WRFDA_VERSION --color=auto
        fi

        if [[ $TEST_FLAG -ne 1 ]];then
            rm $SRC_DIR -r
        fi

        rm $LOG_DIR -r
        
        echo -e "\nEnjoy it\n"

        exit 0

    else
        echo -e "\nInstall ${red}failed${plain} please check errors\n"
        cp $HOME/.bashrc $HOME/.bashrc.WRF.bak
        cp $HOME/.bashrc.autoInstall.bak $HOME/.bashrc

        exit 1
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

envConfig() {
    checkSystemInfo
    getInfo
    # checkRoot
    getDir
    chooseFeatures
    getWRFVersion
    getWPSVersion
    getCompiler
    checkInfo
    getOpenmp
    if [[ $SERVER_FLAG -eq 0 ]];then
        checkMem
        setSources
        getLibrary
    fi
    creatLogs
}

envInstall() {
    if [[ $SERVER_FLAG -eq 0 ]];then
        getOpenMPI  $OPENMPI_VERSION
    fi
    getZilb     $ZLIB_VERSION
    getJasper   $JASPER_VERSION
    getHDF5     $HDF5_VERSION
    getNetCDF   $NETCDF_VERSION $NETCDF_FORTRAN_VERSION
}

wrfInstall() {
    getWRF      $WRF_VERSION
    getWPS      $WPS_VERSION
}

wrfChemInstall() {
    getBison    $BISON_VERSION
    getFlex     $FLEX_VERSION
    WRF_CHEM_SETTING=1
    WRF_KPP_SETTING=1
    getWRF      $WRF_VERSION
    getWPS      $WPS_VERSION
}

wrfHydroInstall() {
    getWRFHydro $WRF_VERSION $WRF_HYDRO_VERSION
    getWPS      $WPS_VERSION
}

wrfdaInstall() {
    wrfInstall
    getWRFplus  $WRFplus_VERSION
    getWRFDA    $WRFDA_VERSION
}

mpasInstall() {
    getPnetCDF  $PNETCDF_VERSION
    getPIO      $PIO_VERSION
    getMPAS     $MPAS_VERSION
}

wrfFeatureInstall() {
    if [[ $SERVER_FLAG -eq 0 ]]; then
        envInstall
    fi
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

WORKFLOW=""
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en

while getopts "d:f:v:c:n:s:p:t" opt;
do
    case $opt in
        d)
            READ_INSTALL_DIR=$OPTARG
            ;;
        f)
            READ_WRF_FEATURE=$OPTARG
            ;;
        v)
            READ_WRF_VERSION=$OPTARG
            READ_WPS_VERSION=$OPTARG
            ;;
        c)
            READ_COMPILER_ID=$OPTARG
            ;;
        n)
            READ_CORE_NUMBER=$OPTARG
            ;;
        s)
            READ_SOFT_SOURCE=$OPTARG
            ;;
        p)
            WORKFLOW=$OPTARG
            ;;
        t)
            TEST_FLAG=1
            ;;
        ?)
            echo "Unknown parameter: $opt"
            showHelp
            exit 1
            ;;
    esac
done

if [[ $WORKFLOW == "help" ]]; then
    showHelp
elif [[ $WORKFLOW == "resetEnv" ]]; then
    reSetEnv
elif [[ $WORKFLOW == "server" ]]; then
    SERVER_FLAG="1"
    envConfig
    wrfFeatureInstall
    checkFinishWRF
elif [[ $WORKFLOW == "dry" ]]; then
    checkSystemInfo
    getInfo
    getDir
    chooseFeatures
    getWRFVersion
    getWPSVersion
    getCompiler
    getOpenmp
    setSources
    checkInfo
    checkMem
else
    envConfig
    wrfFeatureInstall
    checkFinishWRF
fi

exit 0
