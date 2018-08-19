#!/bin/bash
#if you have any questions, Send a email to z1099135632@163.com.
#Start by
#wget https://raw.githubusercontent.com/jokervTv/auto-install-WRFV4/master/ncl-new.sh && sudo chmod 777 ./ncl-new.sh && sudo ./ncl-new.sh

clear

version_ncl="6.5.0"
usr_libssl_ubuntu="http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4.1_amd64.deb"
usr_libssl_debian="http://ftp.cn.debian.org/debian/pool/main/o/openssl/libssl1.1_1.1.0f-3+deb9u2_amd64.deb"
contos_url="https://www.earthsystemgrid.org/dataset/ncl.650.dap/file/ncl_ncarg-6.5.0-CentOS7.5_64bit_gnu485.tar.gz"
debian_url="https://www.earthsystemgrid.org/dataset/ncl.650.dap/file/ncl_ncarg-6.5.0-Debian9.4_64bit_gnu630.tar.gz"

#检查管理员权限
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] 请使用${red}管理员权限${plain}运行此脚本!" && exit 1

#选择安装目录
DEncldir="/opt/NCL"
echo "请手动输入 NCL 安装目录(默认配置可直接回车)："
echo "默认安装位置(绝对路劲) $DEncldir"
read ncldir
if [ ! -n "$ncldir" ]; then
    ncldir="$DEncldir"
fi
echo "|||-----------------------|||"
echo "||  安装位置 $ncldir"
echo "|||-----------------------|||"

#匹配系统版本
os_release=''
sys_package=''

if [[ -f /etc/redhat-release ]]; then
    os_release="centos"
    sys_package="yum"
elif cat /etc/issue | grep -Eqi "debian"; then
    os_release="debian"
    sys_package="apt"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    os_release="ubuntu"
    sys_package="apt"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    os_release="centos"
    sys_package="yum"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    os_release="ubuntu"
    sys_package="apt"
elif cat /proc/version | grep -Eqi "debian"; then
    os_release="debian"
    sys_package="apt"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    os_release="centos"
    sys_package="yum"
else
    echo "||     系统不支持       ||"
    echo "|||--------------------|||"
    exit 1
fi
echo "||  当前系统：$os_release   ||"

#安装必备依赖项
echo "||      安装 依赖       ||"
echo "|||--------------------|||"
$sys_package update
if [ $os_release == "centos" ]; then
    $sys_package -y --force-yes install -y wget tcsh libbz2-dev wget xorg-dev libx11-dev gfortran x11-dev >/dev/null
else
    $sys_package -y --force-yes install -y wget tcsh libxrender1 libfontconfig1 libxext6 libgfortran3 libgomp1 >/dev/null #libbz2-dev wget libX11-devel cairo-devel gcc-gfortran libxrender1
fi

if [ $os_release == "ubuntu" ]; then
    wget "$usr_libssl_ubuntu"
elif [ $os_release == "debian" ]; then
    wget "$usr_libssl_debian"
else
    echo "error for centos"
    echo "because i don't where can download libssl1.1 for NCL-6.5"
    exit 1
fi
dpkg -i ./libssl1.1_1.1*
rm ./libssl1.1_1.1*

#本地环境变量修改
if [ ! -s "~/.ncl.bashrc.bak" ]; then
    cp ~/.bashrc ~/.ncl.bashrc.bak
    echo "" >> ~/.bashrc
    echo "#for NCL" >> ~/.bashrc
    echo "export NCARG_ROOT=$ncldir" >> ~/.bashrc
    echo 'export PATH=$NCARG_ROOT/bin:$PATH' >> ~/.bashrc
    echo "" >> ~/.bashrc
    source ~/.bashrc
fi

#NCL
mkdir $ncldir
if [ ! -s "`ls ncl_ncarg*`" ]; then
    echo "||   下载 NCL 安装包    ||"
    echo "|||--------------------|||"
    cd $ncldir
    if [ $os_release == "centos" ]; then
        wget -c "$contos_url"
    else
        wget -c "$debian_url"
    fi
    tar -xf ncl_ncarg*.tar.gz
else
    tar -xf ncl_ncarg* -C $ncl_ncarg/
fi

#检验安装是否成功
source ~/.bashrc
version=`ncl -V`
if [ version = "$version_ncl" ]; then
    echo -e "\n\n${green}安装成功${plain}\n\n"
    rm ncl_ncarg*
else
    echo -e "\n\n${red}安装失败${plain}，请删除环境变量\n\n"
    mv ~/.ncl.bashrc.bak ~/.bashrc
    echo -e "ncl安装包位于 $ncldir/"
fi
