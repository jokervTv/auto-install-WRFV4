#!/bin/bash

# Description: install WPS and WRF with chem.
# If you have any questions, send a e-mail to zhangyp6603@outlook.com.
# Start by
# wget https://raw.githubusercontent.com/jokervTv/auto-install-WRFV4/master/install_wrf-4.0.1_GUN_EnableNetCDF4.sh
# chmod +x ./install_wrf-4.0.1_GUN_EnableNetCDF4.sh
# sudo ./install_wrf-4.0.1_GUN_EnableNetCDF4.sh

clear

getInfo() {
    echo "===================================="
    echo ""
    echo "===================================="
}

# Check authority
checkRoot() {
    [[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}]: Please run this script with ${red}sudo${plain}!" && exit 1
}

_install() {
    cd $HOME/src-wrf
    rm -rf $HOME/src-wrf/$1
    rm -f $HOME/src-wrf/$1.tar.gz*
    echo -e "\nDownload $1"
    wget -c https://code.aliyun.com/z1099135632/wrf-3.9.1.1/raw/master/data/$1.tar.gz
    echo -e "\nExtract $1"
    tar -xf $1.tar.gz
    rm $1.tar.gz*
    echo -e "\nDelect $1.tar.gz"
    cd $HOME/src-wrf/$1
    echo -e "\nConfigure & make $1"
    if [ "$1" == "hdf5-1.10.2" ]; then
        ./configure --prefix=/usr/local/hdf5-1.10.2 --with-zlib=/usr/local/zlib-1.2.11 >/dev/null
        make -j4 >/dev/null 2>$HOME/log-wrf/$1.make.log
    elif [ "$1" == "netcdf-4.4.1" ]; then
        ./configure --prefix=/usr/local/NETCDF-4.4 --enable-netcdf-4 >/dev/null
        make -j4 >/dev/null 2>$HOME/log-wrf/$1.make.log
    elif [ "$1" == "netcdf-fortran-4.4.4" ]; then
        ./configure FC=gfortran --prefix=/usr/local/NETCDF-4.4 >/dev/null
        make -j4 >/dev/null 2>$HOME/log-wrf/$1.make.log
    else
        ./configure --prefix=/usr/local/$1 >/dev/null
        make -j4 >/dev/null 2>$HOME/log-wrf/$1.make.log
    fi
    echo -e "\nCheck $1"
    make check &> $HOME/log-wrf/$1.Check.log
    echo -e "\nInstall $1"
    make install >/dev/null
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
    echo "  0. no, nothing to change"
    echo ""
    echo "If you know nothing about this, please input 1"
    echo "==============================================="
    read willness

    if [ $willness -ne "0" ];then
        wget https://raw.githubusercontent.com/jokervTv/auto-install-WRFV4/master/superupdate.sh
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
}

# Install essential components
aptLib() {
    echo "Install essential components"
    apt-get install -y glibc* libgrib2c0d libgrib2c-dev libjpeg8* libpng16* perl curl &>/dev/null
    apt-get install -y libpng-tools &>/dev/null
    apt-get install -y libpng-devel &>/dev/null
    apt-get install -y libpng-dev &>/dev/null
    apt-get install -y tcsh samba cpp m4 quota >/dev/null
    apt-get install -y gcc g++ gfortran >/dev/null
    apt-get install -y make wget tar >/dev/null
}

# Creat logs and backupfiles
creatLogs() {
    echo -e "\nMkdir $HOME/log-wrf"
    mkdir $HOME/log-wrf
    echo -e "\nMkdir $HOME/src-wrf"
    mkdir $HOME/src-wrf
    if [ ! -s $HOME/.bashrc.wrf.bak ];then
        cp $HOME/.bashrc $HOME/.bashrc.wrf.bak.temp
    fi
}

# Install zlib
getZilb() {
    if [ ! -s "/usr/local/zlib-1.2.11/lib/libz.a" ]; then
        _install zlib-1.2.11
        if [ ! -s $HOME/.bashrc.wrf.bak ];then
            echo '' >> $HOME/.bashrc
            echo '#for zlib-1.2.11' >> $HOME/.bashrc
            echo 'export LD_LIBRARY_PATH=/usr/local/zlib-1.2.11/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
            source $HOME/.bashrc
        fi
            export LD_LIBRARY_PATH=/usr/local/zlib-1.2.11/lib:$LD_LIBRARY_PATH
    fi
}

# Install jasper
getJasper() {
    if [ ! -s "/usr/local/jasper-1.900.1/lib/libjasper.a" ]; then
        _install jasper-1.900.1
        if [ ! -s $HOME/.bashrc.wrf.bak ];then
            echo '' >> $HOME/.bashrc
            echo '#set JASPER' >> $HOME/.bashrc
            echo 'export JASPER=/usr/local/jasper-1.900.1' >> $HOME/.bashrc
            echo 'export JASPERLIB=/usr/local/jasper-1.900.1/lib' >> $HOME/.bashrc
            echo 'export JASPERINC=/usr/local/jasper-1.900.1/include' >> $HOME/.bashrc
            echo 'export LD_LIBRARY_PATH=/usr/local/jasper-1.900.1/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
            source $HOME/.bashrc
        fi
        export JASPER=/usr/local/jasper-1.900.1
        export JASPERLIB=/usr/local/jasper-1.900.1/lib
        export JASPERINC=/usr/local/jasper-1.900.1/include
        export LD_LIBRARY_PATH=/usr/local/jasper-1.900.1/lib:$LD_LIBRARY_PATH
    fi
}


