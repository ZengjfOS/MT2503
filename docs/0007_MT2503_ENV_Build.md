# MT2503 ENV Build

操作系统尽量使用英文操作系统，血的教训。

# RVCT Install

* 安装Perl：`ActivePerl-5.8.8.822-MSWin32-x86-280952.msi`；
* 安装RVCT：
  * 给`RVCT_ok\Install\RVCT 3.1 installfile`目录下的`setup.exe`管理员权限，并设置兼容模式下运行；
  * 运行`RVCT_ok\Install\RVCT 3.1 installfile`目录下的`setup.exe`，选择默认安装目录，安装过程中选择`RVCT ONLY`，默认不安装lisence；
  * `RVCT_ok\Install\RVCT 3.1 crack`中的内容拷贝到RVCT默认安装目录；
  * 为了看到`crack.bat`的输出内容，在`crack.bat`文件末尾加入`pause`语句；
  * 给`ecc.exe`默认管理员运行权限；
  * [开始]菜单，run --> cmd，管理员权限打开dos窗口，跳转到安装目录，貌似个人还是比较喜欢的PowerShell的；
  * 运行`crack.bat`；
    ```
    C:\Program Files\ARM>.\crack.bat
    
    C:\Program Files\ARM>ecc
    .\RVCT\Programs\3.1\569\win_32-pentium\armasm.exe :
    Found Push 292a at 7ed5bf7b
    Found Func Header at 7ed5ba11
    Success
    .\RVCT\Programs\3.1\569\win_32-pentium\armcc.exe :
    Found Push 292a at 7e5ab3cb
    Found Func Header at 7e5aae61
    Success
    .\RVCT\Programs\3.1\569\win_32-pentium\armcpp.exe :
    Found Push 292a at 7dddb3cb
    Found Func Header at 7dddae61
    Success
    .\RVCT\Programs\3.1\569\win_32-pentium\armlink.exe :
    Found Push 292a at 7daf8b5b
    Found Func Header at 7daf85f1
    Success
    .\RVCT\Programs\3.1\569\win_32-pentium\fromelf.exe :
    Found Push 292a at 7d87ca2b
    Found Func Header at 7d87c4c1
    Success
    .\RVCT\Programs\3.1\569\win_32-pentium\tcc.exe :
    Found Push 292a at 7d0cb3cb
    Found Func Header at 7d0cae61
    Success
    .\RVCT\Programs\3.1\569\win_32-pentium\tcpp.exe :
    Found Push 292a at 7c8fb3cb
    Found Func Header at 7c8fae61
    Success
    .\Utilities\FLEXlm\10.8.5.0\1\linux-pentium\armlmd :
    Fail
    .\Utilities\FLEXlm\10.8.5.0\1\linux-pentium\lmgrd :
    Fail
    .\Utilities\FLEXlm\10.8.5.0\1\linux-pentium\lmutil :
    Fail
    .\Utilities\FLEXlm\10.8.5.0\1\linux-pentium-rh72\armlmd :
    Fail
    .\Utilities\FLEXlm\10.8.5.0\1\linux-pentium-rh72\lmgrd :
    Fail
    .\Utilities\FLEXlm\10.8.5.0\1\linux-pentium-rh72\lmutil :
    Fail
    .\Utilities\FLEXlm\10.8.5.0\1\solaris-sparc\armlmd :
    Fail
    .\Utilities\FLEXlm\10.8.5.0\1\solaris-sparc\lmgrd :
    Fail
    .\Utilities\FLEXlm\10.8.5.0\1\solaris-sparc\lmutil :
    Fail
    .\Utilities\FLEXlm\10.8.5.0\1\win_32-pentium\armlmd.exe :
    Found Push 292a at 7c815c2b
    Found Func Header at 7c815330
    Success
    .\Utilities\FLEXlm\10.8.5.0\1\win_32-pentium\lmgrd.exe :
    Fail
    .\Utilities\FLEXlm\10.8.5.0\1\win_32-pentium\lmtools.exe :
    Fail
    .\Utilities\FLEXlm\10.8.5.0\1\win_32-pentium\lmutil.exe :
    Fail
    .\Utilities\LicenseWizard\4.1\53\win_32-pentium\licwizard.exe :
    Found Push 292a at 7c16f041
    Found Func Header at 7c16eb65
    Success
    ```
  * 安装目录的`rvds.dat`就是lisence文件，拷贝到其他磁盘分区内根目录内，如D盘下，好像在C盘不行；
  * 开始菜单，找到ARM文件夹，打开并执行`Lisence Wizard V4.1`，选择`Install Lisence`，
  * 如果要卸载，要在开始菜单中选中对应的部分，右键，属性，给兼容模式和管理员权限，再进行相关的操作；
  * 升级build number,用最新的armar.exe代替就可以了（大小不一样，最新的比较大）；
  * 安装excel，必须有excel，才能正常编译；

## Make

