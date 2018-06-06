# MT2503 Make Hacking

* `make2.pl`脚本最后执行的一行代码是`exit $result >> 8;`，之前的都是执行的从上到下的代码，在此之后的都是会被调用的处理函数；
* 主要跟踪的是`.\make ULTRA2503A_11C GPRS new`执行的流程；
* `make\ULTRA2503A_11C_GPRS.mak`中的内容在其他Makefile中会被include进去，这样这里面的键值对就被用于选择模块定义了；

## 参考文档

* [MTK 功能机编译](https://blog.csdn.net/u010783226/article/details/73368922)

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
  ```
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
    ```
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
    ```
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
      ```
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

## Generate Bootloader

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
