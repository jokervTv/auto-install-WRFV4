#!/bin/bash

# Author: Yongpeng Zhang - zhangyp6603@outlook.com
#
# Description:  install WPS,WRF,WRFDA,WRF-Chem.
#               If you have any questions, send an e-mail or open an issue.
# Start by
# wget https://raw.githubusercontent.com/jokervTv/auto-install-WRFV4/master/autoInstall.sh | bash autoInstall.sh


# System info
MAKE_OPENMP="-j4"
WRF_WPS_OPENMP='-j 4'
TEST_FLAG="0"
LIB_INSTALL_DIR="$HOME/.WRF_MPAS_LIB"
LOG_DIR="$HOME/log-wrf-mpas"
SRC_DIR="$HOME/src-wrf-mpas"
DOWNLOAD_URL="https://code.aliyun.com/z1099135632/WRF_MPAS_LIB/raw/master"
CC_VERSION="gcc"
FC_VERSION="gfortran"
CXX_VERSION="g++"
MPICC_VERSION="mpicc"
MPIFC_VERSION="mpifort"
MPICXX_VERSION="mpic++"

# Version
ZLIB_VERSION="zlib-1.2.11"
JASPER_VERSION="jasper-2.0.14"
HDF5_VERSION="hdf5-1.10.5"
NETCDF_VERSION="NETCDF-4.7.0"
NETCDF_FORTRAN_VERSION="netcdf-fortran-4.4.5"
BISON_VERSION="bison-3.5.4" #http://ftpmirror.gnu.org/bison/
FLEX_VERSION="flex-2.6.4" #https://github.com/westes/flex
WPS_VERSION="WPS-4.2" #https://github.com/wrf-model/WPS
WRF_VERSION="WRF-4.2" #https://github.com/wrf-model/WRF
WRFplus_VERSION="WRFplus-4.2" #https://github.com/wrf-model/WRF
WRFDA_VERSION="WRFDA-4.2" #https://github.com/wrf-model/WRF
PIO_VERSION="pio-2.5.0" #https://github.com/NCAR/ParallelIO/
PNETCDF_VERSION="pnetcdf-1.11.2" #https://github.com/Parallel-NetCDF/PnetCDF
MPAS_VERSION="MPAS-Model-7.0" #https://github.com/MPAS-Dev/MPAS-Model

# WRF setting
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
    echo " \                                                            / "
    echo " \              Script Created by Yongpeng Zhang              / "
	echo " \                            and                             / "
    echo " \              SuperUpdate.sh Created by Oldking             / "
	echo " ============================================================== "
    echo ""
}

