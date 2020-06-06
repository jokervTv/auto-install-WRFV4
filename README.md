# auto-install-WRFV4

Automatically install WRF and WPS using GUN.

The shell `autoInstall.sh` works well.
`install_wrf-4_GUN.sh` is deprecated.

## Feature

- support Ubuntu, CentOS
- support WRF
  - version: 4.2
  - default compiler options: (smpar) GNU(gfortran/gcc)
- support WPS
  - version: 4.2
  - default compiler options: Linux x86_64,gfortran (serial)
- suport WRFDA
  - version: 4.2
  - default compiler options: (smpar) GNU(gfortran/gcc)
  - installed WRFPLUS and WRFDA for 4DVAR run
- suport WRFHydro
  - version: 4.2
  - default compiler options: (dmpar) GNU (gfortran/gcc)
  - coupled
- suport WRF-chem
  - version: 4.2
  - default compiler options: (smpar) GNU (gfortran/gcc)
- change source
  - support Debian 7/8/9
  - support Ubuntu 14.04/16.06/18.04
  - support CentOS 5/6/7
- Multi-core compilation option support

**Note**:

- WRF-chem will be build without Kpp in Ubuntu, but with Kpp in CentOS.
- WRFHydro can NOT build successfully in CentOS now.

## Getting Started

Run the following command in your terminal.

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/jokervTv/auto-install-WRFV4/master/autoInstall.sh)"
```

## Test information

The script `autoInstall.sh` has been tested in

- aliyun ESC (Elastic Compute Service): Ubuntu 18.04 - successfully
- aliyun ESC (Elastic Compute Service): CentOS 8.1 - successfully

## Todo

- [ ] WRF-Chem(with KPP) support
- [ ] step-by-step tutorial
- [ ] more library download link
- [ ] ~~more WRF/WPS version support~~
- [ ] more WRF/WPS compiler options support

## Authors

Yongpeng Zhang: zhangyp6603@outlook.com