# Install hdf5
getHDF5() {
    if [ ! -s "/usr/local/hdf5-1.10.2/lib/libhdf5.a" ]; then
        export LDFLAGS=-L/usr/local/zlib-1.2.11/lib
        export CPPFLAGS=-I/usr/local/zlib-1.2.11/include
        _install hdf5-1.10.2
        make check-install &> $HOME/log-wrf/hdf5-1.10.2.CheckInstall.log
        if [ ! -s $HOME/.bashrc.wrf.bak ];then
            echo '' >> $HOME/.bashrc
            echo '#for hdf5-1.10.2' >> $HOME/.bashrc
            echo 'export LD_LIBRARY_PATH=/usr/local/hdf5-1.10.2/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
            source $HOME/.bashrc
        fi
        export LD_LIBRARY_PATH=/usr/local/hdf5-1.10.2/lib:$LD_LIBRARY_PATH
    fi
}

# Install netcdf
getNetCDF() {
    if [ ! -s "/usr/local/NETCDF-4.4/include/netcdf.inc" ]; then
        export CPPFLAGS=-I/usr/local/hdf5-1.10.2/include
        export LDFLAGS=-L/usr/local/hdf5-1.10.2/lib
        export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}/usr/local/hdf5-1.10.2/lib
        _install netcdf-4.4.1

        export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/NETCDF-4.4/lib
        export CPPFLAGS=-I/usr/local/NETCDF-4.4/include
        export LDFLAGS=-L/usr/local/NETCDF-4.4/lib
        _install netcdf-fortran-4.4.4
        if [ ! -s $HOME/.bashrc.wrf.bak ];then
            echo '' >> $HOME/.bashrc
            echo '#for netcdf-4.4' >> $HOME/.bashrc
            echo 'export PATH=/usr/local/NETCDF-4.4/bin:$PATH' >> $HOME/.bashrc
            echo 'export LD_LIBRARY_PATH=/usr/local/NETCDF-4.4/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
            source $HOME/.bashrc
        fi
        export PATH=/usr/local/NETCDF-4.4/bin:$PATH
        export LD_LIBRARY_PATH=/usr/local/NETCDF-4.4/lib:$LD_LIBRARY_PATH
    fi
}

# Install bison
getBison() {
    if [ ! -s "/usr/local/bison-3.1/bin/bison" ]; then
        _install bison-3.1
        if [ ! -s $HOME/.bashrc.wrf.bak ];then
            echo '' >> $HOME/.bashrc
            echo '#for bison-3.1' >> $HOME/.bashrc
            echo 'export PATH=/usr/local/bison-3.1/bin:$PATH' >> $HOME/.bashrc
            echo 'export PATH=/usr/local/bison-3.1:$PATH' >> $HOME/.bashrc
            echo "export YACC='yacc -d'" >> $HOME/.bashrc
            source $HOME/.bashrc
        fi
        export PATH=/usr/local/bison-3.1/bin:$PATH
        export PATH=/usr/local/bison-3.1:$PATH
        export YACC='yacc -d'
    fi
}

# Install flex
getFlex() {
    if [ ! -s "/usr/local/flex-2.5.3/bin/flex" ]; then
        _install flex-2.5.3
        if [ ! -s $HOME/.bashrc.wrf.bak ];then
            echo '' >> $HOME/.bashrc
            echo '#for flex-2.5.3' >> $HOME/.bashrc
            echo 'export PATH=/usr/local/flex-2.5.3/bin:$PATH' >> $HOME/.bashrc
            echo 'export FLEX=/usr/local/flex-2.5.3/bin/flex' >> $HOME/.bashrc
            echo "export FLEX_LIB_DIR=/usr/local/flex-2.5.3/lib" >> $HOME/.bashrc
            source $HOME/.bashrc
        fi
        export PATH=/usr/local/flex-2.5.3/bin:$PATH
        export FLEX=/usr/local/flex-2.5.3/bin/flex
        export FLEX_LIB_DIR=/usr/local/flex-2.5.3/lib
    fi
}