* make help
  ```
  D:\MTK2503\SDK>make
  
  Usage:
    make ["customer"|"mt62xx"] "project" "action" ["modules"]|"file1[ file2[ ...]]
   | @files"
  
  Description:
    customer   = mtk             (Default customer)
               = firefly17_demo  (FIREFLY17_DEMO project)
               = [mt6217|mt6219|mt6226|mt6227|mt6228|mt6229] (EVB only)
               = ...
  
    project    = l1s             (Layer 1 stand-alone)
               = gsm             (GSM only)
               = gprs            (GPRS only)
               = umts            (GPRS+UMTS)
               = hspa            (GPRS+UMTS+HSPA)
               = tdd128          (GPRS+TDD128)
               = tdd128dpa       (GPRS+TDD128+HSDPA)
               = tdd128hspa      (GPRS+TDD128+HSPA)
               = basic           (Basic Framework)
  
    action     = new             (codegen, resgen, clean, update) (default)
               = update or u     (scan, compile, link)
               = slim_update     (scan, compile, link without generating mcddll)
               = remake or r     (compile, link)
               = clean or c      (clean)
               = cci or clean_codegen (clean codegen intermedia files)
               = resgen          (resgen)
               = c,u             (clean then update)
               = c,r             (clean then remake)
               = codegen         (codegen)
               = slim_codegen    (codegen without generating mcddll)
               = mcddll_update   (codegen and generate mcddll)
               = slim_mcddll     (generate mcddll without codegen)
               = viewlog         (open edit to view build log)
               = emigen          (emigen)
               = emiclean        (emiclean)
               = check_dep       (check dependency module(s) after source(s)/header(s) changed)
               = remake_dep      (check_dep, remake)
               = update_dep      (check_dep, update)
  
    module(s)  = modules' name   (kal, l1, ...)
     => OPTIONAL when action is one of (clean c remake r update u c,r c,u)
  
    file1      = changed source/header's name (init\include\init.h, ...)
     => VALID ONLY when action is one of (check_dep remake_dep update_dep)
     => MANDATORY when action is one of (check_dep remake_dep update_dep) and @fil
  es is NOT specified
  
    @files     = Specify more changed sources/headers via a file (change list)
     => VALID ONLY when action is one of (check_dep remake_dep update_dep)
     => MANDATORY when action is one of (check_dep remake_dep update_dep) and file
  1 is NOT specified
  
  Example:
    make gsm new                         (MT6205B EVB new)
    make gprs codegen                    (MT6218B EVB codegen)
    make mt6219 gprs update              (MT6219 EVB update)
    make firefly17_demo gprs new
    make milan_demo gprs c,u init custom
    make mt6219 gprs r init custom drv
    make mt6229 gprs check_dep init\include\init.h
    make mt6229 gprs remake_dep @make\init\init.lis
    make mt6229 gprs update_dep init\src\init.c
  ```
* `.\make ULTRA2503A_11C GPRS new`
* 编译期间卡顿，按一下Enter键就可以继续编译，所以有些时候卡主了，需要按一下Enter键才会继续编译：
  ```
  ...
  Generate ft information
  Generate ftc information
  Generate gdi information
  Generate gdi_arm information
  Generate gfx_drv information
  Generate gps information          [卡顿住，按Enter键]
  ...
  ```
* 编译完成：
  ```
  ...
  [Dependency] D:\MTK2503\SDK\.\tools\\sysGenUtility.pm
  [Dependency] D:\MTK2503\SDK\tools\CMMAutoGen.pl
  [Dependency] D:\MTK2503\SDK\.\tools\\sysgenUtility.pm
  [Dependency] D:\MTK2503\SDK\tools\pack_dep_gen.pm
  [Dependency] D:\MTK2503\SDK\.\tools\\CommonUtility.pm
  [Dependency] D:\MTK2503\SDK\.\tools\\FileInfoParser.pm
  [Dependency] D:\MTK2503\SDK\.\tools\\sysGenUtility.pm
  [Dependency] D:\MTK2503\SDK\tools\CMMAutoGen.pl
  [Dependency] D:\MTK2503\SDK\.\tools\\sysgenUtility.pm
  [Dependency] D:\MTK2503\SDK\tools\pack_dep_gen.pm
  [Dependency] D:\MTK2503\SDK\.\tools\\CommonUtility.pm
  [Dependency] D:\MTK2503\SDK\.\tools\\LISInfo.pm
  [Dependency] D:\MTK2503\SDK\.\tools\\FileInfoParser.pm
  [Dependency] D:\MTK2503\SDK\.\tools\\sysGenUtility.pm
  Generate CFG file for flash tool
  [Dependency] D:\MTK2503\SDK\.\tools\cfgGen.pl
  [Dependency] D:\MTK2503\SDK\tools\pack_dep_gen.pm
  [Dependency] D:\MTK2503\SDK\tools\sysGenUtility.pm
  "hal\drv_def\drv_features_6261.h", line 86: Warning:  #1-D: last line of file ends without a newline
  
     ^
  Generate a table for module ID and library...
  check system drive ....
  Cleaning make\~*.tmp files ...
  Done.
  2018/06/04 19:08:57
  PS D:\MTK2503\SDK>
  ```
