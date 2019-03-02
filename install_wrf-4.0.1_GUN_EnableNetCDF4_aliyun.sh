#!/bin/bash
#if you have any questions, Send a email to z1099135632@163.com.
#Start by
#wget https://raw.githubusercontent.com/jokervTv/auto-install-WRFV4/master/install_wrf-4.0.1_GUN_EnableNetCDF4_aliyun.sh && chmod 777 ./install_wrf-4.0.1_GUN_EnableNetCDF4.sh && ./install_wrf-4.0.1_GUN_EnableNetCDF4.sh


_install () {
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
    sudo make install >/dev/null
}

_check (){
    if [ ! -s $1 ];then
        echo -e "\n${red}ERROR:${plain} Failed to generate $1 as expected"
        echo "0"
    else
        echo "1"
    fi
}

#更新软件源
sudo mv /etc/apt/source.list /etc/apt/source.list.wrf.bak
sudo echo 'deb http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
' >> /etc/apt/source.list
echo -e "\nUpdate"
sudo apt-get update >/dev/null

#安装必要组件
echo -e "\nUpdate"
sudo apt-get update >/dev/null
echo -e "\nInstall glibc grib2 jpeg8 libpng16 perl curl"
sudo apt-get install -y glibc* libgrib2c0d libgrib2c-dev libjpeg8* libpng16* perl curl >/dev/null
sudo apt-get install -y libpng-tools &>/dev/null
sudo apt-get install -y libpng-devel &>/dev/null
sudo apt-get install -y libpng-dev &>/dev/null
echo -e "\nInstall tcsh samba cpp m4 quota"
sudo apt-get install -y tcsh samba cpp m4 quota >/dev/null
echo -e "\nInstall gcc g++ gfortran"
sudo apt-get install -y gcc g++ gfortran >/dev/null
echo -e "\nInstall make wget tar"
sudo apt-get install -y make wget tar >/dev/null

#创建日志和源码文件夹
echo -e "\nMkdir $HOME/log-wrf"
mkdir $HOME/log-wrf
echo -e "\nMkdir $HOME/src-wrf"
mkdir $HOME/src-wrf

echo -e "\nBackup .bashrc > .bashrc.wrf.bak"
if [ ! -s $HOME/.bashrc.wrf.bak ];then
    cp $HOME/.bashrc $HOME/.bashrc.wrf.bak.tmp
fi

#zlib
if [ ! -s "/usr/local/zlib-1.2.11/lib/libz.a" ]; then
    _install zlib-1.2.11
    if [ ! -s $HOME/.bashrc.wrf.bak ];then
        echo '' >> $HOME/.bashrc
        echo '#for zlib-1.2.11' >> $HOME/.bashrc
        echo 'export LD_LIBRARY_PATH=/usr/local/zlib-1.2.11/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
        source $HOME/.bashrc
    fi
fi


#jasper
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
fi


#hdf5
if [ ! -s "/usr/local/hdf5-1.10.2/lib/libhdf5.a" ]; then
    export LDFLAGS=-L/usr/local/zlib-1.2.11/lib
    export CPPFLAGS=-I/usr/local/zlib-1.2.11/include
    _install hdf5-1.10.2
    sudo make check-install &> $HOME/log-wrf/hdf5-1.10.2.CheckInstall.log
    if [ ! -s $HOME/.bashrc.wrf.bak ];then
        echo '' >> $HOME/.bashrc
        echo '#for hdf5-1.10.2' >> $HOME/.bashrc
        echo 'export LD_LIBRARY_PATH=/usr/local/hdf5-1.10.2/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
        source $HOME/.bashrc
    fi
fi


#netcdf
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
fi

#bison
if [ ! -s "/usr/local/bison-3.1/bin/bison" ]; then
    _install bison-3.1
    echo '' >> $HOME/.bashrc
    echo '#for bison-3.1' >> $HOME/.bashrc
    echo 'export PATH=/usr/local/bison-3.1/bin:$PATH' >> $HOME/.bashrc
    echo 'export PATH=/usr/local/bison-3.1:$PATH' >> $HOME/.bashrc
    echo "export YACC='yacc -d'" >> $HOME/.bashrc
    source $HOME/.bashrc
    export PATH=/usr/local/bison-3.1/bin:$PATH
    export PATH=/usr/local/bison-3.1:$PATH
    export YACC='yacc -d'
fi

#flex
if [ ! -s "/usr/local/flex-2.5.3/bin/flex" ]; then
    _install flex-2.5.3
    echo '' >> $HOME/.bashrc
    echo '#for flex-2.5.3' >> $HOME/.bashrc
    echo 'export PATH=/usr/local/flex-2.5.3/bin:$PATH' >> $HOME/.bashrc
    echo 'export FLEX=/usr/local/flex-2.5.3/bin/flex' >> $HOME/.bashrc
    echo "export FLEX_LIB_DIR=/usr/local/flex-2.5.3/lib" >> $HOME/.bashrc
    source $HOME/.bashrc
    export PATH=/usr/local/flex-2.5.3/bin:$PATH
    export FLEX=/usr/local/flex-2.5.3/bin/flex
    export FLEX_LIB_DIR=/usr/local/flex-2.5.3/lib
fi


if [ ! -s $HOME/.bashrc.wrf.bak ];then
    echo '' >> $HOME/.bashrc
    echo '#for WRF' >> $HOME/.bashrc
    echo 'export NETCDF=/usr/local/NETCDF-4.4' >> $HOME/.bashrc
    echo 'export WRFIO_NCD_LARGE_FILE_SUPPORT=1' >> $HOME/.bashrc
    echo 'export WRF_CHEM=1' >> $HOME/.bashrc
    echo 'export WRF_KPP=1' >> $HOME/.bashrc
    source $HOME/.bashrc
    mv $HOME/.bashrc.wrf.bak.tmp $HOME/.bashrc.wrf.bak
fi

all_flag=0

#For WRF
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
    export JASPERLIB=/usr/local/jasper-1.900.1/lib
    export JASPERINC=/usr/local/jasper-1.900.1/include
    export NETCDF=/usr/local/NETCDF-4.4
    export WRFIO_NCD_LARGE_FILE_SUPPORT=1
    export J="-j 4"
    ulimit -s unlimited
#    cd arch
#   echo -e "\nReplace config file"
#   wget -c https://code.aliyun.com/z1099135632/wrf-3.9.1.1/raw/master/data/Config_new.pl
#    cd ..
    echo -e "\nConfigure WRF: 33.(smpar) GNU(gfortran/gcc)"
    echo '33\n1' | ./configure >/dev/null
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

#For WPS
cd $HOME
flag=0
for file in $(ls $HOME/WPS-4.0.1/util/*.exe 2>/dev/null)
do
    flag=$(( $flag + 1 ))
done
for file in $(ls $HOME/WPS/*.exe 2>/dev/null)
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
    for file in $(ls $HOME/WPS/util/*.exe)
    do
        flag=$(( $flag + 1 ))
    done
    for file in $(ls $HOME/WPS/*.exe)
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

#for chem
cd $HOME/WRF-4.0.1
./compile emi_conv &> $HOME/log-wrf/WRF_emi_conv.log

if [ $all_flag -eq 2 ];then
    echo -e "\nAll install ${green}successful${plain}\n"
    ls -d $HOME/WPS --color=auto
    ls -d $HOME/WRF --color=auto
    echo -e "\nClean"
    sudo rm $HOME/src-wrf -r
    sudo rm $HOME/log-wrf -r
    echo -e "\nEnjoy it\n"
else
    echo -e "\nInstall ${red}failed${plain}，please check errors\n"
fi