# Check authority
checkRoot() {
    [[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}]: Please run this script with ${red}sudo${plain}!" && exit 1
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

getOpenmp() {
    echo "============================================================"
    echo "How many physical cores does your wanna use ? (defualt: 4)"
    echo "If you know nothing about this, please input 0"
    echo ""
    read cores_number
    if [ "$cores_number" -ne "0" ]; then
        MAKE_OPENMP="-j$cores_number"
        WRF_WPS_OPENMP="-j $cores_number"
    fi
}

getTest() {
    echo "============================================================"
    echo "do you wanna make test or check ? (defualt: no)"
    echo "0.no"
    echo "1.yes"
    read read_test_flag
    if [ "$read_test_flag" -eq "1" ];then
        TEST_FLAG="$read_test_flag"
    fi
}

getWRFChemWill() {
    echo "============================================================"
    echo "do you wanna build WRF-Chem ? (defualt: no)"
    echo "0.no"
    echo "1.yes"
    read read_test_flag
    if [ "$read_test_flag" -eq "1" ];then
        WRF_CHEM_SETTING="$read_test_flag"
        WRF_KPP_SETTING="$read_test_flag"
    fi
}

# Change sources
setSources() {
    echo "=============================================="
    echo "Do you wanna change sources ?"
    echo ""
    echo "  1. set sources from cdn-fastly"
    echo "  2. set sources from USTC"
    echo "  3. set sources from 163.com"
    echo "  4. set sources from aliyun.com"
    echo "  5. set sources from cdn-aws"
    echo "  0. no, nothing to change (default)"
    echo ""
    echo "If you know nothing about this, please input 0"
    willness="0"
    read willness
    if  [ -n "$willness" ] ;then
        if [ $willness -ne "0" ];then
            wget -nv https://raw.githubusercontent.com/jokervTv/auto-install-WRFV4/master/superupdate.sh
            chmod +x ./superupdata.sh
        fi
        if [ $willness -eq "1" ];then
            bash superupdate.sh
        elif [ $willness -eq "2" ];then
            bash superupdate.sh cn
        elif [ $willness -eq "3" ];then
            bash superupdate.sh 163
        elif [ $willness -eq "4" ];then
            bash superupdate.sh aliyun
        elif [ $willness -eq "5" ];then
            bash superupdate.sh aws
        fi
        if [ $willness -ne "0" ];then
            apt-get update
            rm ./superupdate.sh
        fi
    fi
    echo "==============================================="
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
    echo $BISON_VERSION
    echo $FLEX_VERSION
    echo $WRF_VERSION
    echo $WPS_VERSION
    echo $PIO_VERSION
    echo $PNETCDF_VERSION
    echo ""
    echo "=========================================================="
    echo ""
    echo "WRF will be installed in ${red} $HOME/$WRF_VERSION ${plain}"
    echo "WPS will be installed in ${red} $HOME/$WPS_VERSION ${plain}"
    echo ""
}

# Install essential components
aptLib() {
    echo "=========================================================="
    echo -e "\nInstall essential components"
    echo "=========================================================="
    sudo apt-get -yqq install glibc* libgrib2c0d libgrib2c-dev libjpeg8* libpng16* perl curl
    sudo apt-get -yqq install libpng-tools
    sudo apt-get -yqq install libpng-devel
    sudo apt-get -yqq install libpng-dev
    sudo apt-get -yqq install tcsh samba cpp m4 quota
    sudo apt-get -yqq install cmake make wget tar
    sudo apt-get -yqq install autoconf libtool mpich automake
    sudo apt-get -yqq install autopoint gettext
    sudo apt-get -yqq install libcurl4-openssl-dev libcurl4
    sudo apt-get -yqq install git
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

# Install zlib
getZilb() {
    if [ ! -s "$LIB_INSTALL_DIR/$1/lib/libz.a" ]; then
        wgetSource $1
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
    if [ ! -s "$LIB_INSTALL_DIR/$1/lib/libjasper.so" ]; then
        wgetSource $1
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
            echo "export JASPERLIB=$LIB_INSTALL_DIR/$1/lib" >> $HOME/.bashrc
            echo "export JASPERINC=$LIB_INSTALL_DIR/$1/include" >> $HOME/.bashrc
            echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$1'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
        fi
    fi
    export JASPER=$LIB_INSTALL_DIR/$1
    export JASPERLIB=$LIB_INSTALL_DIR/$1/lib
    export JASPERINC=$LIB_INSTALL_DIR/$1/include
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
                --enable-fortran --enable-cxx               \
                &>$LOG_DIR/$1.conf.log
            makeInstall $1
        if [ ! -s $HOME/.bashrc.autoInstall.bak ];then
            echo '' >> $HOME/.bashrc
            echo "#for $1" >> $HOME/.bashrc
            echo 'export LD_LIBRARY_PATH='$LIB_INSTALL_DIR'/'$1'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
        fi
    fi
    export LD_LIBRARY_PATH=$LIB_INSTALL_DIR/$1/lib:$LD_LIBRARY_PATH
}

# Install netcdf
getNetCDF() {
    if [ ! -s "$LIB_INSTALL_DIR/$1/include/netcdf.inc" ]; then
        export CPPFLAGS=-I$LIB_INSTALL_DIR/$HDF5_VERSION/include
        export LDFLAGS=-L$LIB_INSTALL_DIR/$HDF5_VERSION/lib
        export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}$LIB_INSTALL_DIR/$HDF5_VERSION/lib
        wgetSource $1
        ./configure --prefix=$LIB_INSTALL_DIR/$NETCDF_VERSION --enable-netcdf-4 &>$LOG_DIR/$1.conf.log
        makeInstall $1

        export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$LIB_INSTALL_DIR/$1/lib
        export CPPFLAGS=-I$LIB_INSTALL_DIR/$1/include
        export LDFLAGS=-L$LIB_INSTALL_DIR/$1/lib
        wgetSource $2
        CC=$CC_VERSION CXX=$CXX_VERSION FC=$FC_VERSION  \
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
        # todo Note: version 2.6.5
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
        CC=$MPICC_VERSION CXX=$MPICXX_VERSION FC=$MPIFC_VERSION  \
        ./configure --prefix=$LIB_INSTALL_DIR/$1        \
        CFLAGS=-fPIC --enable-shared &>$LOG_DIR/$1.conf.log
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

# Install PIO2
getPIO() {
    if [ ! -s "$LIB_INSTALL_DIR/$1/lib/libpiof.a" ];then
        wgetSource $1
        CC=$MPICC_VERSION CXX=$MPICXX_VERSION FC=$MPIFC_VERSION \
        cmake \
            -DNetCDF_C_PATH=$LIB_INSTALL_DIR/$NETCDF_VERSION \
            -DNetCDF_Fortran_PATH=$LIB_INSTALL_DIR/$NETCDF_VERSION \
            -DPnetCDF_PATH=$LIB_INSTALL_DIR/$PNETCDF_VERSION \
            -DPIO_HDF5_LOGGING=On -DPIO_USE_MALLOC=On \
            -DCMAKE_INSTALL_PREFIX=$LIB_INSTALL_DIR/$1 \
            &>$LOG_DIR/$1.conf.log
        makeInstall $1
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

# Install WRF
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
    if [ $flag -ne 4 ];then
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
        echo " ============================================================== "
        echo -e "\nConfigure WRF: 33.(smpar) GNU(gfortran/gcc)" # todo more options should be choose
        echo '33\n1' | ./configure
        echo " ============================================================== "
        echo -e "\nCompile WRF"
        ./compile $WRF_WPS_OPENMP em_real &> $LOG_DIR/WRF_em_real.log
        flag=0
        WRF_FLAG=0
        for file in $(ls $HOME/$WRF_VERSION/main/*.exe)
        do
            flag=$(( $flag + 1 ))
        done
        if [ $flag -eq 4 ];then
            echo -e "\n\nWRF install ${green}successful${plain}\n"
            WRF_FLAG=$(( $WRF_FLAG + 1 ))
        else
            echo -e "\nInstall WRF ${red}failed${plain} please check errors in logs($LOG_DIR/)\n"
            exit 1
        fi
    else
        echo -e "\nWRF already installed\n"
        WRF_FLAG=$(( $WRF_FLAG + 1 ))
    fi
}

# Install WRFplus
getWRFplus() {
    flag=0
    for file in $(ls $HOME/$WRFplus_VERSION/run/*.exe 2>/dev/null)
    do
        flag=$(( $flag + 1 ))
    done
    if [ $flag -ne 1 ];then
        echo "Install WRFplus"
        if [ ! -s $HOME/$WRFplus_VERSION/configure ];then
            if [ ! -s $SRC_DIR/$WRF_VERSION.tar.gz ];then
                wgetSource $1
                cd $HOME && mv $SRC_DIR/$WRF_VERSION $HOME/$WRFplus_VERSION
            else
                cp -r $HOME/$WRF_VERSION $HOME/$WRFplus_VERSION
            fi
        fi
        cd $HOME/$1
        echo " ============================================================== "
        echo -e "\nClean\n"
        ./clean -a &>/dev/null
        ulimit -s unlimited
        echo " ============================================================== "
        echo -e "\nConfigure wrfplus: 17. (serial)   GNU (gfortran/gcc)"
        echo '17' | ./configure wrfplus
        echo " ============================================================== "
        echo -e "\nCompile wrfplus"
        sed -i 's/-lnetcdff -lnetcdf/-lnetcdff -lnetcdf -lgomp/g' ./configure.wrf
        ./compile $WRF_WPS_OPENMP wrfplus &> $LOG_DIR/WRFplus_compile.log
        export WRFPLUS_DIR=$HOME/$1/WRFPLUS
        echo "WRFPLUS_DIR=$HOME/$1/WRFPLUS" >> $HOME/.bashrc
        flag=0
        WRF_FLAG=0
        for file in $(ls $HOME/$WRFplus_VERSION/run/*.exe)
        do
            flag=$(( $flag + 1 ))
        done
        if [ $flag -eq 1 ];then
            echo -e "\n\nWRFDA install ${green}successful${plain}\n"
            WRF_FLAG=$(( $WRF_FLAG + 1 ))
        else
            echo -e "\nInstall WRFplus ${red}failed${plain} please check errors in logs($LOG_DIR/)\n"
            exit 1
        fi
    else
        echo -e "\nWRFplus has been installed\n"
        WRF_FLAG=$(( $WRF_FLAG + 1 ))
    fi
}

# Install WRFDA
getWRFDA() {
    flag=0
    for file in $(ls $HOME/$WRFDA_VERSION/var/build/*.exe 2>/dev/null)
    do
        flag=$(( $flag + 1 ))
    done
    if [ $flag -ne 44 ];then
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
        echo " ============================================================== "
        echo -e "\nConfigure WRFDA: 33. (smpar)   GNU (gfortran/gcc)"
        echo '33' |./configure 4dvar
        echo -e "\nCompile WRFDA with wrfplus"
        ./compile $WRF_WPS_OPENMP all_wrfvar >& $LOG_DIR/WRFDA_compile.log
        flag=0
        WRF_FLAG=0
        for file in $(ls $HOME/$WRFDA_VERSION/var/build/*.exe)
        do
            flag=$(( $flag + 1 ))
        done
        if [ $flag -eq 44 ];then
            echo -e "\n\nWRFDA install ${green}successful${plain}\n"
            WRF_FLAG=$(( $WRF_FLAG + 1 ))
        else
            echo -e "\nInstall WRF ${red}failed${plain} please check errors in logs($LOG_DIR/)\n"
            exit 1
        fi
    else
        echo -e "\nWRFDA has been installed\n"
        WRF_FLAG=$(( $WRF_FLAG + 1 ))
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
    if [ $flag -ne 11 ];then
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
        echo " ============================================================== "
        echo -e "\nConfigure WPS: 1. Linux x86_64,gfortran (serial)"
        sed -i 's/standard_wrf_dirs="WRF WRF-4.0.3 WRF-4.0.2 WRF-4.0.1 WRF-4.0 WRFV3"/standard_wrf_dirs="WRF WRF-4.0.3 WRF-4.0.2 WRF-4.0.1 WRF-4.0 WRFV3 WRF-4.1.2"/g' ./configure
        echo '1' | ./configure &>$LOG_DIR/$1.config.log
        sed -i 's/-lnetcdff -lnetcdf/-lnetcdff -lnetcdf -lgomp/g' ./configure.wps
        echo " ============================================================== "
        echo -e "\nCompile WPS"
        ./compile &> $LOG_DIR/WPS.compile.log
        flag=0
        for file in $(ls $HOME/$WPS_VERSION/util/*.exe)
        do
            flag=$(( $flag + 1 ))
        done
        for file in $(ls $HOME/$WPS_VERSION/*.exe)
        do
            flag=$(( $flag + 1 ))
        done
        if [ $flag -eq 11 ];then
            echo -e "\n\nWPS install ${green}successful${plain}\n"
            WRF_FLAG=$(( $WRF_FLAG + 1 ))
        else
            echo -e "Install WPS ${red}failed${plain}, please check errors in logs($LOG_DIR/)\n"
        fi
    else
        echo -e "\nWPS already installed\n"
        WRF_FLAG=$(( $WRF_FLAG + 1 ))
    fi
}

checkFinishWRF() {
    echo "# END for WRF or MPAS automatic installation" >> $HOME/.bashrc
    echo "###############################################" >> $HOME/.bashrc
    if [ $WRF_FLAG -eq 4 ];then
        echo -e "\nAll install ${green}successful${plain}\n"
        ls -d $HOME/$WPS_VERSION --color=auto
        ls -d $HOME/$WRF_VERSION --color=auto
        ls -d $HOME/$WRFDA_VERSION --color=auto
        echo -e "\nClean"
        sudo rm $SRC_DIR -r
        sudo rm $LOG_DIR -r
        echo -e "\nEnjoy it\n"
    else
        echo -e "\nInstall ${red}failed${plain} please check errors\n"
        cp $HOME/.bashrc.autoInstall.bak $HOME/.bashrc
        rm $HOME/.bashrc.autoInstall.bak
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
    mv $1 MPAS-atmosphere

    echo -e "\nCompile MPAS-init_atmosphere\n"
    cd $HOME/MPAS-init_atmosphere
    make gfortran CORE=init_atmosphere OPENMP=true USE_PIO2=true AUTOCLEAN=true \
    PIO=$LIB_INSTALL_DIR/$PIO_VERSION &>$LOG_DIR/MPAS-init_atmosphere.log

    echo -e "\nCompile MPAS-atmosphere\n"
    cd $HOME/MPAS-atmosphere
    make gfortran CORE=atmosphere OPENMP=true USE_PIO2=true AUTOCLEAN=true \
    PIO=$LIB_INSTALL_DIR/$PIO_VERSION &>$LOG_DIR/MPAS-atmosphere.log
}

restoreSource() {
    willness=0
    echo "=============================================="
    echo "Do you wanna restore sources ?"
    echo "  1. yes"
    echo "  2. no (default)"
    echo "==============================================="
    read willness

    if [ $willness -eq "1" ];then
        bash superupdate.sh restore
    fi
}

#-------functions end--------

getInfo
#checkRoot
getDir
getOpenmp
#getTest
#getWRFChemWill
setSources
checkInfo
aptLib
creatLogs
getZilb     $ZLIB_VERSION
getJasper   $JASPER_VERSION
getHDF5     $HDF5_VERSION
getNetCDF   $NETCDF_VERSION $NETCDF_FORTRAN_VERSION
getBison    $BISON_VERSION
getFlex     $FLEX_VERSION
getWRF      $WRF_VERSION
getWRFplus  $WRFplus_VERSION
getWRFDA    $WRFDA_VERSION
getWPS      $WPS_VERSION
getPnetCDF  $PNETCDF_VERSION
getPIO      $PIO_VERSION
#getMPAS     $MPAS_VERSION
checkFinishWRF
restoreSource
