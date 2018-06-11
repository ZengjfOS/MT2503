# MT2503 Make Hacking

* `make2.pl`脚本最后执行的一行代码是`exit $result >> 8;`，之前的都是执行的从上到下的代码，在此之后的都是会被调用的处理函数；
* 主要跟踪的是`.\make ULTRA2503A_11C GPRS new`执行的流程；
* `make\ULTRA2503A_11C_GPRS.mak`中的内容在其他Makefile中会被include进去，这样这里面的键值对就被用于选择模块定义了；

## 参考文档

* [MTK 功能机编译](https://blog.csdn.net/u010783226/article/details/73368922)
* [MTK手机开发入门教程](https://wenku.baidu.com/view/242349d75727a5e9846a6152.html)
* [Using multiple IF statements in a batch file](https://stackoverflow.com/questions/6711615/using-multiple-if-statements-in-a-batch-file)

## 代码跟踪

* 执行命令：`.\make ULTRA2503A_11C GPRS new`；
* Make.bat；
  ```
  perl make2.pl %* 2>&1
  ```
* [refers/make2.pl](refers/make2.pl)里面加了调试信息输出，[refers/make2.pl.log](refers/make2.pl.log)是编译过程的输出信息；
  * `project=gprs`
  * `custom=ULTRA2503A_11C`
  * `prj_file: make\ULTRA2503A_11C_gprs.mak`
    ```Perl
    $prj_file = "make/${custom}_${project}.mak";
    ...[省略]
    sub get_package
    {
      my $package = "";
      if (-e "$prj_file") {
        open(MAKFILE, "$prj_file") || die "Can not open txt file!";
        while(<MAKFILE>)
        {
          chomp;
          if ($_ =~ /RELEASE_PACKAGE\s*=\s*(\w*)/i)
          {
            $package = $1;
            print "get package: $1\n";
            last;
          }
        }
        close(MAKFILE);
      }
      return $package;
    }
    ```
  * `make.ini`
    ```Perl
    open (FILE_HANDLE, ">$ini") or die "cannot open $ini\n";
    print FILE_HANDLE "plat= \ncustom= $custom\nproject= $project\n";
    close FILE_HANDLE;
    ```
  * `~net_path.tmp`
    ```Perl
    open (FILE_HANDLE, ">~net_path.tmp") or die "Cannot open ~net_path.tmp";
    if ($ENV{'MTK_INTERNAL'} eq 'TRUE')
    {
    	$net_path = &get_net_path;
    	print FILE_HANDLE "NET_PATH = $net_path\n";
    }
    close FILE_HANDLE;
    ```
  * `package=REL_CR_MMI_`
    ```Perl
    $package = &get_package;
    print "package: $package\n";
    if ($package =~ /_(OBJ)_/i)
    {
     @tools_Dirs = qw(tools\\);
    }
    else
    {
      if ($WISDOM_CUSTOM_BUILD eq "TRUE") {
        @tools_Dirs = qw(tools\\ tools\\MinGW);
      } else {
        @tools_Dirs = qw(tools\\ tools\\MinGW tools\\MSYS);
      }
    }

    # tools_Dirs= tools\ tools\MinGW tools\MSYS
    print "tools_Dirs: @tools_Dirs\n";
    ```
  * `tools_file=tools\make.exe`
  * `ULTRA2503A_11C_gprs.log`
  * `theMF=make\ULTRA2503A_11C_gprs.mak`：这个文件中的key、value会被替换成perl的变量、值
    ```Perl
    open (FILE_HANDLE, "+<$theMF") or die "Cannot open $theMF. Please check if the file is READ-ONLY or not exists.\n";
    $LOGFILE = "${custom}_${project}.log";
    open (LOGFILE,">$LOGFILE") or die "Cannot open ${custom}_${project}.log.\n";
    $line = 0;
    while (<FILE_HANDLE>) {
      if (/^(\w+)\b\s*=/)                   # 匹配以字符开始的行
      {
        if (/^(\S+)\s*=\s*(\S+)/) {         # 匹配以=为键值对的行
          $line++;
          # Returns an uppercased version of EXPR.
          if ($1 ne uc($1)) {               # 键值对的key要全部大写
            print "Line $line: Feature name $1 should be UPPER cases. Correct $1 to ".uc($1)." automatically.\n";
            print LOGFILE "Line $line: Feature name $1 should be UPPER cases. Correct $1 to ".uc($1)." automatically.\n";
            $currentPosition = tell(FILE_HANDLE);
            seek(FILE_HANDLE, $postPosition, 0);
            $currentPosition = tell(FILE_HANDLE);
            $old_feature = $1;
            $new_feature = uc($1);
            $_ =~ s/$old_feature/$new_feature/;
            print FILE_HANDLE $_;
          }
          $keyname = lc($1);
          #defined($${keyname}) && warn "$1 redefined in $thefile!\n";  # 检查key是否已经是变量了
          if (($2 ne uc($2)) && ($1 !~ /SECURE_CUSTOM_NAME/i) && ($1 !~ /IPSEC_SUPPORT/i) && ($1 !~ /CUSTOM_CFLAGS/i) && ($1 !~ /RELEASE_PACKAGE/i) && ($1 !~ /COMPLIST/i) && ($1 !~ /COMP_TRACE_DEFS/i) && ($1 !~ /CUSTOM_COMMINC/i) && ($1 !~ /L1_TMD_FILES/i) && ($1 !~ /PARTIAL_TRACE_LIB/i)) { # 键值对的value要全部大写
            print "Line $line: Feature value $2 should be UPPER cases. Correct $2 to ".uc($2)." automatically.\n";
            print LOGFILE "Line $line: Feature value $2 should be UPPER cases. Correct $2 to ".uc($2)." automatically.\n";
            $currentPosition = tell(FILE_HANDLE);
            seek(FILE_HANDLE, $postPosition, 0);
            $currentPosition = tell(FILE_HANDLE);
            $old_feature = $2;
            $new_feature = uc($2);
            $_ =~ s/$old_feature/$new_feature/;
            print FILE_HANDLE $_;
          }
          $${keyname} = uc($2);                                         # 相当于重新定义变量
        }
      }
      $postPosition=tell(FILE_HANDLE);
    }
    close LOGFILE;
    close FILE_HANDLE;

    # flavorMF=
    # copy /y make\ULTRA2503A_11C_gprs.mak make\> nul
    system("copy /y ${makeFolder}${custom}_${project}.mak ${makeFolder}${flavorMF}> nul");
    ```
  * `enFile=make\ULTRA2503A_11C_gprs_en.def`
  * `disFile=make\ULTRA2503A_11C_gprs_dis.def`
  * `theVerno=make\Verno_ULTRA2503A_11C.bld`
    ```Perl
    open (FILE_HANDLE, "<$theVerno") or die "cannot open $theVerno\n";
    while (<FILE_HANDLE>) {
      if ((/^([^\#]*)\#?.*/) && ($1 =~ /^(\w+)\s*=\s*(.*\S)\s*$/)) {
        $keyname = lc($1);
        #defined($${keyname}) && warn "$1 redefined in $thefile!\n";
        $${keyname} = uc($2);
        print "${keyname}: $${keyname}\n";
      }
    }
    close FILE_HANDLE;
    ```
  * `make\Custom.bld`
    ```Perl
    open (FILE_HANDLE, "<make\\Custom.bld") or die "Cannot open make\\Custom.bld\n";
    while (<FILE_HANDLE>) {
      if (/^(\S+)\s*=\s*(\S+)/) {
        $keyname = lc($1);
        if(defined($${keyname}) && $${keyname} ne ""){
          next;
        }
        #defined($${keyname}) && warn "$1 redefined in $thefile!\n";
        $${keyname} = uc($2);
      }
    }
    close FILE_HANDLE
    ```
  * `make\app_cfg.mak`
    ```Perl
    open(F,">make\\app_cfg.mak");

    if ($action eq "lint") {
      print F "LINT=TRUE\n";
      @theAct = qw(remake);
    } else {
      print "action: $action\n";
      print F "LINT=FALSE\n";
      if ($action eq "c,r") {
        @theAct = qw(clean remake);
      } elsif ($action eq "c,u") {
        @theAct = qw(clean update);
      } elsif ($action eq "c,r_modis") {
        @theAct = ("clean_modis remake_modis");
      } elsif ($action eq "c,u_modis") {
        @theAct = ("clean_modis update_modis");
      } else {
        @theAct = ($action);
        print "theAct: @theAct\n";
      }
      print "newMoDIS: $newMoDIS\n";
      if ($newMoDIS == 1) {
        # make sure set $mbis_target_build_with_Modis should be after localq
        $mbis_target_build_with_Modis = 1;
        if ($action =~ /^c,r(_modis|_uesim)?$/) {
          push(@theAct, "clean_modis remake_modis");
        } elsif ($action =~ /^c,u(_modis|_uesim)?$/) {
          push(@theAct, "clean_modis update_modis");
        } else {
          my $action2 = $action;
          $action2 =~ s/_(modis|uesim)$//ig;
          push(@theAct, $action2 . "_modis");
        }
      }
      print "newUESim: $newUESim\n";
      if ($newUESim == 1) {
        $mbis_target_build_with_Modis = 1;
        if ($action =~ /^c,r(_modis|_uesim)?$/) {
          push(@theAct, "clean_uesim remake_uesim");
        } elsif ($action =~ /^c,u(_modis|_uesim)?$/) {
          push(@theAct, "clean_uesim update_uesim");
        } else {
          my $action2 = $action;
          $action2 =~ s/_(modis|uesim)$//ig;
          push(@theAct, $action2 . "_uesim");
        }
      }
    }

    if ($exec_xgc_result==0)
    {
      print F "XGC=TRUE \n";
      if ((lc($action) eq "bootloader") || (lc($action) eq "custpack"))
      {
        print F "XGC_AND_NOT_BOOTLOADER=FALSE \n";
      } else {
        my $b = `tasklist`;
        if($b=~/buildsystem/i)
        {
          print F "XGC_AND_NOT_BOOTLOADER=FALSE \n";
          $mbis_incredibuild=2;
          print "MoDIS IncrediBuild is disabled due to busy.\n" if (($newMoDIS == 1) || ($newUESim == 1) || ($action =~ /MoDIS|UESim/i));
        }
        else
        {
          print F "XGC_AND_NOT_BOOTLOADER=TRUE \n";
          if (($newMoDIS == 1) || ($newUESim == 1) || ($action =~ /MoDIS|UESim/i))
          {
            if (&chk_vc9())
            {
              print F "VC2008_VERSION=EXPRESS\n";
            }
            else
            {
              print F "VC2008_VERSION=PROFESSIONAL\n";
            }
          }
        }
      }
    } else {
      print F "XGC=FALSE \n";
      print F "XGC_AND_NOT_BOOTLOADER=FALSE \n";
      print "exec_xgc_result: $exec_xgc_result\n";
    }

    if (lc($action) eq "bootloader")
    {
      print F "ACTION_IS_BOOTLOADER=TRUE \n";
    } else {
      print F "ACTION_IS_BOOTLOADER=FALSE \n";
    }
    close(F);
    ```
  * `$myMF = "gsm2.mak";`
  * `tools\make.exe  -fmake\gsm2.mak -r -R CUSTOMER=ULTRA2503A_11C PROJECT=gprs ck3rdptylic`
  * `tools\make.exe  -fmake\gsm2.mak -r -R CUSTOMER=ULTRA2503A_11C PROJECT=gprs  ckmake`
  * `tools\make.exe  -fmake\gsm2.mak -r -R CUSTOMER=ULTRA2503A_11C PROJECT=gprs  new`

# make new

Path: `make\Gsm2.mak`

* Gsm2.mak
  * Option.mak
    * USER_SPECIFIC.mak
  * make\ULTRA2503A_11C_gprs.mak
    ```Makefile
    # *************************************************************************
    # Release Setting Section
    # *************************************************************************
    RELEASE_PACKAGE		= REL_CR_MMI_$(strip $(PROJECT))	# REL_CR_MMI_GPRS, REL_CR_MMI_GSM, REL_CR_L4_GPRS, REL_CR_L4_GSM
    ...[省略]
    # *************************************************************************
    # Custom Release Component Configuration
    # *************************************************************************
    include make\$(strip $(RELEASE_PACKAGE)).mak
    ...[省略]
    ```
    * REL_CR_MMI_GPRS.mak
* `new : backup cleanall genlog sysgen cleancodegen asngen codegen codegen_check asnregen resgen bootloader update`
  ```Makefile
  # *************************************************************************
  # New Build
  # *************************************************************************
  ifeq ($(strip $(call Upper,$(LEVEL))),VENDOR)
    ifeq ($(strip $(NEED_BUILD_BOOTLOADER)),TRUE)
      ifeq ($(filter bootloader, $(strip $(CUS_REL_SRC_COMP))),bootloader)
        ifneq ($(filter UMTS HSPA TDD128 TDD128DPA TDD128HSPA,$(strip $(call Upper,$(PROJECT)))),)

  # add for daily build, add "codegen_check" after "code_gen"
  new : backup cleanall genlog cleancodegen asngen umts_gen ss_lcs_gen codegen codegen_check asnregen cleanbin mcddll_update resgen nvram_auto_gen bootloader remake
        else
  new : backup cleanall genlog cleancodegen asngen codegen codegen_check asnregen cleanbin mcddll_update resgen nvram_auto_gen bootloader remake
        endif    
      else
        ifneq ($(filter UMTS HSPA TDD128 TDD128DPA TDD128HSPA,$(strip $(call Upper,$(PROJECT)))),)
  new : backup cleanall genlog cleancodegen asngen umts_gen ss_lcs_gen codegen codegen_check asnregen cleanbin mcddll_update resgen nvram_auto_gen remake
        else
  new : backup cleanall genlog cleancodegen asngen codegen codegen_check asnregen cleanbin mcddll_update resgen nvram_auto_gen remake
        endif    
      endif
    else
      ifneq ($(filter UMTS HSPA TDD128 TDD128DPA TDD128HSPA,$(strip $(call Upper,$(PROJECT)))),)
  new : backup cleanall genlog cleancodegen asngen umts_gen ss_lcs_gen codegen codegen_check asnregen cleanbin mcddll_update resgen nvram_auto_gen remake
      else
  new : backup cleanall genlog cleancodegen asngen codegen codegen_check asnregen cleanbin mcddll_update resgen nvram_auto_gen remake
      endif  
    endif
  else
    ifeq ($(strip $(NEED_BUILD_BOOTLOADER)),TRUE)
      ifneq ($(filter UMTS HSPA TDD128 TDD128DPA TDD128HSPA,$(strip $(call Upper,$(PROJECT)))),)
  new : backup cleanall genlog sysgen cleancodegen asngen umts_gen ss_lcs_gen codegen codegen_check asnregen resgen bootloader update
      else
  $(info "zengjf Makefile info LEVEL" $(LEVEL))
  $(info "zengjf Makefile info NEED_BUILD_BOOTLOADER" $(NEED_BUILD_BOOTLOADER))
  $(info "zengjf Makefile info PROJECT" $(PROJECT))
  new : backup cleanall genlog sysgen cleancodegen asngen codegen codegen_check asnregen resgen bootloader update  
      endif
    else
      ifneq ($(filter UMTS HSPA TDD128 TDD128DPA TDD128HSPA,$(strip $(call Upper,$(PROJECT)))),)
  new : backup cleanall genlog sysgen cleancodegen asngen umts_gen ss_lcs_gen codegen codegen_check asnregen update
      else
  new : backup cleanall genlog sysgen cleancodegen asngen codegen codegen_check asnregen update
      endif
    endif
  endif
  ```
  * `bootloader: gen_bl_verno gencompbld bl_preflow LINK_BL LINK_BL_CHECK BL_POSTBUILD`
    ```Makefile
    # *************************************************************************
    #  BOOTLOADER Targets
    # *************************************************************************
    ifeq ($(strip $(NEED_BUILD_BOOTLOADER)),TRUE)
      ifeq ($(strip $(MODIS_CONFIG)),FALSE)
        ifeq ($(strip $(ACTION)),bootloader)
    bootloader: gen_bl_verno gencompbld bl_preflow LINK_BL BL_POSTBUILD done
        else
    $(info "zengjf Makefile info NEED_BUILD_BOOTLOADER" $(NEED_BUILD_BOOTLOADER))
    $(info "zengjf Makefile info MODIS_CONFIG" $(MODIS_CONFIG))
    $(info "zengjf Makefile info ACTION" $(ACTION))
    bootloader: gen_bl_verno gencompbld bl_preflow LINK_BL LINK_BL_CHECK BL_POSTBUILD
        endif
      else
    bootloader:
      endif
    else
    bootloader:
    endif
    ```
  * `update : backup genlog cleanbin codegen mcddll_update cksysdrv_slim resgen remake`
    ```Makefile
    # *************************************************************************
    #  Update Build
    # *************************************************************************
    #update : genlog cleanbin codegen mcddll_update resgen cksysdrv_slim remake

    ifeq ($(strip $(ACTION)),slim_update)

    ifeq ($(strip $(CUSTOM_RELEASE)),TRUE)
      ifeq ($(strip $(CUSTOM)),MONZA29)
    update : backup genlog codegen remake
      else
        ifneq ($(filter UMTS HSPA TDD128 TDD128DPA TDD128HSPA,$(strip $(call Upper,$(PROJECT)))),)
    update : backup genlog cleanbin umts_gen codegen cksysdrv_slim resgen remake
        else
    update : backup genlog cleanbin codegen cksysdrv_slim resgen remake
        endif
      endif
    else
      ifneq ($(filter UMTS HSPA TDD128 TDD128DPA TDD128HSPA,$(strip $(call Upper,$(PROJECT)))),)
    update : backup genlog cleanbin umts_gen codegen resgen mmi_obj_check cksysdrv_slim remake
      else
    update : backup genlog cleanbin codegen resgen mmi_obj_check cksysdrv_slim remake
      endif
    endif

    else  
    ## update

    ifeq ($(strip $(CUSTOM_RELEASE)),TRUE)
      ifeq ($(strip $(CUSTOM)),MONZA29)
    update : backup genlog codegen remake
      else
        ifneq ($(filter UMTS HSPA TDD128 TDD128DPA TDD128HSPA,$(strip $(call Upper,$(PROJECT)))),)
    update : backup genlog cleanbin umts_gen ss_lcs_gen codegen mcddll_update cksysdrv_slim resgen remake
        else
    $(info "zengjf Makefile info CUSTOM_RELEASE" $(CUSTOM_RELEASE))
    $(info "zengjf Makefile info CUSTOM" $(CUSTOM))
    $(info "zengjf Makefile info PROJECT" $(PROJECT))
    update : backup genlog cleanbin codegen mcddll_update cksysdrv_slim resgen remake
        endif
      endif
    else
      ifneq ($(filter UMTS HSPA TDD128 TDD128DPA TDD128HSPA,$(strip $(call Upper,$(PROJECT)))),)
    update : backup genlog cleanbin umts_gen ss_lcs_gen codegen mcddll_update resgen mmi_obj_check cksysdrv_slim remake
      else
    update : backup genlog cleanbin codegen mcddll_update resgen mmi_obj_check cksysdrv_slim remake
      endif
    endif

    endif
    ```
    * `remake : backup mcp_check genlog cleanbin genverno genoriverno libs $(BIN_FILE) cmmgen cfggen catgen done`
      ```Makefile
      # *************************************************************************
      #  Remake Build
      # *************************************************************************
      ifeq ($(strip $(MODIS_CONFIG)),FALSE)
      ifneq ($(strip $(LINT)),TRUE)
      ifeq ($(strip $(LEVEL)),VENDOR)
        ifneq ($(strip $(FOTA_ENABLE)),NONE)
          ifeq ($(filter fota, $(strip $(CUS_REL_SRC_COMP))),fota)
      remake : backup mcp_check genlog cleanbin genverno genoriverno libs $(FOTA_BIN_FILE) $(BIN_FILE) cmmgen cfggen catgen done
          else
      remake : backup mcp_check genlog cleanbin genverno genoriverno libs $(BIN_FILE) cmmgen cfggen catgen done
          endif
        else
      remake : backup mcp_check genlog cleanbin genverno genoriverno libs $(BIN_FILE) cmmgen cfggen catgen done
        endif
      else
        ifeq ($(strip $(call Upper,$(REMAKE_MODS))),BOOTLOADER)
      remake : backup bootloader done
        else
          ifeq ($(strip $(call Upper,$(REMAKE_MODS))),FOTA)
      remake : backup $(FOTA_BIN_FILE) done
          else
            ifdef FOTA_ENABLE
              ifneq ($(strip $(FOTA_ENABLE)),NONE)
      remake : backup mcp_check genlog cleanbin genverno genoriverno libs $(FOTA_BIN_FILE) $(BIN_FILE) cmmgen cfggen catgen done
              else
      $(info "zengjf Makefile info MODIS_CONFIG" $(MODIS_CONFIG))
      $(info "zengjf Makefile info LINT" $(LINT))
      $(info "zengjf Makefile info LEVEL" $(LEVEL))
      $(info "zengjf Makefile info REMAKE_MODS" $(REMAKE_MODS))
      $(info "zengjf Makefile info FOTA_ENABLE" $(FOTA_ENABLE))
      remake : backup mcp_check genlog cleanbin genverno genoriverno libs $(BIN_FILE) cmmgen cfggen catgen done
              endif
            else
      remake : backup mcp_check genlog cleanbin genverno genoriverno libs $(BIN_FILE) cmmgen cfggen catgen done
            endif
          endif
        endif
      endif
      else
      remake : backup libs copylintlog genlintstatlog done
      endif
      else # MODIS_CONFIG == TRUE
      remake : mcp_check genlog cleanbin genverno genoriverno
      endif #ifeq ($(strip $(MODIS_CONFIG)),FALSE)
      ```
      * `libs : echo_lib_lists cleanlib startbuildlibs xgc_all_libs_2`
        ```Makefile
        # *************************************************************************
        # Library Targets
        # *************************************************************************
        ifeq ($(strip $(MODIS_CONFIG)),FALSE)
        ifneq ($(filter $(MAKECMDGOALS),remake),)
        ifneq ($(strip $(REMAKE_WITH_CGEN)),FALSE)
        libs: cgen
        endif
        endif
        endif

        ifneq ($(strip $(LINT)),TRUE)
        ifneq ($(strip $(XGC_AND_NOT_BOOTLOADER)),TRUE)
        libs: cleanlib startbuildlibs $(COMPLIBLIST)
        else
        libs : echo_lib_lists cleanlib startbuildlibs xgc_all_libs_2
        endif
        else
        libs: $(LINT_COMP_LIST)
        endif
        ```
        * `startbuildlibs:`
          ```Makefile
          echo_lib_lists:
            # mbis time probe
          	@if /I "$(strip $(MBIS_EN))"  EQU "TRUE" (@perl -e "print 'T_S,$@,T,'. time . \"\n\"";>>$(MBIS_BUILD_TIME_TMP))
          	@echo COMPLIBLIST=$(COMPLIBLIST) > make\complib.txt
             # mbis time probe
          	@if /I "$(strip $(MBIS_EN))"  EQU "TRUE" (@perl -e "print 'T_E,$@,T,'. time . \"\n\"";>>$(MBIS_BUILD_TIME_TMP))

          ifeq ($(strip $(MODIS_CONFIG)),FALSE)
            startbuildlibs: gencompbld
          else
            startbuildlibs:
          endif
             # mbis time probe
          	@if /I "$(strip $(MBIS_EN))"  EQU "TRUE" (@perl -e "print 'T_S,$@,T,'. time . \"\n\"";>>$(MBIS_BUILD_TIME_TMP))
          	@echo Start to build $(COMPLIBLIST)
          # Copy plutommi header files to a temp folder to improve compiler performance.

          ifeq ($(strip $(REDUCE_HEADER_DEPTH)),TRUE)
          	@perl -e "print 'hTogether START TIME='";>>$(strip $(TARGDIR))\build.log
          	@perl tools\time.pl -n>>$(strip $(TARGDIR))\build.log

          	@if exist $(COPY_MMI_INCLUDE_FILE) (copy /Y $(COPY_MMI_INCLUDE_FILE) tools\copy_mmi_include_h.bat >NUL)

          ifeq ($(strip $(RUN_HTOGETHER)),TRUE)
          	@if exist $(CUS_MTK_LIB)\tools\copy_mmi_include_h.bat (copy $(CUS_MTK_LIB)\tools\copy_mmi_include_h.bat tools\copy_mmi_include_h.bat  >NUL)
            ifeq ($(strip $(MMI_VERSION)),NEPTUNE_MMI)
              ifeq ($(strip $(RTOS)),NUCLEUS)
          		@copy /Y tools\copy_mmi_include_h_nucleus_neptune.bat tools\copy_mmi_include_h.bat >NUL
              endif
            endif
          endif
          	@echo Copying header files ......
          	@if exist $(strip $(HEADER_TEMP))\*.* del /q /f $(strip $(HEADER_TEMP))\*.*
          	@if exist tools\mmi_include.dep (del /q /f tools\mmi_include.dep)
          	@if not exist $(strip $(HEADER_TEMP)) (md $(strip $(HEADER_TEMP)))
          	-@if exist tools\copy_mmi_include_h.bat (tools\copy_mmi_include_h.bat $(strip $(HEADER_TEMP)) 1>nul)

          	@perl -e "print 'hTogether END TIME='";>>$(strip $(TARGDIR))\build.log
          	@perl tools\time.pl -n>>$(strip $(TARGDIR))\build.log

          endif

             # mbis time probe
          	@if /I "$(strip $(MBIS_EN))"  EQU "TRUE" (@perl -e "print 'T_E,$@,T,'. time . \"\n\"";>>$(MBIS_BUILD_TIME_TMP))
          ```

## Generate Bootloader

Path: `make/Gsm2.mak`

* `bootloader: gen_bl_verno gencompbld bl_preflow LINK_BL LINK_BL_CHECK BL_POSTBUILD`
  * gen_bl_verno
    ```Perl
    # *************************************************************************
    # Generate Bootloader VersionNo
    # *************************************************************************
    gen_bl_verno: make\~customIncDef.tmp
    #$(eval $(call CheckNeedDependTarget,gen_bl_verno,postgen_dep))
    #$(strip $(RULESDIR_TARGET))\postgen_dep\gen_bl_verno.det:
       # mbis time probe
    	@if /I "$(strip $(MBIS_EN))"  EQU "TRUE" (@perl -e "print 'T_S,$@,T,'. time . \"\n\"";>>$(MBIS_BUILD_TIME_TMP))
    	@perl -e "print 'gen_bl_verno START TIME='";>>$(strip $(TARGDIR))\build.log
    	@perl tools\time.pl -n>>$(strip $(TARGDIR))\build.log

    	@echo Generate BOOTLOADER CMM file ...
    #	@echo [Dependency] tools\CMMAutoGen.pl >$(basename $@).log
        # echo .\BOOTLOADER_ULTRA2503A_11C_MT6261_nocode.cmm
        # .\BOOTLOADER_ULTRA2503A_11C_MT6261_nocode.cmm
        # echo .\build\ULTRA2503A_11C\ULTRA2503A_11C_BOOTLOADER_V005_MT6261_MAUI_11C_W13_52_SP3_V3.elf
        # .\build\ULTRA2503A_11C\ULTRA2503A_11C_BOOTLOADER_V005_MT6261_MAUI_11C_W13_52_SP3_V3.elf
        # echo .\EXT_BOOTLOADER_ULTRA2503A_11C_MT6261_nocode.cmm
        # .\EXT_BOOTLOADER_ULTRA2503A_11C_MT6261_nocode.cmm
        # echo .\build\ULTRA2503A_11C\ULTRA2503A_11C_BOOTLOADER_V005_MT6261_MAUI_11C_W13_52_SP3_V3_ext.elf
        # .\build\ULTRA2503A_11C)\ULTRA2503A_11C_BOOTLOADER_V005_MT6261_MAUI_11C_W13_52_SP3_V3_ext.elf
        #
        # build\ULTRA2503A_11C\log\cmmgen_blnocode.log
        #     ACTION: 3,
        #     CMMFILE: .\EXT_BOOTLOADER_ULTRA2503A_11C_MT6261_nocode.cmm,
        #     CMMDIR: .
        #     ELFFILE: .\build\ULTRA2503A_11C\ULTRA2503A_11C_BOOTLOADER_V005_MT6261_MAUI_11C_W13_52_SP3_V3_ext.elf,
        #     MAKEFILE: make\ULTRA2503A_11C_gprs.mak
        #     MAUI_BIN: ULTRA2503A_11C_PCB01_gprs_MT6261_S00.MAUI_11C_W13_52_SP3_V3.bin,
        #     LISFILE: ~lis_temp
        #     CC_CMD: C:\Progra~1\ARM\RVCT\Programs\3.1\569\win_32-pentium\armcc.exe --thumb      ,
        #     VIA_CMD: --via,
        #     OPTION_TMP: make\~customIncDef.tmp
        #     BIN_PATH: .\build\ULTRA2503A_11C\ULTRA2503A_11C_PCB01_gprs_MT6261_S00.MAUI_11C_W13_52_SP3_V3.bin
        echo $(FIXPATH)\BOOTLOADER_$(strip $(CUSTOMER))_$(strip $(PLATFORM))_nocode.cmm
        echo $(TARGDIR)\$(BTLD_PREFIX).elf
        echo $(FIXPATH)\EXT_BOOTLOADER_$(strip $(CUSTOMER))_$(strip $(PLATFORM))_nocode.cmm
        echo $(TARGDIR)\$(BTLD_EXT_PREFIX).elf
    	@if exist tools\CMMAutoGen.pl  \
    	((perl tools\CMMAutoGen.pl 2 $(FIXPATH)\BOOTLOADER_$(strip $(CUSTOMER))_$(strip $(PLATFORM))_nocode.cmm $(strip $(TARGDIR))\$(BTLD_PREFIX).elf $(strip $(THE_MF)) $(strip $(BIN_FILE)) ~lis_temp "$(CC)" "$(VIA)" make\~customIncDef.tmp $(strip $(INSIDE_MTK)) > $(strip $(COMPLOGDIR))\cmmgen_blnocode.log) & \
    		(if ERRORLEVEL 1 echo Error: generate BOOTLOADER CMM file Failed. Please check $(strip $(COMPLOGDIR))\cmmgen_blnocode.log & exit 1) & \
    		(perl tools\CMMAutoGen.pl 3 $(FIXPATH)\EXT_BOOTLOADER_$(strip $(CUSTOMER))_$(strip $(PLATFORM))_nocode.cmm $(strip $(TARGDIR))\$(BTLD_EXT_PREFIX).elf $(strip $(THE_MF)) $(strip $(BIN_FILE)) ~lis_temp "$(CC)" "$(VIA)" make\~customIncDef.tmp $(strip $(INSIDE_MTK)) > $(strip $(COMPLOGDIR))\cmmgen_extblnocode.log) & \
    		(if ERRORLEVEL 1 echo Error: generate EXT_BOOTLOADER CMM file Failed. Please check $(strip $(COMPLOGDIR))\cmmgen_extblnocode.log & exit 1))

    	@echo Generate BOOTLOADER version number ...
    	@if not exist $(strip $(BTLDVERNODIR)) exit 0

    	@if exist $(strip $(BTLDVERNODIR))\bl_verno.c (del $(strip $(BTLDVERNODIR))\bl_verno.c)

    	@echo #include "kal_release.h" > $(strip $(BTLDVERNODIR))\bl_verno.c
    	@echo const kal_uint32 CHECKSUM_SEED = $(strip $(BTLD_CHECKSUM_SEED)); >> $(strip $(BTLDVERNODIR))\bl_verno.c
    	@echo const kal_int8 BootLDVerno[5] = "$(strip $(BTLD_VERNO))"; >> $(strip $(BTLDVERNODIR))\bl_verno.c

    ifeq ($(strip $(XGC_AND_NOT_BOOTLOADER)),TRUE)
    	@echo COMPLIBLIST=$(BL_COMPLIBLIST) > make\complib.txt
    endif

    	@perl -e "print 'gen_bl_verno END TIME='";>>$(strip $(TARGDIR))\build.log
    	@perl tools\time.pl -n>>$(strip $(TARGDIR))\build.log
       # mbis time probe
    	@if /I "$(strip $(MBIS_EN))"  EQU "TRUE" (@perl -e "print 'T_E,$@,T,'. time . \"\n\"";>>$(MBIS_BUILD_TIME_TMP))
    ```
  * Bootloader Compile
    ```Makefile
    $(info ---------------MODIS_CONFIG $(MODIS_CONFIG))
    $(info LINT $(LINT))
    $(info XGC_AND_NOT_BOOTLOADER $(XGC_AND_NOT_BOOTLOADER))
    $(info AUTO_CHECK_DEPEND $(AUTO_CHECK_DEPEND))
    $(info RULESDIR_TARGET $(RULESDIR_TARGET))
    $(info NEED_CHECK_DEPEND_LIST $(NEED_CHECK_DEPEND_LIST))
    ifneq ($(strip $(MODIS_CONFIG)),TRUE)
    ifneq ($(strip $(LINT)),TRUE)
    ifneq ($(strip $(XGC_AND_NOT_BOOTLOADER)),TRUE)
    ifeq ($(strip $(AUTO_CHECK_DEPEND)),TRUE)
    # in r\comp_dep\$module.det, $module.lib will depend on all source/header files used by all objects in that module
    # so if the source/header are not changed, no need to call comp.mak and waste time to archive again
    -include $(wildcard $(subst \,/,$(strip $(RULESDIR_TARGET)))/comp_dep/*.det)
    %.lib: $(NEED_CHECK_DEPEND_LIST) $(NEED_CHECK_COMP_LIST)
    $(info '.lib: $(NEED_CHECK_DEPEND_LIST) $(NEED_CHECK_COMP_LIST)')
    endif
    $(info '.lib:')
    %.lib:
    else
    $(info 'xgc_all_libs xgc_all_libs_2')
    xgc_all_libs xgc_all_libs_2:
    endif
    else
    $(info '.ltp: gencompbld')
    %.ltp: gencompbld
    endif
       # mbis time probe
    ifneq ($(strip $(XGC)),TRUE)
    	@if /I "$(strip $(MBIS_EN))" EQU "TRUE" (@perl -e "print 'T_S,$(@F),L,'. time . \"\n\"";>>$(MBIS_BUILD_TIME_TMP))
    	@if /I "$(strip $(MBIS_EN_OBJ_LOG))" EQU "TRUE" \
    		(if not exist $(TARGDIR)\log\mbis\$* (md $(TARGDIR)\log\mbis\$*) &\
    		if exist $(TARGDIR)\log\mbis\$*\*.mbis (del /q /f $(TARGDIR)\log\mbis\$*\*.mbis))
    else
    	@if /I "$(strip $(MBIS_EN))" EQU "TRUE" (@perl -e "print 'T_S,$@,L,'. time . \"\n\"";>>$(MBIS_BUILD_TIME_TMP))
    endif

    	@if exist $(strip $(COMPLIBDIR))\$*.lib (del /q $(strip $(COMPLIBDIR))\$*.lib)
    	@if not exist $(strip $(COMPLIBDIR)) (md $(COMPLIBDIR))

    	$(info "------------------------XGC_AND_NOT_BOOTLOADER:" $(XGC_AND_NOT_BOOTLOADER))
    	$(info "FOTA_LOG:" $(FOTA_LOG))
    	$(info "BOOTLOADER_LOG:" $(BOOTLOADER_LOG))
    	$(info "BOOTLOADER_EXT_LOG:" $(BOOTLOADER_EXT_LOG))
    	$(info "LOG:" $(LOG))
    ifneq ($(strip $(XGC_AND_NOT_BOOTLOADER)),TRUE)
    	@if $*==fota \
    		(@echo Beginning $* component build process ... > $(FOTA_LOG)) \
    	else \
    		@if $*==bootloader \
    			(@echo Beginning $* component build process ... > $(BOOTLOADER_LOG)) \
    		else \
    			@if $*==bootloader_ext \
    				(@echo Beginning $* component build process ... > $(BOOTLOADER_EXT_LOG)) \
    			else \
    				(@echo Beginning $* component build process ... >> $(LOG))

    	@perl tools\time.pl
    	@echo zengjf $*
    	@echo Building $*
    	@echo                     LOG: $(strip $(COMPLOGDIR))\$*.log

    	$(info "----------------OBJSDIR:" $(OBJSDIR))
    	$(info "ACTION:" $(ACTION))
    	@if not exist $(strip $(OBJSDIR))\$* (md $(strip $(OBJSDIR))\$*)
    	@if $(ACTION)==new if exist $(strip $(RULESDIR))\$*_dep\*.det del /f /q $(strip $(RULESDIR))\$*_dep\*.det
    	@if $(ACTION)==bm_new if exist $(strip $(RULESDIR))\$*_dep\*.det del /f /q $(strip $(RULESDIR))\$*_dep\*.det
    	@if not $(ACTION)==remake if not exist $(strip $(RULESDIR))\$*_dep md $(strip $(RULESDIR))\$*_dep
      ifneq ($(strip $(AUTO_CHECK_DEPEND)),TRUE)
    	@if $(ACTION)==new if exist $(strip $(RULESDIR))\$*.dep del /q /f $(strip $(RULESDIR))\$*.dep
    	@if $(ACTION)==bm_new if exist $(strip $(RULESDIR))\$*.dep del /q /f $(strip $(RULESDIR))\$*.dep
      else
        # extract all *.det from $module.dep, otherwise, the det of unchanged files will lose
    	@if not $(ACTION)==remake if exist $(strip $(RULESDIR))\$*.dep (perl tools\pack_dep_gen.pl --extract $(strip $(RULESDIR))\$*.dep NULL $(strip $(RULESDIR))\$*_dep NULL)
      endif
    	@if exist *.via del /f /q *.via
    	@if exist *.d del /f /q *.d
    endif
       # -----------------------------
       # invoke component build script
       # -----------------------------
    # Start to extract obj
    	$(info "---------------LINT:" $(LINT))
    	$(info "LINT:" $(LINT))
    	$(info "XGC:" $(XGC))
    	$(info "RVCT_PARTIAL_LINK:" $(RVCT_PARTIAL_LINK))
    	$(info "OBJSDIR:" $(OBJSDIR))
    ifneq ($(strip $(LINT)),TRUE)
      ifneq ($(strip $(XGC)),TRUE)
        ifneq ($(strip $(RVCT_PARTIAL_LINK)),TRUE)
    			@if exist $(strip $(OBJSDIR))\$*\$*.lib_bak if not exist $(subst /,\,$(OBJSDIR))\$*\*.obj  perl tools\extract_obj_from_lib.pl  $(subst /,\,$(OBJSDIR))\$*\$*.lib_bak  $(subst /,\,$(OBJSDIR))\$* $(subst /,\,$(LIB)) $(TARGDIR)\module\$*\$*.lis
        endif
      endif
    endif
    # End of extract obj

    	$(info "------------------build log:" $(strip $(TARGDIR))\build.log)
    	@perl -e "print '$* START TIME='";>>$(strip $(TARGDIR))\build.log
    	@perl tools\time.pl -n>>$(strip $(TARGDIR))\build.log
    	$(info "LINT" $(LINT))
    	$(info "XGC_AND_NOT_BOOTLOADER" $(XGC_AND_NOT_BOOTLOADER))
    	$(info "BM_NEW" $(BM_NEW))
    	$(info "COMPLOGDIR" $(COMPLOGDIR))
    ifneq ($(strip $(LINT)),TRUE)
    #@echo tools\make.exe -fmake\comp.mak -r -R COMPONENT=$* ... $(strip $(COMPLOGDIR))\$*.log
    ifneq ($(strip $(XGC_AND_NOT_BOOTLOADER)),TRUE)
    	$(info tools\make.exe -fmake\comp.mak -k -r -R $(strip $(CMD_ARGU)) --no-print-directory COMPONENT=$* setup_env > $(strip $(COMPLOGDIR))\$*_setEnv.log 2>&1)
    	tools\make.exe -fmake\comp.mak -k -r -R $(strip $(CMD_ARGU)) --no-print-directory COMPONENT=$* setup_env > $(strip $(COMPLOGDIR))\$*_setEnv.log 2>&1

      ifeq ($(strip $(call Upper,$(BM_NEW))),TRUE)
    			@if not exist $(strip $(COMPLOGDIR))\$* md $(strip $(COMPLOGDIR))\$*
    			(tools\make.exe -fmake\comp.mak -k -r -R $(strip $(CMD_ARGU)) COMPONENT=$* update_lib > $(strip $(COMPLOGDIR))\$*.log 2>&1) & \
    			(if ERRORLEVEL 1 \
    			  (perl tools\get_log.pl $(strip $(COMPLOGDIR))\$*.log $(strip $(COMPLOGDIR))\$* tools\copy_mmi_include_h.bat) & \
    			  (rd /S /Q $(strip $(COMPLOGDIR))\$*) & \
    			  (exit 1) \
    			else \
    			  (perl tools\get_log.pl $(strip $(COMPLOGDIR))\$*.log $(strip $(COMPLOGDIR))\$* tools\copy_mmi_include_h.bat) & \
    			  (rd /S /Q $(strip $(COMPLOGDIR))\$*) \
    			)
      else
    			$(info "BM_NEW FALSE COMPLOGDIR" $(COMPLOGDIR))
    			@if not exist $(strip $(COMPLOGDIR))\$* md $(strip $(COMPLOGDIR))\$*
    			$(info "BM_NEW FALSE COMPLOGDIR" $(COMPLOGDIR))
    			(tools\make.exe -fmake\comp.mak -r -R $(strip $(CMD_ARGU)) COMPONENT=$* update_lib > $(strip $(COMPLOGDIR))\$*.log 2>&1) & \
    			(if ERRORLEVEL 1 \
    			  (perl tools\get_log.pl $(strip $(COMPLOGDIR))\$*.log $(strip $(COMPLOGDIR))\$* tools\copy_mmi_include_h.bat) & \
    			  (rd /S /Q $(strip $(COMPLOGDIR))\$*) & \
    			  (exit 1) \
    			else \
    			  (perl tools\get_log.pl $(strip $(COMPLOGDIR))\$*.log $(strip $(COMPLOGDIR))\$* tools\copy_mmi_include_h.bat) & \
    			  (rd /S /Q $(strip $(COMPLOGDIR))\$*) \
    		)
      endif

    else
    #XGC

    	$(info "BM_NEW" $(BM_NEW))
      ifeq ($(strip $(call Upper,$(BM_NEW))),TRUE)
    			XGConsole /command="tools\make.exe  -fmake\intermed.mak -k -r -R $(strip $(CMD_ARGU))  " /NOLOGO /profile="tools\XGConsole.xml"
      else
    			XGConsole /command="tools\make.exe  -fmake\intermed.mak -r -R $(strip $(CMD_ARGU))   " /NOLOGO /profile="tools\XGConsole.xml"
      endif
    endif

    	$(info "XGC_AND_NOT_BOOTLOADER" $(XGC_AND_NOT_BOOTLOADER))
    ifneq ($(strip $(XGC_AND_NOT_BOOTLOADER)),TRUE)
    	@if $*==fota \
    		(@type $(strip $(COMPLOGDIR))\$*.log >> $(FOTA_LOG)) \
    	else \
    		@if $*==bootloader \
    			(@type $(strip $(COMPLOGDIR))\$*.log >> $(BOOTLOADER_LOG)) \
    		else \
    			@if $*==bootloader_ext \
    				(@type $(strip $(COMPLOGDIR))\$*.log >> $(BOOTLOADER_EXT_LOG)) \
    			else \
    				(@type $(strip $(COMPLOGDIR))\$*.log >> $(LOG))

    	@perl .\tools\chk_lib_err_warn.pl $(strip $(COMPLOGDIR))\$*.log
    endif

    else
    #LINT
    	@if not exist $(COMPLINTLOGDIR)	(md $(COMPLINTLOGDIR))
    	@if exist $(strip $(COMPLINTLOGDIR))\targetl.end del /F /Q $(strip $(COMPLINTLOGDIR))\targetl.end
    	@if exist $(strip $(COMPLINTLOGDIR))\$*_build.log del /F /Q $(strip $(COMPLINTLOGDIR))\$*_build.log
    	@if exist $(strip $(COMPLINTLOGDIR))\$*.log del /F /Q $(strip $(COMPLINTLOGDIR))\$*.log
    	tools\make.exe -fmake\comp.mak -k -r -R $(strip $(CMD_ARGU)) COMPONENT=$* update_lib> $(strip $(COMPLINTLOGDIR))\$*_build.log 2>&1
    endif
    	perl -e "print '$* END TIME='";>>$(strip $(TARGDIR))\build.log
    	perl tools\time.pl -n>>$(strip $(TARGDIR))\build.log
       # mbis time probe
    ifneq ($(strip $(XGC)),TRUE)
    	@if /I "$(strip $(MBIS_EN_OBJ_LOG))"  EQU "TRUE" (if exist $(TARGDIR)\log\mbis\$*\*.mbis (perl tools\mbis.pl -o $(TARGDIR)\log\mbis\$*))
    	@if exist $(TARGDIR)\log\mbis\$*\*.mbis ((del /q /f $(TARGDIR)\log\mbis\$*\*.mbis) & (rmdir /S /Q $(TARGDIR)\log\mbis\$*))
    	@if /I "$(strip $(MBIS_EN))"  EQU "TRUE" (@perl -e "print 'T_E,$(@F),L,'. time . \"\n\"";>>$(MBIS_BUILD_TIME_TMP))
    else
    	@if /I "$(strip $(MBIS_EN))" EQU "TRUE" (@perl -e "print 'T_E,$@,L,'. time . \"\n\"";>>$(MBIS_BUILD_TIME_TMP))
    endif
    endif #ifneq ($(strip $(MODIS_CONFIG)),TRUE)
    ```
  * `tools\make.exe -fmake\comp.mak -k -r -R -j4 --no-print-directory COMPONENT=bootloader setup_env > .\build\ULTRA2503A_11C\log\bootloader_setEnv.log 2>&1`
  * `tools\make.exe -fmake\comp.mak -r -R -j4 COMPONENT=bootloader update_lib > .\build\ULTRA2503A_11C\log\bootloader.log 2>&1`
  * Make Help
    ```Shell
    Usage: make [options] [target] ...
    Options:
      -b, -m                      Ignored for compatibility.
      -B, --always-make           Unconditionally make all targets.
      -C DIRECTORY, --directory=DIRECTORY
                                  Change to DIRECTORY before doing anything.
      -d                          Print lots of debugging information.
      --debug[=FLAGS]             Print various types of debugging information.
      -e, --environment-overrides
                                  Environment variables override makefiles.
      -f FILE, --file=FILE, --makefile=FILE
                                  Read FILE as a makefile.
      -h, --help                  Print this message and exit.
      -i, --ignore-errors         Ignore errors from commands.
      -I DIRECTORY, --include-dir=DIRECTORY
                                  Search DIRECTORY for included makefiles.
      -j [N], --jobs[=N]          Allow N jobs at once; infinite jobs with no arg.
      -k, --keep-going            Keep going when some targets can't be made.
      -l [N], --load-average[=N], --max-load[=N]
                                  Don't start multiple jobs unless load is below N.
      -L, --check-symlink-times   Use the latest mtime between symlinks and target.
      -n, --just-print, --dry-run, --recon
                                  Don't actually run any commands; just print them.
      -o FILE, --old-file=FILE, --assume-old=FILE
                                  Consider FILE to be very old and don't remake it.
      -p, --print-data-base       Print make's internal database.
      -q, --question              Run no commands; exit status says if up to date.
      -r, --no-builtin-rules      Disable the built-in implicit rules.
      -R, --no-builtin-variables  Disable the built-in variable settings.
      -s, --silent, --quiet       Don't echo commands.
      -S, --no-keep-going, --stop
                                  Turns off -k.
      -t, --touch                 Touch targets instead of remaking them.
      -v, --version               Print the version number of make and exit.
      -w, --print-directory       Print the current directory.
      --no-print-directory        Turn off -w, even if it was turned on implicitly.
      -W FILE, --what-if=FILE, --new-file=FILE, --assume-new=FILE
                                  Consider FILE to be infinitely new.
      --warn-undefined-variables  Warn when an undefined variable is referenced.

    This program built for i386-pc-mingw32
    Report bugs to <bug-make@gnu.org>
    ```
  * Bootloader Makefile Load
    ```Makefile
    ...[省略]
    ifdef $($(COMPONENT))
      MODULE_MAKEFILE := make\$(strip $($(COMPONENT)))\$(strip $(COMPONENT))\$(strip $(COMPONENT)).mak
    else
      MODULE_MAKEFILE := make\$(strip $(COMPONENT))\$(strip $(COMPONENT)).mak
    endif
    include $(MODULE_MAKEFILE)
    ...[省略]
    ```
  * setup_env
    ```Makefile
    setup_env:
    ifneq ($(strip $(MODIS_CONFIG)),TRUE)
      ifneq ($(strip $(GEN_MODULE_INFO)),TRUE)
    	-@if not exist $(TARGDIR)\via md $(TARGDIR)\via
    	@tools\strcmpex.exe abc abc e $(TARGDIR)\via\$(strip $(COMPONENT)).via $(CINTWORK) $(CDEFS)
    	@tools\strcmpex.exe abc abc e $(TARGDIR)\via\$(strip $(COMPONENT))_inc.via $(CINCDIRS)
    	@tools\warp.exe $(TARGDIR)\via\$(strip $(COMPONENT)).via
    	@tools\warp.exe $(TARGDIR)\via\$(strip $(COMPONENT))_inc.via
    	-@if not exist $(TARGDIR)\log\$(strip $(COMPONENT)) md $(TARGDIR)\log\$(strip $(COMPONENT))
    	-@if not exist $(TARGDIR)\dep\$(strip $(COMPONENT)) md $(TARGDIR)\dep\$(strip $(COMPONENT))
      else
    	@echo Generating $(COMPONENT) information is done.
      endif
    else
    	@echo $(COMPONENT) MoDIS module setup is done.
    endif
    ```
  * update_lib
    ```Makefile
    # *************************************************************************
    # Library Targets
    # *************************************************************************
    update_lib: $(TARGLIB)
    	@if exist $(RULESDIR)\$(strip $(COMPONENT))_dep rd /s /q $(RULESDIR)\$(strip $(COMPONENT))_dep

    ifeq ($(strip $(RVCT_MULTI_FILE)),NONE)

    $(TARGLIB) :

       # If library for customer release exists.
       # Copy and update it or create a new one
       # mbis time probe
    	@if /I "$(strip $(MBIS_EN_OBJ_LOG))"  EQU "TRUE" (@perl -e "print 'T_S,$@,L,'. time . \"\n\"";>>$(TARGDIR)\log\mbis\$(strip $(COMPONENT))\$(*F)".mbis")
    	@if exist $(OBJ_ARCHIVE) \
    		(del /f /q $(OBJ_ARCHIVE))
    	@if exist $(OBJ_ARCHIVE_SORT) \
    		(del /f /q $(OBJ_ARCHIVE_SORT))

    ifneq ($(words $(CFLAGS)),0)
    	@echo CFLAGS = $(strip $(CFLAGS))
    endif
    ifneq ($(words $(CPLUSFLAGS)),0)
    	@echo CPLUSFLAGS = $(strip $(CPLUSFLAGS))
    endif
    ifneq ($(words $(AFLAGS)),0)
    	@echo AFLAGS = $(strip $(AFLAGS))
    endif
    ifneq ($(words $(ADEFS)),0)
    	@echo ADEFS = $(strip $(ADEFS))
    endif

    	@for %%i in ($(COMPOBJS_DIR)/*.obj) do \
    		echo $(COMPOBJS_DIR)/%%i>>$(OBJ_ARCHIVE)
    	@perl .\tools\sortobj.pl $(OBJ_ARCHIVE) $(OBJ_ARCHIVE_SORT)

    ifneq ($(filter $(PARTIAL_TRACE_LIB),$(COMPONENT)),)
    	@if exist $(FIXPATH)\$(CUS_MTK_LIB_TRACE)\$(strip $(COMPONENT)).lib \
    		(copy /z $(FIXPATH)\$(CUS_MTK_LIB_TRACE)\$(strip $(COMPONENT)).lib $(subst /,\,$(TARGLIB)))
    else
    	@if exist $(FIXPATH)\$(CUS_MTK_LIB)\$(strip $(COMPONENT)).lib \
    		(copy /z $(FIXPATH)\$(CUS_MTK_LIB)\$(strip $(COMPONENT)).lib $(subst /,\,$(TARGLIB)))
    endif

    	$(strip $(LIB)) -create $(TARGLIB) $(VIA) $(OBJ_ARCHIVE_SORT)

    	@echo $(TARGLIB) is updated

    	@if exist $(OBJ_ARCHIVE) \
    		(del /f /q $(OBJ_ARCHIVE))
    	@if exist $(OBJ_ARCHIVE_SORT) \
    		(del /f /q $(OBJ_ARCHIVE_SORT))

    ifeq ($(strip $(AUTO_CHECK_DEPEND)),TRUE)
      ifneq ($(ACTION),remake)
        # delete $module.dep, otherwise there will be duplicated info appended, becasue *.det are already extracted from $module.dep
    	@if exist $(RULESDIR)\$(strip $(COMPONENT)).dep del /q $(RULESDIR)\$(strip $(COMPONENT)).dep
      endif
    endif
    	@if not $(ACTION)==remake if exist $(RULESDIR)\$(strip $(COMPONENT)).dep if exist $(RULESDIR)\$(strip $(COMPONENT))_dep\*.det type $(RULESDIR)\$(strip $(COMPONENT))_dep\*.det >> $(RULESDIR)\$(strip $(COMPONENT)).dep
    	@if not $(ACTION)==remake if not exist $(RULESDIR)\$(strip $(COMPONENT)).dep if exist $(RULESDIR)\$(strip $(COMPONENT))_dep\*.det type $(RULESDIR)\$(strip $(COMPONENT))_dep\*.det > $(RULESDIR)\$(strip $(COMPONENT)).dep
    ifneq ($(ACTION),remake)
      # generate r\comp_dep\$module.det to be included by Gsm2.mak, in order to check $module.lib with all source/header files in that module
    	@if exist $(RULESDIR)\$(strip $(COMPONENT)).dep (perl tools\pack_dep_gen.pl $(RULESDIR)\comp_dep\$(strip $(COMPONENT)).det $(strip $(COMPONENT)).lib $(RULESDIR)\$(strip $(COMPONENT))_dep \w+\.det) else (if exist $(RULESDIR)\comp_dep\$(strip $(COMPONENT)).det del $(RULESDIR)\comp_dep\$(strip $(COMPONENT)).det)
    endif
    	@if not $(ACTION)==remake if exist $(RULESDIR)\$(strip $(COMPONENT))_dep\*.det del /f /q $(RULESDIR)\$(strip $(COMPONENT))_dep\*.det
    	@if exist $(RULESDIR)\$(strip $(COMPONENT))_dep rd /s /q $(RULESDIR)\$(strip $(COMPONENT))_dep
    ifeq ($(findstring j2me,$(strip $(COMPONENT))),j2me)
    	@if not $(ACTION)==remake if exist $(RULESDIR)\$(strip $(COMPONENT)).dep copy /y $(RULESDIR)\$(strip $(COMPONENT)).dep make\$(strip $(COMPONENT))
    endif
    ifeq ($(strip $(COMPONENT)),jblendia)
    	@if not $(ACTION)==remake if exist $(RULESDIR)\$(strip $(COMPONENT)).dep copy /y $(RULESDIR)\$(strip $(COMPONENT)).dep make\$(strip $(COMPONENT))
    endif
    ifeq ($(strip $(COMPONENT)),ijet_adp)
    	@if not $(ACTION)==remake if exist $(RULESDIR)\$(strip $(COMPONENT)).dep copy /y $(RULESDIR)\$(strip $(COMPONENT)).dep make\$(strip $(COMPONENT))
    endif
    ifeq ($(strip $(COMPONENT)),nemo_adp)
    	@if not $(ACTION)==remake if exist $(RULESDIR)\$(strip $(COMPONENT)).dep copy /y $(RULESDIR)\$(strip $(COMPONENT)).dep make\$(strip $(COMPONENT))
    endif
       # mbis time probe
    	@if /I "$(strip $(MBIS_EN_OBJ_LOG))"  EQU "TRUE" (@perl -e "print 'T_E,$@,L,'. time . \"\n\"";>>$(TARGDIR)\log\mbis\$(strip $(COMPONENT))\$(*F)".mbis")
    endif

    ifeq ($(strip $(RVCT_MULTI_FILE)),MULTI_FILE)
    ifeq ($(strip $(COMPILER)),RVCT)

    $(TARGLIB):
       # mbis time probe
    	@if /I "$(strip $(MBIS_EN_OBJ_LOG))"  EQU "TRUE" (@perl -e "print 'T_S,$@,L,'. time . \"\n\"";>>$(TARGDIR)\log\mbis\$(strip $(COMPONENT))\$(*F)".mbis")
    	@echo Compiling $< ...
    	@tools\strcmpex.exe $(ACTION) remake e $(*F).via  $(CINTWORK) -c $(CFLAGS) $(CDEFS) $(CINCDIRS) --multifile -o $(COMPOBJS_DIR)/$(strip $(COMPONENT)).obj $(CPPSRCS) $(CSRCS) $<
    	@tools\strcmpex.exe $(ACTION) remake n $(*F).via  $(CINTWORK) -c $(CFLAGS) $(CDEFS) $(CINCDIRS) --multifile -o $(COMPOBJS_DIR)/$(strip $(COMPONENT)).obj $(CPPSRCS) $(CSRCS) $<
    	@if exist $(*F).via tools\warp.exe $(*F).via
    	@if exist $(*F).via $(CMPLR) -via $(*F).via

    	@if exist $(OBJ_ARCHIVE) \
    		(del /f /q $(OBJ_ARCHIVE))
    	@if exist $(OBJ_ARCHIVE_SORT) \
    		(del /f /q $(OBJ_ARCHIVE_SORT))

    ifneq ($(words $(CFLAGS)),0)
    	@echo CFLAGS = $(strip $(CFLAGS))
    endif
    ifneq ($(words $(CPLUSFLAGS)),0)
    	@echo CPLUSFLAGS = $(strip $(CPLUSFLAGS))
    endif
    ifneq ($(words $(AFLAGS)),0)
    	@echo AFLAGS = $(strip $(AFLAGS))
    endif
    ifneq ($(words $(ADEFS)),0)
    	@echo ADEFS = $(strip $(ADEFS))
    endif

    	@for %%i in ($(COMPOBJS_DIR)/*.obj) do \
    		echo $(COMPOBJS_DIR)/%%i>>$(OBJ_ARCHIVE)
    	@perl .\tools\sortobj.pl $(OBJ_ARCHIVE) $(OBJ_ARCHIVE_SORT)

    ifneq ($(filter $(PARTIAL_TRACE_LIB),$(COMPONENT)),)
    	@if exist $(FIXPATH)\$(CUS_MTK_LIB_TRACE)\$(strip $(COMPONENT)).lib \
    		(copy /z $(FIXPATH)\$(CUS_MTK_LIB_TRACE)\$(strip $(COMPONENT)).lib $(subst /,\,$(TARGLIB)))
    else
    	@if exist $(FIXPATH)\$(CUS_MTK_LIB)\$(strip $(COMPONENT)).lib \
    		(copy /z $(FIXPATH)\$(CUS_MTK_LIB)\$(strip $(COMPONENT)).lib $(subst /,\,$(TARGLIB)))
    endif

    	$(strip $(LIB)) -create $(TARGLIB) $(VIA) $(OBJ_ARCHIVE_SORT)

    	@echo $(TARGLIB) is updated

    	@if not $(ACTION)==remake if exist $(RULESDIR)\$(strip $(COMPONENT)).dep if exist $(RULESDIR)\$(strip $(COMPONENT))_dep\*.det type $(RULESDIR)\$(strip $(COMPONENT))_dep\*.det >> $(RULESDIR)\$(strip $(COMPONENT)).dep
    	@if not $(ACTION)==remake if not exist $(RULESDIR)\$(strip $(COMPONENT)).dep if exist $(RULESDIR)\$(strip $(COMPONENT))_dep\*.det type $(RULESDIR)\$(strip $(COMPONENT))_dep\*.det > $(RULESDIR)\$(strip $(COMPONENT)).dep
    	@if not $(ACTION)==remake if exist $(RULESDIR)\$(strip $(COMPONENT))_dep\*.det del /f /q $(RULESDIR)\$(strip $(COMPONENT))_dep\*.det
    	@if exist $(RULESDIR)\$(strip $(COMPONENT))_dep rd /s /q $(RULESDIR)\$(strip $(COMPONENT))_dep
    ifeq ($(findstring j2me,$(strip $(COMPONENT))),j2me)
    	@if not $(ACTION)==remake if exist $(RULESDIR)\$(strip $(COMPONENT)).dep copy /y $(RULESDIR)\$(strip $(COMPONENT)).dep make\$(strip $(COMPONENT))
    endif
    ifeq ($(strip $(COMPONENT)),jblendia)
    	@if not $(ACTION)==remake if exist $(RULESDIR)\$(strip $(COMPONENT)).dep copy /y $(RULESDIR)\$(strip $(COMPONENT)).dep make\$(strip $(COMPONENT))
    endif
    ifeq ($(strip $(COMPONENT)),ijet_adp)
    	@if not $(ACTION)==remake if exist $(RULESDIR)\$(strip $(COMPONENT)).dep copy /y $(RULESDIR)\$(strip $(COMPONENT)).dep make\$(strip $(COMPONENT))
    endif
    ifeq ($(strip $(COMPONENT)),nemo_adp)
    	@if not $(ACTION)==remake if exist $(RULESDIR)\$(strip $(COMPONENT)).dep copy /y $(RULESDIR)\$(strip $(COMPONENT)).dep make\$(strip $(COMPONENT))
    endif
    endif
    endif
       # mbis time probe   
    	@if /I "$(strip $(MBIS_EN_OBJ_LOG))"  EQU "TRUE" (@perl -e "print 'T_E,$@,L,'. time . \"\n\"";>>$(TARGDIR)\log\mbis\$(strip $(COMPONENT))\$(*F)".mbis")
    ```
  * bat script `/I` 开关(如果指定)说明要进行的字符串比较不分大小写；
  * BAT脚本中可以使用type命令获取文件内容；
  * Compile Log Info：`build\ULTRA2503A_11C\bootloader.log`；
* `LINK_BL: LINK_BL_BIN_FILE LINK_BLEXT_BIN_FILE`
  ```Makefile
  # *************************************************************************
  #  Executable Bootloader Targets
  # *************************************************************************
  LINK_BL: LINK_BL_BIN_FILE LINK_BLEXT_BIN_FILE
  BL_POSTBUILD: BLFILE_POSTBUILD BLEXTFILE_POSTBUILD

  #ifneq ($(strip $(AUTO_CHECK_DEPEND)),TRUE)
  #$(BTLD_BIN_FILE): FORCE
  #else
  #-include $(strip $(RULESDIR_TARGET))\postgen_dep\.\bootloader.det
  #endif
  #$(BTLD_BIN_FILE): $(strip $(RULESDIR_TARGET))\postgen_dep\bl_preflow.det $(strip $(RULESDIR_TARGET))\postgen_dep\gen_bl_verno.det

  LINK_BL_BIN_FILE:
  	@if /I "$(strip $(MBIS_EN))"  EQU "TRUE" (@perl -e "print 'T_S,$@,B,'. time . \"\n\"";>>$(MBIS_BUILD_TIME_TMP))
  	@tools\make.exe -fmake\gsm2.mak -k -r -R XGC_AND_NOT_BOOTLOADER=FALSE CUSTOMER=$(strip $(CUSTOMER)) PROJECT=$(strip $(PROJECT)) bootloader.lib

  	@echo Linking $(strip $(BTLD_PREFIX)) ...
  	@perl tools\time.pl -n
  	@echo $(BTLDLNKOPT) > make\~libs.tmp
  	@echo $(strip $(COMPLIBDIR))\bootloader.lib(*) >> make\~libs.tmp
  	@if exist make\~bllibs.tmp (type make\~bllibs.tmp >> make\~libs.tmp)
  	@perl .\tools\sortLib.pl make\~libs.tmp $(strip $(COMPOBJS))
  	@if exist make\~sortedLibs.tmp (copy /y make\~sortedLibs.tmp $(strip $(COMPLOGDIR))\link_option_bl.log >nul)
    ifeq ($(strip $(PARTIAL_SOURCE)),TRUE)
  	tools\Linker.exe BOOTLOADER $(strip $(LINK)) $(strip $(BOOTLOADER_LOG)) NONE $(strip $(VIA)) NONE $(strip $(BIN_CREATE)) $(strip $(TARGDIR)) $(BTLD_PREFIX).elf $(strip $(BIN_FORMAT)) $(strip $(BTLD_BIN_FILE)) $(strip $(TST_DB)) $(BTLD_PREFIX).lis
    else
  	@($(LINK) $(VIA) make\~sortedLibs.tmp >> $(BOOTLOADER_LOG) 2>&1) & \
  	(if ERRORLEVEL 1 \
  				(echo Error: link failed! Please check $(BOOTLOADER_LOG)) & \
  				(if exist $(strip $(TARGDIR))\$(BTLD_PREFIX).elf (del /q $(strip $(TARGDIR))\$(BTLD_PREFIX).elf)))
    endif

  	@if /I "$(strip $(MBIS_EN))"  EQU "TRUE" (@perl -e "print 'T_E,$@,B,'. time . \"\n\"";>>$(MBIS_BUILD_TIME_TMP))

  BLFILE_POSTBUILD:
  	@if /I "$(strip $(MBIS_EN))"  EQU "TRUE" (@perl -e "print 'T_S,$@,B,'. time . \"\n\"";>>$(MBIS_BUILD_TIME_TMP))
  	@if not exist $(strip $(TARGDIR))\$(BTLD_PREFIX).elf \
  		(echo Error: $(strip $(TARGDIR))\$(BTLD_PREFIX).elf does not exist! Please check link error for bootloader. & exit 1)
  	$(strip $(BIN_CREATE)) $(strip $(TARGDIR))\$(BTLD_PREFIX).elf $(BIN_FORMAT) -output $(strip $(TARGDIR))\$(BTLD_BIN_FILE)
  ifneq ($(filter $(strip $(PLATFORM)),$(SV5_PLATFORM)),)
  	(@if /I "$(strip $(SW_BINDING_SUPPORT))" EQU "BIND_TO_CHIP"  .\tools\update_img.exe -blpath $(strip $(TARGDIR))\$(strip $(BTLD_BIN_FILE)) -keyini $(strip $(KEYFILE_PATH))) & \
  	(@if /I "$(strip $(SW_BINDING_SUPPORT))" EQU "BIND_TO_KEY"   .\tools\update_img.exe -blpath $(strip $(TARGDIR))\$(strip $(BTLD_BIN_FILE)) -keyini $(strip $(KEYFILE_PATH))) & \
  	@if not exist make\~gfh_cfg.tmp (tools\make.exe -fmake\gsm2.mak -r -R gen_gfh_cfg)
  	@echo $(strip $(TARGDIR))\$(strip $(BTLD_BIN_FILE))> make\~gfh_files.tmp
  	@perl tools\gfh_process.pl make\~gfh_files.tmp make\~gfh_cfg.tmp $(strip $(THE_MF)) > $(strip $(COMPLOGDIR))\gfh_process_bl.log 2>&1 & \
  	(if ERRORLEVEL 1 (echo Error: Failed in gfh_process.pl. Please check $(strip $(COMPLOGDIR))\gfh_process_bl.log & exit 1))
  #	@echo [Dependency] tools\update_img.exe $(KEYFILE_PATH) tools\gfh_process.pl >$(RULESDIR)\postgen_dep\bootloader.log
  else
  	@if exist $(strip $(TARGDIR))\$(strip $(BTLD_BIN_FILE))\READ_ONLY \
  		copy /Y $(strip $(TARGDIR))\$(strip $(BTLD_BIN_FILE))\READ_ONLY $(strip $(TARGDIR))\READ_ONLY & \
  		rmdir /S /Q $(strip $(TARGDIR))\$(strip $(BTLD_BIN_FILE)) & \
  		move /Y $(strip $(TARGDIR))\READ_ONLY $(strip $(TARGDIR))\$(strip $(BTLD_BIN_FILE))

  	(@if /I "$(strip $(SW_BINDING_SUPPORT))" EQU "BIND_TO_CHIP"  .\tools\update_img.exe -blpath $(strip $(TARGDIR))\$(strip $(BTLD_BIN_FILE)) -keyini $(strip $(KEYFILE_PATH))) & \
  	(@if /I "$(strip $(SW_BINDING_SUPPORT))" EQU "BIND_TO_KEY"   .\tools\update_img.exe -blpath $(strip $(TARGDIR))\$(strip $(BTLD_BIN_FILE)) -keyini $(strip $(KEYFILE_PATH))) & \

  	@perl .\tools\bl_append.pl $(strip $(TARGDIR))\$(strip $(BTLD_BIN_FILE)) $(strip $(BTLDVERNODIR))\bl_verno.c $(strip $(BL_SCATTERFILE)) $(strip $(THE_MF)) $(strip $(TARGDIR))\$(BTLD_PREFIX).sym $(call Upper,$(strip $(BIN_FILE))) $(strip $(VERNO))
  #	@echo [Dependency] tools\update_img.exe $(KEYFILE_PATH) tools\bl_append.pl >$(RULESDIR)\postgen_dep\bootloader.log
  endif

  	@if exist $(strip $(TARGDIR))\$(strip $(BIN_FILE))\ROM \
  		(if exist $(strip $(TARGDIR))\$(strip $(BIN_FILE))\$(strip $(BTLD_BIN_FILE)) \
  			del $(strip $(TARGDIR))\$(strip $(BIN_FILE))\$(strip $(BTLD_BIN_FILE))) & \
  		copy /Y $(strip $(TARGDIR))\$(strip $(BTLD_BIN_FILE)) $(strip $(TARGDIR))\$(strip $(BIN_FILE)) > nul

    ifeq ($(strip $(PARTIAL_SOURCE)),TRUE)
  	tools\Linker.exe BOOTLOADERs $(strip $(LINK)) $(strip $(LOG)) $(strip $(LNKERRORLOG)) $(strip $(VIA)) $(strip $(HEADER_TEMP)) $(strip $(BIN_CREATE)) $(strip $(TARGDIR)) $(strip $(IMG_FILE)) $(strip $(BIN_FORMAT)) $(strip $(BTLD_BIN_FILE)) $(strip $(TST_DB)) $(TARGNAME).lis
    endif
  	@if /I "$(strip $(MBIS_EN))"  EQU "TRUE" (@perl -e "print 'T_E,$@,B,'. time . \"\n\"";>>$(MBIS_BUILD_TIME_TMP))
  ```
