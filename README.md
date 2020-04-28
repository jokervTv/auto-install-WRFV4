# auto-install-WRFV4

Automatically install WRF and WPS with Ubuntu and GCC.

The shell `autoInstall.sh` works well.
`install_wrf-4_GUN.sh` is deprecated.

## Feature

- support WRF
  - version
    - 4.2
  - compiler options
    - (smpar) GNU(gfortran/gcc)
- support WPS
  - version
    - 4.2
  - compiler options
    - Linux x86_64,gfortran (serial)
- change source
  - support Debian 7/8/9
  - support Ubuntu 14.04/16.06/18.04
  - support CentOS 5/6/7
- Multi-core compilation option support

## Getting Started

now only support Ubuntu:

```sh
wget -nv https://raw.githubusercontent.com/jokervTv/auto-install-WRFV4/master/autoInstall.sh && bash autoInstall.sh
```

## Test information

The script `autoInstall.sh` has been tested in

- aliyun ESC (Elastic Compute Service): Ubuntu 18.04 - successfully
- WSL2: Ubuntu 20.04 - successfully



## Todo

- [ ] WRF-Chem
- [ ] WRFDA
- [ ] MPAS support
- [ ] step-by-step tutorial
- [ ] more library download link
- [ ] more WRF/WPS version support
- [ ] more WRF/WPS compiler options support
- [ ] more Linux distribution support
- [ ] More tests

## Authors

Yongpeng Zhang zhangyp6603@outlook.com
