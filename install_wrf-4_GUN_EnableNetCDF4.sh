#!/bin/bash
#if you have any questions, Send a email to z1099135632@163.com.
#Start by
#wget https://raw.githubusercontent.com/jokervTv/auto-install-WRFV4/master/install_wrf-4_GUN_EnableNetCDF4.sh && chmod 777 ./install_wrf-4_GUN_EnableNetCDF4.sh && ./install_wrf-4_GUN_EnableNetCDF4.sh


_install () {
    cd ~/src-wrf
    rm -rf ~/src-wrf/$1
    rm -f ~/src-wrf/$1.tar.gz*
    echo -e "\nDownload $1"
    wget -c https://code.aliyun.com/z1099135632/wrf-3.9.1.1/raw/master/data/$1.tar.gz
    echo -e "\nExtract $1"
    tar -xf $1.tar.gz
    rm $1.tar.gz*
    echo -e "\nDelect $1.tar.gz"
    cd ~/src-wrf/$1
    echo -e "\nConfigure & make $1"
    if [ "$1" == "hdf5-1.10.2" ]; then
        ./configure --prefix=/usr/local/hdf5-1.10.2 --with-zlib=/usr/local/zlib-1.2.11 >/dev/null
        make -j4 >/dev/null 2>~/log-wrf/$1.make.log
    elif [ "$1" == "netcdf-4.4.1" ]; then
        ./configure --prefix=/usr/local/NETCDF-4.4 --enable-netcdf-4 >/dev/null
        make -j4 >/dev/null 2>~/log-wrf/$1.make.log
    elif [ "$1" == "netcdf-fortran-4.4.4" ]; then
        ./configure FC=gfortran --prefix=/usr/local/NETCDF-4.4 >/dev/null
        make -j4 >/dev/null 2>~/log-wrf/$1.make.log
    else
        ./configure --prefix=/usr/local/$1 >/dev/null
        make -j4 >/dev/null 2>~/log-wrf/$1.make.log
    fi
    echo -e "\nCheck $1"
    make check &> ~/log-wrf/$1.Check.log
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

#安装必要组件
#echo -e "\nUpdate"
#sudo apt-get update >/dev/null
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
echo -e "\nMkdir ~/log-wrf"
mkdir ~/log-wrf
echo -e "\nMkdir ~/src-wrf"
mkdir ~/src-wrf

echo -e "\nBackup .bashrc > .bashrc.wrf.bak"
if [ ! -s ~/.bashrc.wrf.bak ];then
    cp ~/.bashrc ~/.bashrc.wrf.bak.tmp
fi

#zlib
if [ ! -s "/usr/local/zlib-1.2.11/lib/libz.a" ]; then
    _install zlib-1.2.11
    if [ ! -s ~/.bashrc.wrf.bak ];then
        echo '' >> ~/.bashrc
        echo '#for zlib-1.2.11' >> ~/.bashrc
        echo 'export LD_LIBRARY_PATH=/usr/local/zlib-1.2.11/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
        source ~/.bashrc
    fi
fi


#jasper
if [ ! -s "/usr/local/jasper-1.900.1/lib/libjasper.a" ]; then
    _install jasper-1.900.1
    if [ ! -s ~/.bashrc.wrf.bak ];then
        echo '' >> ~/.bashrc
        echo '#set JASPER' >> ~/.bashrc
        echo 'export JASPER=/usr/local/jasper-1.900.1' >> ~/.bashrc
        echo 'export JASPERLIB=/usr/local/jasper-1.900.1/lib' >> ~/.bashrc
        echo 'export JASPERINC=/usr/local/jasper-1.900.1/include' >> ~/.bashrc
        echo 'export LD_LIBRARY_PATH=/usr/local/jasper-1.900.1/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
        source ~/.bashrc
    fi
fi


#hdf5
if [ ! -s "/usr/local/hdf5-1.10.2/lib/libhdf5.a" ]; then
    export LDFLAGS=-L/usr/local/zlib-1.2.11/lib
    export CPPFLAGS=-I/usr/local/zlib-1.2.11/include
    _install hdf5-1.10.2
    sudo make check-install &> ~/log-wrf/hdf5-1.10.2.CheckInstall.log
    if [ ! -s ~/.bashrc.wrf.bak ];then
        echo '' >> ~/.bashrc
        echo '#for hdf5-1.10.2' >> ~/.bashrc
        echo 'export LD_LIBRARY_PATH=/usr/local/hdf5-1.10.2/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
        source ~/.bashrc
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
    if [ ! -s ~/.bashrc.wrf.bak ];then
        echo '' >> ~/.bashrc
        echo '#for netcdf-4.4' >> ~/.bashrc
        echo 'export PATH=/usr/local/NETCDF-4.4/bin:$PATH' >> ~/.bashrc
        echo 'export LD_LIBRARY_PATH=/usr/local/NETCDF-4.4/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
        source ~/.bashrc
    fi
fi

if [ ! -s ~/.bashrc.wrf.bak ];then
    echo '' >> ~/.bashrc
    echo '#for WRF' >> ~/.bashrc
    echo 'export NETCDF=/usr/local/NETCDF-4.4' >> ~/.bashrc
    echo 'export WRFIO_NCD_LARGE_FILE_SUPPORT=1' >> ~/.bashrc
    source ~/.bashrc
    mv ~/.bashrc.wrf.bak.tmp ~/.bashrc.wrf.bak
fi

all_flag=0

#For WRF
cd ~
flag=0
for file in $(ls ~/WRF/main/*.exe 2>/dev/null)
do
    flag=$(( $flag + 1 ))
done
if [ $flag -ne 4 ];then
    echo "Install WRFV4"
    if [ ! -s ~/WRF/configure ];then
        if [ ! -s ~/WRFV4.0.TAR.gz ];then
        echo -e "\nDownload WRF-4"
        wget -c http://www2.mmm.ucar.edu/wrf/src/WRFV4.0.TAR.gz
        fi
        echo -e "\nExtract WRFV4.TAR.gz"
        tar -xf WRFV4.0.TAR.gz
    fi
    cd WRF
    echo -e "\nClean"
    ./clean -a &>/dev/null
    export JASPERLIB=/usr/local/jasper-1.900.1/lib
    export JASPERINC=/usr/local/jasper-1.900.1/include
    export NETCDF=/usr/local/NETCDF-4.4
    export WRFIO_NCD_LARGE_FILE_SUPPORT=1
    export J="-j 4"
    ulimit -s unlimited
    cd arch
    cd ..
    echo -e "\nConfigure WRF: 33.(smpar) GNU(gfortran/gcc)"
    echo '33\n1' | ./configure >/dev/null
    sed -i 's/-lnetcdff -lnetcdf/-lnetcdff -lnetcdf -lgomp/g' ./configure.wrf
    echo -e "\nCompile WRF"
    ./compile em_real &> ~/log-wrf/WRFV4_em_real.log
    flag=0
    for file in $(ls ~/WRF/main/*.exe)
    do
        flag=$(( $flag + 1 ))
    done
    if [ $flag -eq 4 ];then
        echo -e "\n\nWRF install ${green}successful${plain}\n"
        all_flag=$(( $all_flag + 1 ))
    else
        echo -e "\nInstall WRF ${red}failed${plain}，please check errors in logs(~/log-wrf/)\n"
        exit 1
    fi
else
    echo -e "\nWRF already installed\n"
    all_flag=$(( $all_flag + 1 ))
fi

#For WPS
cd ~
flag=0
for file in $(ls ~/WPS/util/*.exe 2>/dev/null)
do
    flag=$(( $flag + 1 ))
done
for file in $(ls ~/WPS/*.exe 2>/dev/null)
do
    flag=$(( $flag + 1 ))
done
if [ $flag -ne 11 ];then
    echo -e "\nInstall WPS"
    if [ ! -s ~/WPS/configure ];then
        if [ ! -s ~/WPSV4.0.TAR.gz ];then
        echo -e "\nDownload WPS-4"
        wget -c http://www2.mmm.ucar.edu/wrf/src/WPSV4.0.TAR.gz
        fi
        echo -e "\nExtract WPS-4"
        tar -xf WPSV4.0.TAR.gz
    fi
    cd WPS
    echo -e "\nClean"
    ./clean -a &>/dev/null
    echo -e "\nConfigure WPS: 1. Linux x86_64,gfortran (serial)"
    echo '1' | ./configure >/dev/null
    sed -i 's/-lnetcdff -lnetcdf/-lnetcdff -lnetcdf -lgomp/g' ./configure.wps
    echo -e "\nCompile WPS"
    ./compile &> ~/log-wrf/WPS.compile.log
    flag=0
    for file in $(ls ~/WPS/util/*.exe)
    do
        flag=$(( $flag + 1 ))
    done
    for file in $(ls ~/WPS/*.exe)
    do
        flag=$(( $flag + 1 ))
    done
    if [ $flag -eq 11 ];then
        echo -e "\n\nWPS install ${green}successful${plain}\n"
        all_flag=$(( $all_flag + 1 ))
    else
        echo -e "Install WPS ${red}failed${plain}，please check errors in logs(~/log-wrf/)\n"
    fi
else
    echo -e "\nWPS already installed\n"
    all_flag=$(( $all_flag + 1 ))
fi

if [ $all_flag -eq 2 ];then
    echo -e "\nAll install ${green}successful${plain}\n"
    ls -d ~/WPS --color=auto
    ls -d ~/WRF --color=auto
    echo -e "\nClean"
    sudo rm ~/src-wrf -r
    sudo rm ~/log-wrf -r
    echo -e "\nEnjoy it\n"
else
    echo -e "\nInstall ${red}failed${plain}，please check errors\n"
fi