# Install WRF
getWRF() {
    if [ ! -s $HOME/.bashrc.wrf.bak ];then
        echo '' >> $HOME/.bashrc
        echo '#for WRF' >> $HOME/.bashrc
        echo 'export NETCDF=/usr/local/NETCDF-4.4' >> $HOME/.bashrc
        echo 'export WRFIO_NCD_LARGE_FILE_SUPPORT=1' >> $HOME/.bashrc
        echo 'export WRF_CHEM=1' >> $HOME/.bashrc
        echo 'export WRF_KPP=1' >> $HOME/.bashrc
        source $HOME/.bashrc
        mv $HOME/.bashrc.wrf.bak.tmp $HOME/.bashrc.wrf.bak
        export NETCDF=/usr/local/NETCDF-4.4
        export WRFIO_NCD_LARGE_FILE_SUPPORT=1
        export WRF_CHEM=1
        export WRF_KPP=1
    fi
    cd $HOME
    flag=0
    for file in $(ls $HOME/WRF/main/*.exe 2>/dev/null)
    do
        flag=$(( $flag + 1 ))
    done
    if [ $flag -ne 4 ];then
        echo "Install WRF"
        if [ ! -s $HOME/WRF-4.0.1/configure ];then
            if [ ! -s $HOME/WRF-4.0.1.tar.gz ];then
            echo -e "\nDownload WRF"
            wget -c https://github.com/wrf-model/WRF/archive/v4.0.1.tar.gz
            mv ./v4.0.1.tar.gz ./WRF-4.0.1.tar.gz
            fi     
            echo -e "\nExtract"
            tar -xf WRF-4.0.1.tar.gz
        fi
        cd WRF-4.0.1
        echo -e "\nClean"
        ./clean -a &>/dev/null
        export J="-j 4"
        ulimit -s unlimited
        echo -e "\nConfigure WRF: 33.(smpar) GNU(gfortran/gcc)"
        echo '33\n1' | ./configure
        echo -e "\nCompile WRF"
        ./compile em_real &> $HOME/log-wrf/WRF_em_real.log
        flag=0
        for file in $(ls $HOME/WRF-4.0.1/main/*.exe)
        do
            flag=$(( $flag + 1 ))
        done
        if [ $flag -eq 4 ];then
            echo -e "\n\nWRF install ${green}successful${plain}\n"
            all_flag=$(( $all_flag + 1 ))
        else
            echo -e "\nInstall WRF ${red}failed${plain}，please check errors in logs($HOME/log-wrf/)\n"
            exit 1
        fi
    else
        echo -e "\nWRF already installed\n"
        all_flag=$(( $all_flag + 1 ))
    fi
}

# Install WPS
getWPS() {
    cd $HOME
    flag=0
    for file in $(ls $HOME/WPS-4.0.1/util/*.exe 2>/dev/null)
    do
        flag=$(( $flag + 1 ))
    done
    for file in $(ls $HOME/WPS-4.0.1/*.exe 2>/dev/null)
    do
        flag=$(( $flag + 1 ))
    done
    if [ $flag -ne 11 ];then
        echo -e "\nInstall WPS"
        if [ ! -s $HOME/WPS-4.0.1/configure ];then
            if [ ! -s $HOME/WPS-4.0.1.tar.gz ];then
            echo -e "\nDownload WPS"
            wget -c https://github.com/wrf-model/WPS/archive/v4.0.1.tar.gz
            mv ./v4.0.1.tar.gz ./WPS-4.0.1.tar.gz
            fi
            echo -e "\nExtract"
            tar -xf WPS-4.0.1.tar.gz
        fi
        cd WPS-4.0.1
        echo -e "\nClean"
        ./clean -a &>/dev/null
        echo -e "\nConfigure WPS: 1. Linux x86_64,gfortran (serial)"
        echo '1' | ./configure >/dev/null
        sed -i 's/-lnetcdff -lnetcdf/-lnetcdff -lnetcdf -lgomp/g' ./configure.wps
        echo -e "\nCompile WPS"
        ./compile &> $HOME/log-wrf/WPS.compile.log
        flag=0
        for file in $(ls $HOME/WPS-4.0.1/util/*.exe)
        do
            flag=$(( $flag + 1 ))
        done
        for file in $(ls $HOME/WPS-4.0.1/*.exe)
        do
            flag=$(( $flag + 1 ))
        done
        if [ $flag -eq 11 ];then
            echo -e "\n\nWPS install ${green}successful${plain}\n"
            all_flag=$(( $all_flag + 1 ))
        else
            echo -e "Install WPS ${red}failed${plain}，please check errors in logs($HOME/log-wrf/)\n"
        fi
    else
        echo -e "\nWPS already installed\n"
        all_flag=$(( $all_flag + 1 ))
    fi
}

checkFinish() {
    if [ $all_flag -eq 2 ];then
        echo -e "\nAll install ${green}successful${plain}\n"
        ls -d $HOME/WPS-4.0.1 --color=auto
        ls -d $HOME/WRF-4.0.1 --color=auto
        echo -e "\nClean"
        rm $HOME/src-wrf -r
        rm $HOME/log-wrf -r
        echo -e "\nEnjoy it\n"
        mv $HOME/.bashrc.wrf.bak.temp $HOME/.bashrc.wrf.bak
    else
        echo -e "\nInstall ${red}failed${plain}，please check errors\n"
        mv $HOME/.bashrc.wrf.bak $HOME/.bashrc
    fi
}


checkRoot
setSources
aptLib
creatLogs
getZilb
getJasper
getHDF5
getNetCDF
getBison
getFlex
getWRF
getWPS
checkFinish
getInfo
