#!/usr/local/bin/perl
# 
# Copyright Statement:
# --------------------
# This software is protected by Copyright and the information contained
# herein is confidential. The software may not be copied and the information
# contained herein may not be used or disclosed except with the written
# permission of MediaTek Inc. (C) 2005
# 
# BY OPENING THIS FILE, BUYER HEREBY UNEQUIVOCALLY ACKNOWLEDGES AND AGREES
# THAT THE SOFTWARE/FIRMWARE AND ITS DOCUMENTATIONS ("MEDIATEK SOFTWARE")
# RECEIVED FROM MEDIATEK AND/OR ITS REPRESENTATIVES ARE PROVIDED TO BUYER ON
# AN "AS-IS" BASIS ONLY. MEDIATEK EXPRESSLY DISCLAIMS ANY AND ALL WARRANTIES,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NONINFRINGEMENT.
# NEITHER DOES MEDIATEK PROVIDE ANY WARRANTY WHATSOEVER WITH RESPECT TO THE
# SOFTWARE OF ANY THIRD PARTY WHICH MAY BE USED BY, INCORPORATED IN, OR
# SUPPLIED WITH THE MEDIATEK SOFTWARE, AND BUYER AGREES TO LOOK ONLY TO SUCH
# THIRD PARTY FOR ANY WARRANTY CLAIM RELATING THERETO. MEDIATEK SHALL ALSO
# NOT BE RESPONSIBLE FOR ANY MEDIATEK SOFTWARE RELEASES MADE TO BUYER'S
# SPECIFICATION OR TO CONFORM TO A PARTICULAR STANDARD OR OPEN FORUM.
# 
# BUYER'S SOLE AND EXCLUSIVE REMEDY AND MEDIATEK'S ENTIRE AND CUMULATIVE
# LIABILITY WITH RESPECT TO THE MEDIATEK SOFTWARE RELEASED HEREUNDER WILL BE,
# AT MEDIATEK'S OPTION, TO REVISE OR REPLACE THE MEDIATEK SOFTWARE AT ISSUE,
# OR REFUND ANY SOFTWARE LICENSE FEES OR SERVICE CHARGE PAID BY BUYER TO
# MEDIATEK FOR SUCH MEDIATEK SOFTWARE AT ISSUE.
# 
# THE TRANSACTION CONTEMPLATED HEREUNDER SHALL BE CONSTRUED IN ACCORDANCE
# WITH THE LAWS OF THE STATE OF CALIFORNIA, USA, EXCLUDING ITS CONFLICT OF
# LAWS PRINCIPLES.  ANY DISPUTES, CONTROVERSIES OR CLAIMS ARISING THEREOF AND
# RELATED THERETO SHALL BE SETTLED BY ARBITRATION IN SAN FRANCISCO, CA, UNDER
# THE RULES OF THE INTERNATIONAL CHAMBER OF COMMERCE (ICC).
# 

require v5.8.6;
use Win32::OLE qw(in);
use Win32API::Registry qw(:ALL);
# for mbis start stamp
$build_time_sec = time;
($sec, $min, $hour, $mday, $mon, $year) = localtime($build_time_sec);
$build_time_string = sprintf("%4.4d.%2.2d.%2.2d.%2.2d.%2.2d.%2.2d", $year+1900, $mon+1, $mday, $hour, $min, $sec);


$myCmd = "make"; #$0
$plat = "";
$custom = "MTK";
@arguments = ();
$project = "";
$action = "";
$m_in_lsf = 0;
$local_q = 0;
@mOpts = ();
$fullOpts = "";
$level = "";
$relDir = "";
$ini = "make.ini";
$enINI = 1;
($#ARGV < 0) && &Usage;
(($#ARGV < 1) && ($enINI == 0)) && &Usage;

my $newMoDIS = 0;
my $bypassMoDIS = 0;
my $atMoDIS = 0;
my $newUESim = 0;
my $pureMoDIS = 0;
my $modisDir = "";
my $target_option = "";
my $check_depend = 0;
my $run_flavor_conf = 0;
$dummyvm = 0;
$disable_ib = 0;
$rmdebug = 0;

#mbis default enable
$mbis = "tools\\mbis.pl";
$arg_mbis_en = "FALSE";
$arg_mbis_en_obj_log = "FALSE";
$arg_mbis_en_save_log = "FALSE";
$mbis_arg_exist = 0;
$mbis_en = "FALSE";
$mbis_en_obj_log = "FALSE";
$mbis_en_save_log = "FALSE";
@mbis_arg = ();
#$mbis_conf_file = "\\\\glbfs14\\sw_releases\\mbis\\scripts\\MBIS_conf.ini";
$mbis_conf_file = "tools\\MBIS_conf.ini";
@orgARGVwithFlavor = ();
$mbis_num_proc = 0;
$mbis_incredibuild = 0;
$mbis_target_build_with_Modis = 0;
@levels = qw(level2_src level2_obj level1 vendor);
@actions = qw(getusr new update remake clean resgen codegen nvram_auto_gen bootloader fota emiclean emigen sysgen sys_auto_gen sys_mem_gen ckscatter mmi_feature_check mmi_obj_check operator_check viewlog rel c,r c,u ckcr dummy_data_check lint removecode custpack custpackini theme_bin scan check_scan check ck3rdptylic check_dep remake_dep update_dep cci clean_codegen slim_codegen slim_mcddll mcddll_update slim_update crip genlog ckmemcons findpad elfpatch gendsp cksysdrv nvram_auto_gen xml_parser rmdebugobj cust_menu_tree_check genmoduleinfo gen_modlibtbl ximgen gen_bt_switch_info gendummylis echo_dspinfo genmakefile video_mem_gen obj_sys_auto_gen dcm_debug);
@projects = qw(l1s gsm gprs basic umts hspa udvt tdd128 tdd128dpa tdd128hspa);
@orgARGV = @ARGV;
@orgARGVwithFlavor = @orgARGV;

$localq_disk = "z:";
print "ENV{\"OS\"}: $ENV{\"OS\"}\n";
if ($ENV{"OS"} eq "Windows_NT") {
  $delCmd = "del /Q";
  $dirDelim = "\\";
  $makeFolder = "make\\";
} else {
  $delCmd = "rm";
  $dirDelim = "/";
  $makeFolder = "make/";
}

if ($ENV{'MTK_INTERNAL'} eq 'TRUE') {
	# MTK_INTERNAL is a internal environment flag
} elsif (($ENV{'USERDOMAIN'} =~ /MTK|PMT|MBJ|MSZ|MTI|WISE|MEDIATEK|MWS|GCN|APJ/i) && ($ENV{'USERDNSDOMAIN'} =~ /MEDIATEK\.INC/i)) {
	warn "Current user is from MTK internal, but the environment MTK_INTERNAL != TRUE\nPlease check ! Build script will continue after 30 sec.\n";
	sleep 30;
	$ENV{'MTK_INTERNAL'} = 'TRUE';
}

if (($ENV{'MTK_INTERNAL'} eq 'TRUE') && (-e "mtk_tools\\Internal_function.pm")) {
	require mtk_tools::Internal_function;
}

$no_pcibt = "FALSE";

my $numArgs = $#ARGV + 1;
print "thanks, you gave me $numArgs command-line arguments.\n";

foreach my $argnum (0 .. $#ARGV) {
   print "$ARGV[$argnum]\n";
}

# .\make ULTRA2503A_11C GPRS new
# 这个前面的一堆的判断，对于上面这条命令来说，没有用途，主要在else中解析
while ($#ARGV != -1) {
  if ($ARGV[0] =~ /^(p|pl|pla|plat|platf|platfo|platfor|platform)=(\w+)/i) {
    $plat = $2;
  } elsif ($ARGV[0] =~ /^(c|cu|cus|cust|custo|custom)=(\w+)/i) {
    $custom = $2;
  } elsif ($ARGV[0] =~ /-modis/i) {
    $newMoDIS = 1;
  } elsif ($ARGV[0] =~ /-forcemodis/i) {
    $newMoDIS = 1;
    $bypassMoDIS = -1;
  } elsif ($ARGV[0] =~ /-atmodis/i) {
    $atMoDIS = 1;
  } elsif ($ARGV[0] =~ /-puremodis/i) {
    $pureMoDIS = 1;
  } elsif ($ARGV[0] =~ /-uesim/i) {
    $newUESim = 1;
  } elsif ($ARGV[0] =~ /-dummyvm/i) {
    $dummyvm = 1;
  } elsif ($ARGV[0] =~ /-release/i) {
    $modisDir = "Release";
  } elsif ($ARGV[0] =~ /-debug/i) {
    $modisDir = "Debug";
  } elsif ($ARGV[0] =~ /-h/i) {
    &Usage;
  } elsif ($ARGV[0] =~ /^-(o|op|opt)=(.*)$/i) {
    $fullOpts = "CMD_ARGU=$2";
    @mOpts = split(",", $2);
  } elsif ($ARGV[0] =~ /-lsf/i) {
    $m_in_lsf = 1;
  } elsif ($ARGV[0] =~ /-no_lsf/i) {
    $not_enter_lsf = 1;
  } elsif ($ARGV[0] =~ /-localq/i) {
    $local_q = 1;
  } elsif ($ARGV[0] =~ /-localpath/i) {
    $local_p = 1;
  } elsif ($ARGV[0] =~ /-disable_ib/i) {
    $disable_ib = 1;
  } elsif ($ARGV[0] =~ /-no_ib/i) {
    $disable_ib = 1;
  } elsif ($ARGV[0] =~ /-bm/i) {
    $disable_ib = 1;
  } elsif ($ARGV[0] =~ /-klocwork/i) {
    $RUN_KLOCWORK = 1;
  } elsif ($ARGV[0] =~ /-disk=(.*)/i) {
    $localq_disk = $1;
  } elsif ($ARGV[0] =~ /^-mbis=(.*)$/i) {
    # mbis get argument
    @mbis_arg = split(",", $1);
    &mbis_parse_arg;
  } elsif ($ARGV[0] =~ /-rmdebug/i) {
    $rmdebug = 1;
  } elsif ($ARGV[0] =~ /-bootup=(.*)$/i) {
    $bootup_arg = uc($1);
  } elsif ($ARGV[0] =~ /-smart/i) {
    $check_depend = 1;
    $run_flavor_conf = 1;
  } elsif ($ARGV[0] =~ /-no_cgen/i) {
    $target_option .= " REMAKE_WITH_CGEN=FALSE";
  }
  #Add for daily build
  elsif ($ARGV[0] =~ /-dbld/i) {
    $daily_build = 1;
  }
  elsif ($ARGV[0] =~ /(-no_pcibt|-no_pc)\b/i) {
    $no_pcibt = "TRUE";
  }
  else {
    # @projects = qw(l1s gsm gprs basic umts hspa udvt tdd128 tdd128dpa tdd128hspa);
    foreach $m (@projects) {
      # make gprs codegen                    (MT6218B EVB codegen)
      if (lc($ARGV[0]) eq $m) {
        $project = $m;
        print "ARGV[0]: $project\n";
        shift(@ARGV);
        last;
      # make firefly17_demo gprs new
      } elsif (lc($ARGV[1]) eq $m) {
        $project = $m;
        $custom = $ARGV[0];
        print "ARGV[1]: $project $custom\n";
        shift(@ARGV);
        shift(@ARGV);
        last;
      }
    }
    if(-e "SubReleaseConfig.ini")
    {
      print "SubReleaseConfig.ini: \n";
      open (FILE_HANDLE, "<SubReleaseConfig.ini") or die "cannot open SubReleaseConfig.ini\n";
	  while (<FILE_HANDLE>) {
	    if (/^(\S+)\s*=\s*(\S+)/) {
	      $keyname = $1;
	      $${keyname} = $2;
	    }
	  }
	  close FILE_HANDLE;
	  
	  if(($newMoDIS ==1) || ($ARGV[0] =~ /_modis/i))
	  {
	  	if($MoDIS_Build =~ /FALSE/i)
	  	{
	  		die "This project can't build modis.\n";
	  	}
	  }

	  if($Project_Name =~ /^(\w+)_(\w+)\((\w+)\)$/i)
	  {
	  	$default_custom = "$1($3)";
	  	$default_project = "$2";
	  }
	  elsif($Project_Name =~ /^(\w+)_(\w+)$/i)
	  {
	  	$default_custom = "$1";
	  	$default_project = "$2";
	  }
    }
    else
    {
      print "SubReleaseConfig.ini:  not exists or is a directory\n";
    }
    if (($project eq "") && ($enINI == 1) && (-e $ini)) {
      open (FILE_HANDLE, "<$ini") or die "cannot open $ini\n";
      while (<FILE_HANDLE>) {
        if (/^(\S+)\s*=\s*(\S+)/) {
          $keyname = $1;
          $${keyname} = $2;
        }
      }
      close FILE_HANDLE;
      print "custom=$custom; plat=$plat; project=$project\n";
    }
    elsif(($project eq "") && (-e "SubReleaseConfig.ini"))
    {
    	$custom = $default_custom;
    	$project = lc($default_project);
    }
    else
    {
      print "project=$project\n";
    }
    ($project eq "") && (die "Unrecognized \"$ARGV[0]\" or \"$ARGV[1]\"\nLack off one of (@projects)\nOr try $myCmd -h\n");
    if ((-e "SubReleaseConfig.ini")) {
    	$result = system("perl mtk_tools\\USR\\USR_Initial.pl $m_in_lsf $custom $project $makeFolder");
    	exit 1 if ($result);
    }

    print "#ARGV=$#ARGV, ARGV[0]=$ARGV[0]\n";
    if ($#ARGV != -1) {
      if ($ARGV[0] =~ /^[ucrUCR]$/) {
        ($action = "clean") if ($ARGV[0] =~ /^[cC]$/);
        ($action = "update") if ($ARGV[0] =~ /^[uU]$/);
        ($action = "remake") if ($ARGV[0] =~ /^[rR]$/);
        shift(@ARGV);
        @arguments = @ARGV;
        @ARGV = ();
        last;
      } else {
        print "action = new\n";
        if ($ENV{'MTK_INTERNAL'} eq 'TRUE')
        {
          unshift(@actions, "bm_new", "notify","warn_notify", "cq_notify", "err_out", "db_notify",  "db_modis_notify", "bm_remake", "bm_update", "patch", "patch_hal", "find", "at", "rm_cleanroom", "ckmake", "gendoc", "at_rel", "rmdebugobj","catgen");
          unshift(@actions, "cmmgen");
          unshift(@actions, "cfggen");
        } 
        else
        {
          print "ENV{'MTK_INTERNAL'}: $ENV{'MTK_INTERNAL'}\n";
        }
        if (-d "MoDIS_VC9") {
          print "MoDIS_VC9 directory exist\n";
          # 这是shift的反函数。unshift 会传入一个或多个值(或者0个) 并把它放在数组的开头，将其他元素右移动。
          # @actions = qw(getusr new update remake clean resgen codegen nvram_auto_gen bootloader fota emiclean emigen sysgen sys_auto_gen sys_mem_gen ckscatter mmi_feature_check mmi_obj_check operator_check viewlog rel c,r c,u ckcr dummy_data_check lint removecode custpack custpackini theme_bin scan check_scan check ck3rdptylic check_dep remake_dep update_dep cci clean_codegen slim_codegen slim_mcddll mcddll_update slim_update crip genlog ckmemcons findpad elfpatch gendsp cksysdrv nvram_auto_gen xml_parser rmdebugobj cust_menu_tree_check genmoduleinfo gen_modlibtbl ximgen gen_bt_switch_info gendummylis echo_dspinfo genmakefile video_mem_gen obj_sys_auto_gen dcm_debug);
          print "actions before ---- :\n @actions\n";

          unshift(@actions, "new_modis", "sys_mem_gen_modis", "new_uesim", "sys_mem_gen_uesim");
          unshift(@actions, "gen_modis", "gen_uesim") if (-e "MoDIS_VC9\\createMoDIS.pl");
          unshift(@actions, "codegen_modis", "clean_codegen_modis", "codegen_uesim", "clean_codegen_uesim");
          unshift(@actions, "remake_modis", "clean_modis", "update_modis", "remake_uesim", "clean_uesim", "update_uesim");
          unshift(@actions, "c,r_modis", "c,u_modis", "c,r_uesim", "c,u_uesim");
          unshift(@actions, "at_modis", "ap_modis", "ap_uesim");
          unshift(@actions, "codegen_vre_modis", "mtegen");

          print "actions after ---- :\n @actions\n";
        }
        else
        {
          print "MoDIS_VC9 directory not exist\n";
        }
        unshift(@actions, "new_viti", "bm_new_viti", "remake_viti") if (-d "hal\\viti");
        # hat\\viti not exist
        print "actions after ---- :\n @actions\n";
        foreach $act (@actions) {
          print "ARGV: $ARGV[0], act: $act\n";
          if (lc($ARGV[0]) eq $act) {
            $action = $act;
            print "action: $action\n";
            if (($act eq "bm_update") || ($act eq "bm_remake")) {
              ($action = "update") if ($act eq "bm_update");
              ($action = "remake") if ($act eq "bm_remake");
              ($fullOpts eq "") ? ($fullOpts = "CMD_ARGU=-k") : ($fullOpts .= ",-k");
              push(@mOpts, "-k");
            }
            else
            {
                print "aciton else\n";
            }
            shift(@ARGV);
            @arguments = @ARGV;
            @ARGV = ();
            print "arguments: @arguments, ARGV: @ARGV\n";
            last;
          }
        }
      }
    }
    print "final action: $action, #ARGV: $#ARGV\n";
    ($action eq "") && (die "Unrecognized \"$ARGV[0]\"\nLack off one of (@actions)\nOr try $myCmd -h\n");
    ($#ARGV != -1) && (die "Unrecognized \"@ARGV\"\nPlease check again or try $myCmd -h\n");
    if ($action eq "rel" || $action eq "ckcr") {
      $relDir = $arguments[0];
      shift(@arguments);
      ($#arguments == -1) && die "Lack off release level(@levels).\nOr try $myCmd -h\n";
      foreach $arg (@levels) {
        if (lc($arguments[0]) eq $arg) {
          $level = $arg;
          shift(@arguments);
          last;
        }
      }
      ($level eq "") && die "Lack off release level(@levels).\nOr try $myCmd -h\n";
      ($#arguments != -1) && (warn "Unrecognized \"@arguments\"\n");
    }
    else
    {
      print "action is not rel and ckcr\n";
    }
    if ($action eq "removecode") {
      $remove_dir = $arguments[0];
    }
    else
    { 
      print "action is not removecode\n";
    }
    last;
  }

  shift(@ARGV);
}
# 如果make目录不存在，那么就退出了
(!-d "make")&&(die "Folder \"make\" does NOT exist!\nPlease help to check.\n");

if ($action =~ /^(bm_new|bm_update|bm_remake)$/i)
{
  $ENV{"PCIBT_NO_STOP"} = "TRUE";
}
else
{
  print "action is not bm_new|bm_update|bm_remake\n";
}

if ((-e "mtk_tools\\Perl") && ($] >= 5.008006)){
  use lib "mtk_tools\\Perl";
  use Win32::Process;
  use Win32;
  use Net::SMTP;
}

print("local_q: $local_q, local_p: $local_p\n");
if (($local_q == 1) && ($local_p != 1)) {
  chomp(my $cwd = `cd`);
  system("subst $localq_disk $cwd");
  chdir("$localq_disk");
  print "cwd = $cwd\n";
}

chomp($cwd = `cd`);
print "cwd: $cwd\n";
if ($cwd =~ /\s+/)
{
  $arrow = $cwd;
  $arrow =~ s/\s/\^/g;
  $arrow =~ s/[^\^]/ /g;
  print "\n$cwd\n";
  print "$arrow\n";
  print "Space is not a legal character for a folder name.\nPlease check it !!\n";
  exit 1;
}
else 
{
  print "cwd: ckeck directory is ok\n";
}

# delete temp. files in make folder before executing build command
print "delCmd: $delCmd, makeFolder: $makeFolder\n";
`$delCmd ${makeFolder}~*.tmp > nul 2>&1`;

if ($custom =~ /^(\w+)\((\w+)\)$/i) # match <custom>(<flavor>)=>SUPERMAN29_DEMO(FLAVOR)
{
    $custom = uc($1);
    $flavor = uc($2);
    $flavorMF = "${custom}_${project}($flavor).mak";
    #(!-e "${makeFolder}${flavorMF}") && (die "${makeFolder}${flavorMF} does NOT exist!\nPlease help to check.\n");
    if (-e "${makeFolder}${flavorMF}")
    {
       print ("copy /y ${makeFolder}${flavorMF} ${makeFolder}${custom}_${project}.mak\n");
       system("copy /y ${makeFolder}${flavorMF} ${makeFolder}${custom}_${project}.mak > nul");
    }
    if (($action =~ /\b(new|bm_new|codegen|sysgen|sys_auto_gen|getusr)\b/i) || ($pureMoDIS == 1))
    {
      system("md build\\${custom}\\log") if(!-d "build\\${custom}\\log");
      $run_flavor_conf = 1;
      #print ("perl make\\flavor_conf.pl $custom $flavor $project\n");
      #$fla_rel = system("perl make\\flavor_conf.pl $custom $flavor $project > build\\${custom}\\log\\flavor_conf.log 2>&1");
      #die "\nError: make\\flavor_conf.pl failed, please check error message in build\\${custom}\\log\\flavor_conf.log\n" if($fla_rel);
    }
    
    @tmpARGV = @orgARGV;
    @orgARGV = ();
    foreach (@tmpARGV)
    {
       $_ = $custom if (/^(${custom}\($flavor\))$/i);
       push (@orgARGV, $_);
    }
}
else
{
  print "custom: $custom\n";
}

#  创建build\log目录存放编译log
system("md build\\${custom}\\log") if(!-d "build\\${custom}\\log");

# $ini = "make.ini";
# 将make配置信息写入文件中
open (FILE_HANDLE, ">$ini") or die "cannot open $ini\n";
print FILE_HANDLE "plat= \ncustom= $custom\nproject= $project\n";
close FILE_HANDLE;

if ($action eq "getusr") 
{
    exit 0;
}
# for initial mbis config 
&mbis_init;
&mbis_start_probe;
# mbis options
system("echo MBIS_EN=$mbis_en >> ${makeFolder}~buildinfo.tmp");
system("echo MBIS_EN_OBJ_LOG=$mbis_en_obj_log >> ${makeFolder}~buildinfo.tmp");
system("echo NO_PCIBT=$no_pcibt >> ${makeFolder}~buildinfo.tmp");

if (($action ne "ckmake") && ($action ne "mmi_feature_check") && ($action ne "ck3rdptylic")) {
  print("m_in_lsf: $m_in_lsf\n");
  if ($m_in_lsf != 1) {
    # Before executing actions, dump environment information to the build.log
    if (!-d ".\\build\\${custom}") {
      system("md .\\build\\${custom}");
    }
    # 这个文件是不存在的
    if(-e ".\\SubReleaseConfig.ini")
	  {
	  	print "copy .\\SubReleaseConfig.ini .\\build\\${custom}";
	  	system("copy .\\SubReleaseConfig.ini .\\build\\${custom}");
	  }
    system("echo USERNAME=%USERNAME%>.\\build\\${custom}\\build.log");
    system("perl -e \"print \'START TIME=\'\";>>.\\build\\${custom}\\build.log");
    system("perl tools\\time.pl -n>>.\\build\\${custom}\\build.log");
  }
}

my $package;
print "package: $package\n";
# 目前就是Windows下编译的，所以用这个部分的代码
if ($ENV{"OS"} eq "Windows_NT") {
  $toolsFolder = "tools\\";
  $MTKtoolsFolder = "mtk_tools\\";
  
  $prj_file = "make\\${custom}_${project}.mak";
  print("prj_file: $prj_file\n");
  
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
  print "tools_Dirs: @tools_Dirs\n";

  $makeCmd = "tools\\make.exe";
  push (@tools_file,$makeCmd) ;
  print "tools_file: @tools_file, ENV{'MTK_INTERNAL'}: $ENV{'MTK_INTERNAL'}\n";
  if ($ENV{'MTK_INTERNAL'} eq 'TRUE')
  {
  	$VerCmd = "make\\VerifyCus.mak";
  	push (@tools_file,$VerCmd) ;
  }
  # 这两个目录貌似都不存在的
  @mmi_path = qw(plutommi\\Customer\\ResGenerator lcmmi\\Customer\\ResGenerator);
  foreach $mmi_path (@mmi_path)  
  {
    next if (!-d $mmi_path);
    $sevenZa_file = $mmi_path."\\7za.exe";
    push (@tools_file,$sevenZa_file) ;
    $convert = $mmi_path."\\convert.exe";
    push (@tools_file,$convert) ;
  }
} else {
  $toolsFolder = "tools/";
  $MTKtoolsFolder = "mtk_tools/";
  
  $prj_file = "make/${custom}_${project}.mak";
  
  $package = &get_package;
  if ($package =~ /_(OBJ)_/i)
  {
    @tools_Dirs = qw(tools/);
  }
  else
  {
    if ($WISDOM_CUSTOM_BUILD eq "TRUE") {
      @tools_Dirs = qw(tools/ tools/MinGW);
    } else {
      @tools_Dirs = qw(tools/ tools/MinGW tools/MSYS);
    }
  }

  $makeCmd = "tools/make";
  push (@tools_file,$makeCmd) ;
  if ($ENV{'MTK_INTERNAL'} eq 'TRUE')
  {
    $VerCmd = "make\\VerifyCus.mak";
    push (@tools_file,$VerCmd) ;
  }
  @mmi_path = qw(plutommi/Customer/ResGenerator lcmmi/Customer/ResGenerator);
  foreach $mmi_path (@mmi_path)
  {
    next if (!-d $mmi_path);
    $sevenZa_file = $mmi_path."/7za.exe";
    push (@tools_file,$sevenZa_file) ;
    $convert = $mmi_path."/convert.exe";
    push (@tools_file,$convert) ;
    last;
  }
}

# 检查目录是否存在
foreach $tools_Dirs (@tools_Dirs)
{
  if (!-d $tools_Dirs)
  {
    warn "$tools_Dirs folder does NOT exist!\n";
    &cp_3rdpartyTool;
  }
}

# 检查目录是否存在
foreach $tools_file (@tools_file)
{
  if (!-e $tools_file)
  {
    warn "$tools_file does NOT exist!\n";
    &cp_3rdpartyTool;
  }
}

my $no_of_proc=1;
my $exec_xgc_result=999;
# $exec_xgc_result  = system("XGConsole /NOLOGO /SILENT /NOWAIT tools\\XGC_Test.xml \n");
$exec_xgc_result  = `XGConsole /NOLOGO /SILENT /NOWAIT tools\\XGC_Test.xml  2>&1`;

if  ("$exec_xgc_result" ne "")
{
  $exec_xgc_result=99;
  print "XGConsole not found\n";
  $mbis_incredibuild=3;
} else {

  if (("$ENV{\"TERM\"}" eq "") && ($local_q != 1) && ("$ENV{\"USERDOMAIN\"}" eq "DOMAIN_MTK"))
  {
    #if (($ENV{"LSF_BINDIR"} eq "") || ($m_in_lsf==1))
    #{
    #  $disable_ib = 1;
    #  print " WARNING: XGConsole is supported but it's NOT in telnet mode.  TERM is not defined! \n";
    #}
  }

  if ($disable_ib==0)
  {
    $exec_xgc_result=0;
    # print "XGConsole found";
  } else {
    $exec_xgc_result=99;
  }
}

my $strBypassMoDIS = 0;
#my $notify_list = "\\\\glbfs14\\sw_releases\\3rd_party\\Scripts\\BM_conf.ini";
my $notify_list = "tools\\BM_conf.ini";
print "notify_list: $notify_list\n";
if (($ENV{'MTK_INTERNAL'} eq 'TRUE') && (-e "$notify_list")) {
  %BM_conf = iniToHash($notify_list);
  $curr_usr = lc(getlogin());
  $BM_LIST=$BM_conf{'romizing_server'}->{'BM_LIST'};
  #$BuildInfoServer=$BM_conf{'BUILD_INFORMATION'}->{'SERVER'};
  $LICENSE_FILE = $BM_conf{'NODELOCKED_LICENSE'}->{'LICENSE_FILE'};
  if ($bypassMoDIS > -1)
  {
    $strBypassMoDIS = $BM_conf{'MODIS_RULE'}->{'MODIS_BYPASS'};
  }
}
else
{
  print "notify_list: if else\n";
}



  if ( $exec_xgc_result==0 )
  {
    $no_of_proc = 12;
    if ($fullOpts eq "") {
      $fullOpts = "CMD_ARGU=-j$no_of_proc";
    } else {
      $fullOpts .= ",-j$no_of_proc";
    }

    if ($mbis_en eq "TRUE")
    {
      $mbis_num_proc = $no_of_proc;
      $mbis_incredibuild = 1;
    }
  }
  else
  {
    print "exec_xgc_result is not 0\n";
  }

  print "ENV{\"NUMBER_OF_PROCESSORS\"}:$ENV{\"NUMBER_OF_PROCESSORS\"}\n";
  if ($ENV{"NUMBER_OF_PROCESSORS"} > 1) {
    print "exec_xgc_result: $exec_xgc_result\n";
    if ( $exec_xgc_result!=0 )
    {
      $PROCESS_NUM = $ENV{"NUMBER_OF_PROCESSORS"};
      $license_num = -1;
      # Check if license number is enough.
      if ($ENV{'MTK_INTERNAL'} eq 'TRUE') {
        if (!-e "$LICENSE_FILE") {
          $license_num += 1;
          system ("lmutil lmstat -f compiler>license.log 2>nul");
          open (FILE_HANDLE, "license.log");
          while (<FILE_HANDLE>) {
            if ($_ =~ /.+ (\d+) licenses .+ (\d+) .+/) {
              $license_num = $license_num + $1 - $2;
            }
          }
          close(FILE_HANDLE);
        }
        if (($license_num > 0) && ($license_num < $PROCESS_NUM)) {
          $PROCESS_NUM = ($license_num%2) ? int($license_num/2)+1 : int($license_num/2);
        }
      }
      else
      {
        print "don't to check license number\n";
      }

      print "fullOpts: $fullOpts\n";
      if ($fullOpts eq "") {
        $fullOpts = "CMD_ARGU=-j$PROCESS_NUM";
      } else {
        $fullOpts .= ",-j$PROCESS_NUM";
      }
      print "fullOpts: $fullOpts\n";

      if ($mbis_en eq "TRUE")
      {
        $mbis_num_proc = $PROCESS_NUM;
      }
      print "mbis_num_proc $mbis_num_proc\n";
    }
  }

print "fullOpts: $fullOpts\n";
if ($fullOpts ne "") {
# Fix build errors when "parallel jobs processing" fuction enabled by argument "-o|-op|-opt" in command line
  my @temp = @mOpts;
  @mOpts = ();
  print "temp: @temp, mOpts: @mOpts\n";
  foreach (@temp)
  {
    if ($_ =~ /^\s*(-j|--jobs)/)
    {
      $fullOpts .= ",$_";
    }
    else
    {
      push(@mOpts,$_);
    }
  }
# End
  $fullOpts =~ s/"/\\"/g;
  print "fullOpts: $fullOpts\n";
# $fullOpts = "\"$fullOpts\"";
  $fullOpts =~ s/,/ /g;
  print "fullOpts: $fullOpts\n";
# $makeCmd .= " " . join(" ", @mOpts) . " $fullOpts ";
  $makeCmd .= " " . join(" ", @mOpts);
  print "makeCmd $makeCmd\n";
}

my $exec_buildconsole=999;
#$exec_buildconsole  = system("BuildConsole \n");
$exec_buildconsole  = `BuildConsole  2>&1`;
print "exec_buildconsole: `BuildConsole  2>&1`\n";

if ($exec_buildconsole  =~ /IncrediBuild/)
{
  if (( "$ENV{\"TERM\"}" eq "" ) && ($local_q != 1) && ("$ENV{\"USERDOMAIN\"}" eq "DOMAIN_MTK"))
  {
    #if (($ENV{"LSF_BINDIR"} eq "") || ($m_in_lsf==1))
    #{
    #  $disable_ib = 1;
    #  print " WARNING: BuildConsole is supported but it's NOT in telnet mode.  TERM is not defined! \n";
    #}
  }
  if ($disable_ib==0)
  {
    $exec_buildconsole=0;
    #print "\nBuildConsole found";
  } else
  {
    $exec_buildconsole=99;
  }
} else
{
  $exec_buildconsole=99;
  print "\nBuildConsole not found\n";
}

print "m_in_lsf: $m_in_lsf\n";
if ($m_in_lsf == 1) {
  die "NOT IN LSF SERVER!\n" if ($ENV{"LS_ADMINNAME"} eq "");
  $computerName = $ENV{"COMPUTERNAME"};
  if ($local_q != 1) {
    system("echo set LAST_SUBMITTED_CF=$computerName > LAST_S_C.bat");
    $ENV{"TMP"} = "e:\\temp";
    $ENV{"TEMP"} = "e:\\temp";
    system("mkdir e:\\temp  > nul 2>&1") if (!-d "e:\\temp");
  }
  $ENV{"INLSF"} = $computerName;
}

print "plat: $plat\n";
if ($plat ne "") {
  $plat =~ y/a-z/A-Z/;
  $theMF = "${makeFolder}${plat}_${project}.mak";
  $enFile = "${makeFolder}${plat}_${project}_en.def";
  $disFile = "${makeFolder}${plat}_${project}_dis.def";
  if ($project =~ /GPRS/i) {
    $theVerno = "${makeFolder}verno_classb.bld";
  } elsif ($project =~ /(UMTS|HSPA)/i) {
    $theVerno = "${makeFolder}verno_classb_umts.bld";
  } else {
    $theVerno = "${makeFolder}verno.bld";
  }
} else {
  print "plat: $plat is empty\n";
  $custom =~ y/a-z/A-Z/;
  $plat = "NONE";
  $theMF = "${makeFolder}${custom}_${project}.mak";
  $enFile = "${makeFolder}${custom}_${project}_en.def";
  $disFile = "${makeFolder}${custom}_${project}_dis.def";
  $theVerno = "${makeFolder}Verno_${custom}.bld";

  print "custom: $custom\n";
  print "theMF: $theMF\n";
  print "enFile: $enFile\n";
  print "disFile: $disFile\n";
  print "theVerno: $theVerno\n";
}

# 检查相关文件是否存在
(!-e $theMF) && (die "$theMF does NOT exist!\nPlease help to check.\n");
(!-e $theVerno) && (die "$theVerno does NOT exist!\nPlease help to check.\n");
$myMF = "gsm2.mak";

# Get network path
# 这里是不会写入的，因为MTK_INTERNAL环境变量不存在
open (FILE_HANDLE, ">~net_path.tmp") or die "Cannot open ~net_path.tmp";
if ($ENV{'MTK_INTERNAL'} eq 'TRUE')
{
	$net_path = &get_net_path;
	print FILE_HANDLE "NET_PATH = $net_path\n";
}
close FILE_HANDLE;

open (FILE_HANDLE, "+<$theMF") or die "Cannot open $theMF. Please check if the file is READ-ONLY or not exists.\n";
$LOGFILE = "${custom}_${project}.log";
open (LOGFILE,">$LOGFILE") or die "Cannot open ${custom}_${project}.log.\n";
$line = 0;
while (<FILE_HANDLE>) {
	if (/^(\w+)\b\s*=/)
	{
	  if (/^(\S+)\s*=\s*(\S+)/) {
	    $line++;
        # Returns an uppercased version of EXPR. 
	    if ($1 ne uc($1)) {
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
	    #defined($${keyname}) && warn "$1 redefined in $thefile!\n";
	    if (($2 ne uc($2)) && ($1 !~ /SECURE_CUSTOM_NAME/i) && ($1 !~ /IPSEC_SUPPORT/i) && ($1 !~ /CUSTOM_CFLAGS/i) && ($1 !~ /RELEASE_PACKAGE/i) && ($1 !~ /COMPLIST/i) && ($1 !~ /COMP_TRACE_DEFS/i) && ($1 !~ /CUSTOM_COMMINC/i) && ($1 !~ /L1_TMD_FILES/i) && ($1 !~ /PARTIAL_TRACE_LIB/i)) {
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
	    $${keyname} = uc($2);
	  }
	}
  $postPosition=tell(FILE_HANDLE);
}
close LOGFILE;
close FILE_HANDLE;
print "flavorMF: ${flavorMF}\n";
print ("copy /y ${makeFolder}${custom}_${project}.mak ${makeFolder}${flavorMF}\n");
system("copy /y ${makeFolder}${custom}_${project}.mak ${makeFolder}${flavorMF}> nul");
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

print "verno: $verno\n";
if ($verno =~ /\s+/) {
  $arrow = $verno;
  $arrow =~ s/\s/\^/g;
  $arrow =~ s/[^\^]/ /g;
  print "\n$verno\n";
  print "$arrow\n";
  print "Space is not a legal character for VERNO name.\nPlease check it !!\n\n";
  exit 1;
}

# let lsf to get the version of this job 
$ENV{VERNO} = "$verno";

# Get custom_release value
print "demo_project: $demo_project\n";
# if ($demo_project eq "FALSE") {
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
  close FILE_HANDLE;
# }

############################################################
# To delete 3G codes in 2G projects.
if ((!defined($l1_3gsolution)) || ((defined($l1_3gsolution))&&($l1_3gsolution eq "NONE"))) {
  if ((!defined($monza2g)) || ($monza2g ne "TRUE")) {
    if (-e "3GList.txt") {
      open (F,"<3GList.txt");
      while (<F>) {
        if ($_ =~ /.+\.(c|h)/) {
          chop($_);
          if (-e "$_") {
            print "Warning! $_ should not exist in 2G project. The script will remove it.\n";
            system ("del /F /Q $_");
          }
        } else {
          chop($_);
          if (-d "$_") {
            print "Warning! $_ should not exist in 2G project. The script will remove it.\n";
            system ("rd /s /q $_");
          }
        }
      }
      close(F);
    }
  } else {
    if (-e "3GList.txt") {
      system ("del /Q 3GList.txt");
    }
  }
} else {
  if (-e "3GList.txt") {
    system ("del /Q 3GList.txt");
  }
}

# To check if FLAVOR length is less than 36 bytes
print "flaver: $flavor\n";
if ((defined($flavor)) && ($flavor ne "NONE")) {
  (length($flavor)>36) && die "ERROR: FLAVOR name should be less than 36 characters.\n";
}

# To copy needed GIS folder from Server to the local disk.
print "empty_resource: $empty_resource\n";
if ($empty_resource eq "FALSE") {
  if ((defined $gis_support) && ($gis_support ne "NONE")) {
    if ($gis_support eq "MAPBAR_NAVI") {
      open(FILE_HANDLE,"vendor\\gis\\mapbar\\map\\navi_map_version.ini") || die "Cannot open vendor\\gis\\mapbar\\map\\navi_map_version.ini:$!";
      $vendor="mapbar";
    } elsif ($gis_support eq "MAPBAR_BUS") {
      open(FILE_HANDLE,"vendor\\gis\\mapbar\\map\\bus_map_version.ini") || die "Cannot open vendor\\gis\\mapbar\\map\\bus_map_version.ini:$!";
      $vendor="mapbar";
    } elsif ($gis_support eq "SUNAVI") {
      open(FILE_HANDLE,"vendor\\gis\\sunavi\\map\\sunavi_map_version.ini") || die "Cannot open vendor\\gis\\mapbar\\map\\sunavi_map_version.ini:$!";
      $vendor="sunavi";
    }
    while (<FILE_HANDLE>) {
      if (/\[TEST_SOURCE\]\s+=\s+(.+)/){
        # For internal
        $test_source = $1;
        $dir_exist=system("dir /b $test_source>nul");
        $test_source =~ /.+\\(.+)?\"/;
        $target_folder=$1;
      }
    }
    close(FILE_HANDLE);
    if ((!-d "vendor\\gis\\$vendor\\map\\$target_folder") && ($dir_exist == 0)) {
      print "mkdir vendor\\gis\\$vendor\\map\\$target_folder\n";
      system("mkdir vendor\\gis\\$vendor\\map\\$target_folder");
      print "xcopy /e /Y $test_source vendor\\gis\\$vendor\\map\\$target_folder\n";
      system("xcopy /e /Y $test_source vendor\\gis\\$vendor\\map\\$target_folder > nul");
    }
  }
}

# To copy needed LangLearn folder from Server to the local disk.
print "langln_engine: $langln_engine\n";
if ((defined $langln_engine) && (uc($langln_engine) eq "LANGLN_DIGIDEA")) {
  if (-e "vendor\\langlearn\\Courseware\\Englishto_courseware_release.ini") {
    open(FILE_HANDLE,"vendor\\langlearn\\Courseware\\Englishto_courseware_release.ini") || die "Cannot open Englishto_courseware_release.ini:$!";
    while (<FILE_HANDLE>) {
      if (/\[DEMO_SOURCE\]\s+=\s+(.+)/){
        $demo_source = $1;
        $dir_exist=system("dir /b $demo_source>nul");
        $demo_source =~ /.+\\(.+)?\"/;
        $target_folder=$1;
      }
    }
    close(FILE_HANDLE);
    if ((!-d "vendor\\langlearn\\Courseware\\$target_folder") && ($dir_exist == 0)) {
      print "mkdir vendor\\langlearn\\Courseware\\$target_folder\n";
      system("mkdir vendor\\langlearn\\Courseware\\$target_folder");
      print "xcopy /e /Y $demo_source vendor\\langlearn\\Courseware\\$target_folder\n";
      system("xcopy /e /Y $demo_source vendor\\langlearn\\Courseware\\$target_folder > nul");
    }
  }
}

# To copy needed romizing files from Server to the local disk.
print "j2me_support: $j2me_support\n";      # NONE
if ((defined $j2me_support) && (uc($j2me_support) ne "NONE")) {
  if ((($action ne "ckmake") && ($action ne "mmi_feature_check")) && ($ENV{'MTK_INTERNAL'} eq 'TRUE')) {
    if ((-e "tools\\go_romizing.pl") || (uc($custom_release) ne "TRUE"))
    {
      $result = system("perl tools\\go_romizing.pl $theMF $theVerno $m_in_lsf") >> 8;
      if ($result)
      {
        print "ROMizing result = $result\n";
        exit(1) if (lc($action) ne "bm_new");
      }
    }
  }
} else {
  if (($BM_LIST =~ /$curr_usr/i) && (-d "j2me\\vm\\IJET\\romizing")) {
    print ("call rd /s /q j2me\\vm\\IJET\\romizing\n");
    system("call rd /s /q j2me\\vm\\IJET\\romizing");
  }
}

# To build needed wndrv
if (defined $wifi_support) {
  if (uc($wifi_support) ne "NONE") {
    print "wifi_support: $wifi_support\n";
  } else {
    print "Remove WIFI source codes.\n";
    system("call mtk_tools\\RmCleanRoom.bat wndrv 2>nul");
  }
} else {
  print "Remove WIFI source codes.\n";
  system("call mtk_tools\\RmCleanRoom.bat wndrv 2>nul");
}

# To check if custom folder exists.
if ($action !~ /^(ap_modis|at_modis|at|mmi_feature_check)$/i) {
  # path: make/ULTRA2503A_11C_GPRS.mak --> BOARD_VER = ULTRA2503A_11C_BB
  # path: make/ULTRA2503A_11C_GPRS.mak --> FLAVOR = NONE
  print "action: $action, flavor: $flavor, board_ver: $board_ver\n";
  if ((defined($flavor)) && ($flavor ne "NONE")) {
    if ((!-d "custom\\system\\$board_ver") && (!-d "custom\\system\\$board_ver\($flavor\)")) {
      print "\nWarning: custom folders not exist, will auto download it from CC.\n";
      &copy_BB if ($ENV{'MTK_INTERNAL'} eq 'TRUE');
    }
  } else {
    if (!-d "custom\\system\\$board_ver") {
      print "\nWarning: custom folders not exist, will auto download it from CC.\n";
      &copy_BB if ($ENV{'MTK_INTERNAL'} eq 'TRUE');
    }
  }
  print "mmi_version: $mmi_version\n";
  if ($mmi_version eq "WISDOM_MMI") {
    if (!-d "external_mmi\\wise") {
      &copy_WisdomMMI if ($ENV{'MTK_INTERNAL'} eq 'TRUE');
    }
    if (!-d "external_mmi\\wise\\wise_headers\\$board_ver") {
      &copy_WisdomMMI($board_ver) if ($ENV{'MTK_INTERNAL'} eq 'TRUE');
    }
  }
}

# Output MMI_VERSION for MCT.
system "echo MMI_VERSION=$mmi_version>mct.ini";


# Check if the node-locked license still works.
$LICENSE_FILE = $BM_conf{'NODELOCKED_LICENSE'}->{'LICENSE_FILE'};
$ARM_COMPILER = $BM_conf{'NODELOCKED_LICENSE'}->{'ARM_COMPILER'};
print "LICENSE_FILE: $LICENSE_FILE, ARM_COMPILER: $ARM_COMPILER\n";
$nodelock_fail = 0;
if (-e "license_check\.log") {
  system("del /Q license_check\.log");
}
if (($ENV{'MTK_INTERNAL'} eq 'TRUE') && ($ENV{"USERDOMAIN"} =~ /MTK/i) && (-e "$LICENSE_FILE")) {
  $orig_ARMLMD_LICENSE_FILE = $ENV{"ARMLMD_LICENSE_FILE"};
  $ENV{"ARMLMD_LICENSE_FILE"} = $LICENSE_FILE;
  system("$ARM_COMPILER 2>license_check.log");
  system("echo COMPUTERNAME=$ENV{COMPUTERNAME}>>license_check.log");
  open(license_check_file, "license_check.log") or die "Cannot open license_check.log";
  $backup = $/;
  undef $/;
  $log_content = <license_check_file>;
  $/ = $backup;
  if ($log_content =~ /FLEXlm error:/i) {
    $nodelock_fail = 1;
  }
  close(license_check_file);

  if ($nodelock_fail == 1) {
    $email_list = $BM_conf{'NODELOCKED_LICENSE'}->{'MAIL_LIST'};
    $smtp = Net::SMTP->new('smtp.mediatek.inc');
    $smtp->mail($curr_usr);
    map { $smtp->recipient($_); } split(/,/, $email_list);
    $smtp->data();
    $smtp->datasend("Subject:[ERROR: Nodelocked License Failed on $ENV{COMPUTERNAME}].\n");
    $smtp->datasend("$log_content\n\n");
    $smtp->quit;
  }
  $ENV{"ARMLMD_LICENSE_FILE"}=$orig_ARMLMD_LICENSE_FILE;
}
else
{
  print "ENV{'MTK_INTERNAL'}: $ENV{'MTK_INTERNAL'}\n";
}

print "ENV{COMPUTERNAME}: $ENV{COMPUTERNAME}\n";
if ($ENV{COMPUTERNAME} =~ /mtks(cf|ib)/i) {
  $m_in_lsf = 1;
}

print "bypassMoDIS: $bypassMoDIS\n";    # 0
if ($bypassMoDIS > -1)
{
  $bypassMoDIS = int(eval($strBypassMoDIS));
}
print "bypassMoDIS: $bypassMoDIS\n";    # 0

print "run_flavor_conf: $run_flavor_conf\n"; # 0
if ($run_flavor_conf == 1)
{
  # workaround for flavor and AAPMC
  #$target_option .= " RUN_FLAVOR_CONF=AUTO";
  $ENV{"RUN_FLAVOR_CONF"} = "AUTO";
}

print "check_dep: $check_depend\n";     # 0
if ($check_depend)
{
	$target_option .= " AUTO_CHECK_DEPEND=TRUE";
	if ($action !~ /^(new|bm_new|new_modis)$/i)
	{
		die "-smart can only work with new/bm_new/new_modis";
	}
	my $res = system("perl tools\\ChkDepMod.pl --step 0 $custom $project $platform") >> 8;
	if ($ENV{'MTK_INTERNAL'} eq 'TRUE')
	{
		if ($not_enter_lsf || $m_in_lsf || $local_q)
		{
		}
		else
		{
			# decide bsub queue
			$check_depend = $res;
		}
	}
}

if (($m_in_lsf == 0) && ($not_enter_lsf != 1))
{
  print "m_in_lsf: $m_in_lsf, not_enter_lsf $not_enter_lsf\n";    # 0, NONE
  if ($action =~ /^(bm_new|bm_update|bm_remake)$/i)
  {
    system("${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project $target_option mmi_feature_check") && exit 1;
  }
  if (($action =~ /^(bm_new|new|rel|ck3rdptylic)$/i) && ($demo_project eq "FALSE"))
  {
    # action: new, demo_project: FALSE
    print "action: $action, demo_project: $demo_project\n";
    # tools\make.exe  -fmake\gsm2.mak -r -R CUSTOMER=ULTRA2503A_11C PROJECT=gprs ck3rdptylic
    print "${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project ck3rdptylic\n";
    system("${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project ck3rdptylic") && exit 1;
  }
  if (($action =~ /new/i) && ($action !~ /new_viti/i) && ($ENV{"SESSIONNAME"} ne "") && ($ENV{"LSF_BINDIR"} ne "") && ($project !~ /BASIC/i) && ($project !~ /L1S/i) && ($project !~ /UDVT/i) && ($ENV{'MTK_INTERNAL'} eq 'TRUE') && ($check_depend != 2))
  {
    chomp($cwd = `cd`);
    if ($cwd =~ /^[abg-z]/i) {
      &pre_gen() if (($pureMoDIS == 1) || ((lc($action) ne "new_modis") && (lc($action) ne "new_uesim")));
      $env_last_S_CF = "";
      $lastSC = "LAST_S_C.bat";
      if ((-e $lastSC) && (open(LOGF, "${lastSC}"))) {
        while (<LOGF>) {
          if (/set LAST_SUBMITTED_CF=(\S+)/) {
            $env_last_S_CF = $1;
            last;
          }
        }
        close(LOGF);
      }
#    $ENV{"NUMBER_OF_PROCESSORS"} = 1;
      if ($mbis_en eq "TRUE")
      {
        $mbis_time = time;
        system("echo T_S,DISPATCH_CF,P,$mbis_time >>$ENV{MBIS_BUILD_TIME_TMP}");
      }
      my $result = 0;
      if ($env_last_S_CF eq "") {
        $result = system("bsub -I \"perl $net_path\\m_cp2lsf.pl\" \"$net_path\" @orgARGV");
      } else {
        if (($output = `bhosts ${env_last_S_CF} mtkcf 2>&1`) =~ / Bad host name, host group name or cluster name/)
        {
          $result = system("bsub -I \"perl $net_path\\m_cp2lsf.pl\" \"$net_path\" @orgARGV");
        }
        else
        {
          $result = system("bsub -I -m \"${env_last_S_CF}+2 mtkcf+1\" \"perl $net_path\\m_cp2lsf.pl\" \"$net_path\" @orgARGV");
        }
      }
      &writeINI;
      exit $result >> 8;
    } else {
      # make new in local E: driver
      if (($ENV{"SESSIONNAME"} ne "") && ($ENV{"LSF_BINDIR"} ne "") && ($compiler eq "RVCT") && ($ENV{'MTK_INTERNAL'} eq 'TRUE')) {
        &localq;
      }
    }
  } else {
    if (($action !~ /ckmake|ck3rdptylic|check|notify|patch|patch_hal|modis|uesim|sysgen|sys_auto_gen|emigen|nvram_auto_gen|xml_parser|find|rel|cmmgen|removecode|ckcr|elfpatch|codegen|gendsp|viewlog|genmoduleinfo|gen_bt_switch_info|viti|genmakefile/ig) || ($action =~ /mmi_feature_check/i)) {
      print "action: $action, check position\n";
      if (($ENV{"SESSIONNAME"} ne "") && ($ENV{"LSF_BINDIR"} ne "") && ($compiler eq "RVCT") && ($ENV{'MTK_INTERNAL'} eq 'TRUE') && ($check_depend != 3)) {
        $local_path = "";
        $current_path=Win32::GetCwd();
        if($current_path=~/^([A-CG-Z]:)(.*)/i)
        {
          my $tmp_string1=$1;
          my $tmp_string2=$2;
          my @tmp_str2=`net use $tmp_string1`;
          my ($tmp_str3)=($tmp_str2[1]=~/\s+(\\\\.*)\s*$/);
          $net_path = lc("\\\\".$ENV{"COMPUTERNAME"}."\\E\\home");
          $tmp_str3=lc($tmp_str3);
          if ($tmp_str3 eq $net_path) {
            $local_path = "E:\\home\\$tmp_string2";
            chdir("E:\\home\\$tmp_string2");
          }
        }
        if ($local_path ne "") {
          &localq($local_path);
        }else{
          &localq();
        }
      }
    }
  }
}


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

if (($action ne "ckmake") && ($action ne "mmi_feature_check") && ($action ne "ck3rdptylic")) {
  # Before executing actions, dump environment information to the build.log
  print "action: $action\n";
  if (!-d ".\\build\\${custom}") {
    system("md .\\build\\${custom}");
  }
  if(-e ".\\SubReleaseConfig.ini")
  {
  	print "copy .\\SubReleaseConfig.ini .\\build\\${custom}";
  	system("copy .\\SubReleaseConfig.ini .\\build\\${custom}");
  }
  system("perl -e \"print \'BUILD START TIME=\'\";>>.\\build\\${custom}\\build.log");
  system("perl tools\\time.pl -n>>.\\build\\${custom}\\build.log");
  system("echo NUMBER_OF_PROCESSORS=$ENV{\"NUMBER_OF_PROCESSORS\"} >>.\\build\\${custom}\\build.log");
  system("echo BUILD_MACHINE=%COMPUTERNAME% >>.\\build\\${custom}\\build.log");
  &mbis_info_probe;
}

# check current working folder length
# if it is too long, it will cause build error. The max length is defined 90 characters.
chomp($cwd = `cd`);
$len = length($cwd);
$folder_limit = 90;
print "len: $len, folder_limit: $folder_limit\n";
if($len > $folder_limit)
{
		if ($cwd =~ /.+\\(.+)/) {
		  $folder_name = $1;
		}
		print "Folder: $cwd\n";
		print "Error: The folder length from $folder_name($len characters) exceeds $folder_limit characters. Please reduce folder lengths!\n";
		exit 1;
}

my $AAPMCLOG = "AAPMC.log";
system("del /f /q $AAPMCLOG")if(-e "$AAPMCLOG");

my $result = 0;
my %saw;
@theAct = grep (!$saw{$_}++, @theAct);
print "theAct: @theAct\n";
foreach my $action (@theAct) {
  $ENV{"ACTION"} = $action;
  if ($action ne "ckcr") {
    print "action: $action\n";
    system("$delCmd ${makeFolder}~*.tmp *.d > nul 2>&1");
    system("echo CUSTOMER=$custom > ${makeFolder}~buildinfo.tmp");
    system("echo PROJECT=$project >> ${makeFolder}~buildinfo.tmp");
    system("echo APLAT=$plat >> ${makeFolder}~buildinfo.tmp");
    system("echo $fullOpts >> ${makeFolder}~buildinfo.tmp");   
    my $timeStr = &CurrTimeStr;
    system("echo BUILD_DATE_TIME=$timeStr>> ${makeFolder}~buildinfo.tmp");
    my $dbg_timeStr = $timeStr;
    $dbg_timeStr =~ s/ /_/g;
    $dbg_timeStr =~ s/:/_/g;
    $dbg_timeStr =~ s/\//_/g;
    # mbis options
    system("echo MBIS_EN=$mbis_en >> ${makeFolder}~buildinfo.tmp");
    system("echo MBIS_EN_OBJ_LOG=$mbis_en_obj_log >> ${makeFolder}~buildinfo.tmp");
    system("echo DBG_BUILD_DATE_TIME=$dbg_timeStr >> ${makeFolder}~buildinfo.tmp");
    system("echo REMOVE_DEBUG_INFO=RHR>> ${makeFolder}~buildinfo.tmp") if ($rmdebug == 1);
    system("echo NO_PCIBT=$no_pcibt >> ${makeFolder}~buildinfo.tmp");
  }

  if ($action =~ /\b(clean)_(modis|uesim)\b/) {
    if ($#arguments != -1) {
      system("echo DO_CLEAN_MODULE=TRUE > ${makeFolder}~cleanmod.tmp");
      system("echo CLEAN_MODS=@arguments >> ${makeFolder}~cleanmod.tmp");
    }
  }
  if ($action eq "clean") {
    if ($#arguments != -1) {
      system("echo DO_CLEAN_MODULE=TRUE > ${makeFolder}~cleanmod.tmp");
      system("echo CLEAN_MODS=@arguments >> ${makeFolder}~cleanmod.tmp");
      system("${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project cleanmod");
    } else {
      system("echo DO_CLEAN_MODULE=FALSE > ${makeFolder}~cleanmod.tmp");
      system("${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project cleanall");
    }
  } elsif (($action eq "remake") || ($action =~ /\b(remake)_(modis|uesim)\b/)) {
    if ($#arguments != -1) {
      system("echo DO_REMAKE_MODULE=TRUE > ${makeFolder}~remakemod.tmp");
      system("echo REMAKE_MODS=@arguments >> ${makeFolder}~remakemod.tmp");
    }
  } elsif (($action eq "update") || ($action =~ /\b(gen|update)_(modis|uesim)\b/)) {
    if ($#arguments != -1) {
      system("echo DO_UPDATE_MODULE=TRUE > ${makeFolder}~updatemod.tmp");
      system("echo UPDATE_MODS=@arguments >> ${makeFolder}~updatemod.tmp");
    }
  } elsif (($action eq "scan") || ($action =~ /\b(scan)_(modis|uesim)\b/)) {
    if ($#arguments != -1) {
      system("echo DO_SCAN_MODULE=TRUE > ${makeFolder}~scanmod.tmp");
      system("echo SCAN_MODS=@arguments >> ${makeFolder}~scanmod.tmp");
    }
  } elsif (($action eq "new") || ($action eq "bm_new") || ($action eq "codegen") || ($action =~ /_(modis|uesim)\b/)) {
    # empty here to run through BT switch
    print "empty here to run through BT switch\n";
  } elsif ($action eq "mtegen") {
    $result = &MoDIS_build_process($action);
  } elsif ($action eq "check_scan") {
    if ($#arguments != -1) {
      system("echo DO_SCAN_MODULE=TRUE > ${makeFolder}~scanmod.tmp");
      system("echo SCAN_MODS=@arguments >> ${makeFolder}~scanmod.tmp");
    }
    system("${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project CHECK_SCAN=TRUE scan");
  } elsif ($action eq "check") {
    system("perl ${toolsFolder}parse_comp_err.pl $custom");
  } elsif ($action eq "notify") {
    system("perl ${MTKtoolsFolder}notify_err.pl $custom $project bm_notify");
  } elsif ($action eq "warn_notify") {
    system("perl ${MTKtoolsFolder}notify_err.pl $custom $project warn_notify");
  } elsif ($action eq "cq_notify") {
    system("perl ${MTKtoolsFolder}notify_err.pl $custom $project cq_notify");  
  } elsif ($action eq "err_out") {
    system("perl ${MTKtoolsFolder}notify_err.pl $custom $project err_out");
  } elsif ($action eq "db_notify") {
    system("perl ${MTKtoolsFolder}notify_err.pl $custom $project db_notify");
  } elsif ($action eq "db_modis_notify") {
    system("perl ${MTKtoolsFolder}notify_err.pl $custom $project db_modis_notify");
  } elsif ($action eq "patch") {
    system("perl ${MTKtoolsFolder}patch_file.pl $custom $project @arguments");
  } elsif ($action eq "patch_hal") {
    system("perl ${MTKtoolsFolder}patch_tool_HAL.pl $custom $project @arguments");
  } elsif ($action eq "find") {
    system("cqperl ${MTKtoolsFolder}find_file.pl $theMF $theVerno @arguments");
  } elsif ($action eq "at") {
    &atTarget("$custom $project $mmi_version @arguments");
  } elsif ($action eq "at_rel") {
    &rel_atTarget_BM(@arguments);
  } elsif ($action eq "rm_cleanroom") {
    &rm_cleanroom();
  } elsif ($action eq "check_dep") {
    	&Usage if (!@arguments);
    	&writeINI;
    	system("perl tools\\GetDepMod.pl .\\ $custom $project  @arguments") && exit 1;
    	exit 0;
  } elsif ($action =~ /update_dep|remake_dep/i) {
    	&Usage if (!@arguments);
    	print "Scanning dependency modules...\n";
    	my $output;
    	if (($output = `perl tools\\GetDepMod.pl .\\ $custom $project @arguments 2>&1`) =~ /=+DEPENDENCY MODULE\(S\)=+\n(.*)\n/)
    	{
    		@arguments = split(/\s+/,$1);
    		$action = "update" if ($action eq "update_dep");
    		$action = "remake" if ($action eq "remake_dep");
    		print "The following module(s) will be rebuilt!\n";
    		print "===========================================================\n";
    		print "@arguments","\n";
    		print "===========================================================\n";
    		redo; # redo to generate ${makeFolder}~remakemod.tmp
    	}
    	else
    	{
    		print $output;
    		&writeINI;
    		exit 1;
    	}
  } elsif ($action =~ /_viti/i) {
    $result = system("perl ${MTKtoolsFolder}build_viti.pl $custom $project $theMF $action @arguments");
    exit 1 if($result != 0);
  } elsif ($action eq "viewlog") {
    my $logDir = ".\\build\\${custom}\\log";
    die "$logDir does NOT exist\n" if (!-d $logDir);
    if ($#arguments != -1) {
      foreach my $argu (@arguments) {
        if (-e "${logDir}\\${argu}.log") {
          system("start ${logDir}\\${argu}.log");
        } elsif (-e "${logDir}\\${argu}_classb.log") {
          system("start ${logDir}\\${argu}_classb.log");
        } else {
          warn "${logDir}\\${argu}.log does NOT exist\n";
        }
      }
    } else {
      while ($argu = <$logDir\\*.log>) {
        system("start ${argu}") if (-e "${argu}");
      }
    }
  } elsif ($action eq "rel") {
    #(!-e $disFile) && (die "$disFile does NOT exist!\nPlease help to check.\n");
    if (!-e $enFile) {
      warn "$enFile does NOT exist!\nCreate an EMPTY $enFile\n";
      sleep 2;
      system "copy /y nul $enFile > nul";
    }
    system("echo LEVEL=$level >> ${makeFolder}~buildinfo.tmp");
    system("echo DUMMYVM=TRUE >> ${makeFolder}~buildinfo.tmp") if ($dummyvm == 1);
    $result = system("$makeCmd -f${makeFolder}custom_release.mak custom_release -r -R CUSTOMER=$custom PROJECT=$project RELEASE_DIR_O=$relDir LEVEL=$level");
    &writeINI;
    exit 1 if ($result);
    exit 0;
  } elsif ($action eq "ckcr") {
    if(-e "error") {
      system("del /Q error");
    }
    if(-e "ckrelpkg.log") {
      system("del /Q ckrelpkg.log");
    }
    system("$makeCmd -f${makeFolder}custom_release.mak -r -R CUSTOMER=$custom PROJECT=$project RELEASE_DIR_O=$relDir LEVEL=$level ckcr 2>error");    
    if ( $package !~  /REL_SUB_UAS_/i )    
    {        
      system("perl mtk_tools\\ckrelpkg.pl NONE $theVerno TRUE $custom>>error");
    }  
    if (-e "error") {
      open(preCR,"<error") || die "Cannot not open custom release pre-check log:$!\n";
      my $crlf = $/;
      undef $/;
      my $errorContent = <preCR>;
      $/ = $crlf;
      close preCR;
      if (($errorContent =~ /\*\*\*/) || ($errorContent =~ /Error:/i)) {
      	print "\nCustom Release script check error\n\n";
      	print "$errorContent\n";
      	exit 1;
      }
    }
  } elsif ($action eq "removecode") {
    print "${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project REMOVE_DIR=$remove_dir $action";
    system("${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project REMOVE_DIR=$remove_dir $action");
  } elsif ($action eq "genmakefile") {
    die "Lack off -bootup parameter. Please check \"-bootup=XXX\" with FACTORY or MAUIONLY or COMBINE options.\n" if($bootup_arg !~ /factory|mauionly|combine/i);
    print "Generating makefile for $bootup_arg...\n";
    $custom_tmp = $custom;
    if(${custom} =~ /(.+)\_(FACTORY|MAUIONLY|COMBINE)$/i) {
     $custom_tmp = $1;
    }
    $result = system("perl tools\\factory_feature_check.pl make\\${custom_tmp}_${project}.mak tools\\factory_option.mak $bootup_arg $custom_release > .\\make\\factory_feature.log");
    if($result == 0){
      print "copy /y $theVerno ${makeFolder}Verno_${custom_tmp}_${bootup_arg}.bld \n";
      system("copy /y $theVerno ${makeFolder}Verno_${custom_tmp}_${bootup_arg}.bld > nul");
    }
  } elsif (($action eq "gendoc") && ($#arguments != -1)) {
    system("echo DO_GENDOC_MODULE=TRUE > ${makeFolder}~gendocmod.tmp");
    system("echo GENDOC_MODS=@arguments >> ${makeFolder}~gendocmod.tmp");
  } elsif ($action eq "rmdebugobj") {
    system("${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project $action");
  } else {
    if ($action !~ /^ckmake$/i) {
      $result = system("${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project $target_option ckmake");
      die "Error: ckmake failed!!!\n" if($result != 0);
    }
    $result = system("${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project $target_option $action");
    if ($action eq "resgen"){
      #mbis end probe
      if ($result == 0) {
        &mbis_success if ($mbis_en eq "TRUE");
      }
    }
    if(-e $AAPMCLOG){
      print "perl tools\\ChkDepMod.pl --step 2 $custom $project $platform\n";
      $ckdepmod = system("perl tools\\ChkDepMod.pl --step 2 $custom $project $platform > build\\${custom}\\log\\ChkDepMod_2.log 2>&1");
      die "Error: tools\\ChkDepMod.pl failed. Please check build\\${custom}\\log\\ChkDepMod_2.log for more details.\n"  if ($ckdepmod != 0);
    }
     if($result != 0) {
    	&error_handle;
    } else{
    	if (($custom_release eq "FALSE") && ($ENV{'MTK_INTERNAL'} eq 'TRUE') && (-e "mtk_tools\\Internal_function.pm")) {
        $result = &AAPMC::Parse_AAPMCLog($AAPMCLOG,$custom,$project);
        die "AAPMC parser Error!!!\n" if ($result != 0)
    	}
    }
    next;
  }

  if (($action eq "remake") || ($action eq "update") || ($action eq "new") || ($action eq "bm_new") || ($action eq "scan") || ($action eq "codegen") || ($action =~ /^new_(modis|uesim)$/i)) {
    # tools\make.exe  -fmake\gsm2.mak -r -R CUSTOMER=ULTRA2503A_11C PROJECT=gprs  ckmake
    print "${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project $target_option ckmake\n";
    $result = system("${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project $target_option ckmake");
    die "Error: ckmake failed!!!\n" if($result != 0);
  }
  print "make ckmake action###########################zengjf################################ \n";
  if (($action eq "remake") || ($action eq "update") || ($action eq "new") || ($action eq "bm_new") || ($action eq "scan")) {
    if ($action eq "bm_new") {
      system("echo BM_NEW=TRUE >> ${makeFolder}~buildinfo.tmp");
      #Add for daily build
      if ($daily_build){
        system("echo DAILY_BUILD=TRUE >> ${makeFolder}~buildinfo.tmp");
      }
      $result = system("${makeCmd} -f${makeFolder}${myMF} -k -r -R CUSTOMER=$custom PROJECT=$project $target_option new");
    } else {
      # tools\make.exe  -fmake\gsm2.mak -r -R CUSTOMER=ULTRA2503A_11C PROJECT=gprs  new
      # 这一部分要编译将近1个小时，这里也基本上是编译的最后一部分了
      print "${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project $target_option $action\n";
      $result = system("${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project $target_option $action");
    }
    print "make new aciton###########################zengjf################################ \n";
    if(-e $AAPMCLOG){
      $ckdepmod = system("perl tools\\ChkDepMod.pl --step 2 $custom $project $platform > build\\${custom}\\log\\ChkDepMod_2.log 2>&1");
      die "Error: tools\\ChkDepMod.pl failed. Please check build\\${custom}\\log\\ChkDepMod_2.log for more details.\n"  if ($ckdepmod != 0);
    } 
    else
    {
      print "AAPMCLOG: $AAPMCLOG is not exist";
        
    }
    if ($result == 0) {
    	if (($custom_release eq "FALSE") && ($ENV{'MTK_INTERNAL'} eq 'TRUE') && (-e "mtk_tools\\Internal_function.pm")) {
        $result = &AAPMC::Parse_AAPMCLog($AAPMCLOG,$custom,$project);
        die "AAPMC parser Error!!!\n" if ($result != 0)
    	}
      &rel_atTarget if ($action =~ /^(new|bm_new|remake|update)$/i);
      &mbis_success if ($mbis_en eq "TRUE");
    } else {
      &error_handle;
    }
    last if ($mbis_target_build_with_Modis != 1);
  } elsif ($action =~ /_(modis|uesim)\b/) {
    $result = &MoDIS_build_process($action);
  } elsif ($action eq "codegen") {
    $result = system("${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project $target_option code_generate");
    #mbis end probe
    if ($result == 0) {
      &mbis_success if ($mbis_en eq "TRUE");
    }
  }
  if ($result != 0) {
    system("perl $mbis -i SUCCESSFUL_BUILD,0") if ($mbis_en eq "TRUE");
    print "Failed in $action\n";
    last;
  }
}
&writeINI;
print "writeINI $writeINI, check_depend: $check_depend\n";
if ($check_depend)
{
  my $res = system("perl tools\\ChkDepMod.pl --step 1 $custom $project $platform");
}
if (($m_in_lsf != 1) && ($mbis_target_build_with_Modis == 1))
{
  &mbis_end_probe;
}
#die "make2.pl\n" if ($result != 0);
print "exit command before\n";
exit $result >> 8;
print "exit command after\n";

sub MoDIS_build_process
{
	my $modis_action = shift @_;
	my $modis_result = 0;
	if ($bypassMoDIS < 1)
	{
		system("perl $mbis -t T_S,M_TOTAL,M_P") if ($mbis_en eq "TRUE");
		my $modis_option = $target_option;
		$modis_option .= " MODIS_CONFIG=TRUE";
		if (($modisDir ne "") && ($modisDir ne "undef")) {
			$modis_option .= " MODIS_MODE=$modisDir";
		} else {
			$modisDir = "undef";
		}
		$modis_action =~ s/\b(bm)_//ig;
		if ($modis_action =~ /_uesim\b/) {
			$modis_action =~ s/_uesim\b/_modis/g;
			$modis_option .= " MODIS_UESIM=UESim";
		}
		my $modis_cwd = `cd`;
		chomp($modis_cwd);
		my $modis_subst = "";
		if (($modis_action !~ /^(gen|clean|ap|at)_(modis|uesim)$/i) && ($modis_action ne "mtegen")) {
			foreach my $disk (k..z) {
				if (system("subst $disk: $modis_cwd >NUL 2>&1") == 0) {
					$modis_subst = $disk;
					last;
				}
			}
			if ($modis_subst ne "") {
				print "MoDIS subst disk for $modis_cwd is $modis_subst:\n";
				chdir("$modis_subst:");
			} else {
				warn "Warning: Execute subst for MoDIS fail !\n";
			}
		}
		if ($modis_action ne "at_modis")
		{
			$modis_action = "new $modis_action" if ($pureMoDIS == 1);
			$modis_result = system("${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project $modis_option $modis_action");
		}
		chdir("$modis_cwd");
		system("subst $modis_subst: /D >NUL") if ($modis_subst ne "");
		if ($modis_result == 0)
		{
			if ($modis_action =~ /\b(new|remake|update)_(modis|uesim)\b/) {
				system("perl $mbis -i SUCCESSFUL_BUILD,1") if ($mbis_en eq "TRUE");
				#rel_atMoDIS
			}
			if (($modis_action eq "at_modis") || ($atMoDIS == 1))
			{
				chdir("$modis_cwd\\MoDIS_VC9");
				$modis_result = system("perl modisAutoTest.pl at_modis $modisDir ..\\$theMF ..\\$theVerno");
				chdir("$modis_cwd");
			}
		}
		system("perl $mbis -t T_E,M_TOTAL,M_P") if ($mbis_en eq "TRUE");
	} else {
		print "Skip $modis_action for MoDIS\n";
	}
	return $modis_result;
}

#usage:
#      my %hash=iniToHash('/tmp/myini.ini');
#      print $hash{'TITLE'}->{'Name'},"\n";
#
sub iniToHash {
  open(MYINI, $_[0]);
  my %hash;
  my $hashref;

  while(<MYINI>)
  {
    next if ((/^\s*$/) || (/^\s*#/));
    if (/^\s*\[(.+)\]/)
    {
      $hashref = $hash{$1} ||= {};
    }
    elsif (/^\s*(\S+)\s*=\s*(.+)\s*$/)
    {
      $hashref->{$1} = $2;
    }
    elsif (/^\s*(\S+)\s*\+=\s*(.+)\s*$/)
    {
      $hashref->{$1} = $hashref->{$1} . " $2";
    }
  }

  close MYINI;
  return %hash;
}

sub copy_BB {
  if (-e "\\\\glbfs14\\WCP\\sw_releases\\3rd_party\\Scripts\\copy_BB\\copy_BB.pl")
  {
  	system("perl \\\\glbfs14\\WCP\\sw_releases\\3rd_party\\Scripts\\copy_BB\\copy_BB.pl $theMF $theVerno");
  }
}

sub copy_WisdomMMI {
  if (-e "\\\\glbfs14\\WCP\\sw_releases\\3rd_party\\Scripts\\copy_WisdomMMI\\copy_WisdomMMI.pl") {
    if (defined $_[0]) {
      system("perl \\\\glbfs14\\WCP\\sw_releases\\3rd_party\\Scripts\\copy_WisdomMMI\\copy_WisdomMMI.pl $theMF $theVerno $_[0]");
    } else {
       system("perl \\\\glbfs14\\WCP\\sw_releases\\3rd_party\\Scripts\\copy_WisdomMMI\\copy_WisdomMMI.pl $theMF $theVerno");
    }
  }
}

sub rel_atTarget {
  my @script_path = qw(
     \\\\mtkrs12\\Software_Management_Material\\Script\\3rd_party\\Scripts\\Target_AutoTest\\rel_atTarget.pl
     \\\\mtkrfs01\\Public1\\3rd_party\\Scripts\\Target_AutoTest\\rel_atTarget.pl
     \\\\glbfs14\\WCP\\sw_releases\\3rd_party\\Scripts\\Target_AutoTest\\rel_atTarget.pl
   );
   
   foreach (@script_path)
   {
     next if (!-e);
     system("perl $_ $theMF");
     last;
   }
}

sub rel_atTarget_BM {
  my @script_path = qw(
     \\\\mtkrs12\\Software_Management_Material\\Script\\3rd_party\\Scripts\\Target_AutoTest\\rel_atTarget_BM.pl
     \\\\mtkrfs01\\Public1\\3rd_party\\Scripts\\Target_AutoTest\\rel_atTarget_BM.pl
     \\\\glbfs14\\WCP\\sw_releases\\3rd_party\\Scripts\\Target_AutoTest\\rel_atTarget_BM.pl
   );
   
   foreach (@script_path)
   {
     next if (!-e);
     system("perl $_ $theMF $_[0]");
     last;
   }
}

sub atTarget {
  my $args        = $_[0];
  my @script_path = qw(
       \\\\mtkrfs05\\Public2\\atTarget_tools\\at_main.pl
       \\\\mtkrs12\\Software_Management_Material\\Script\\3rd_party\\Scripts\\Target_AutoTest\\at_main.pl
       \\\\mtkrfs01\\Public1\\3rd_party\\Scripts\\Target_AutoTest\\at_main.pl
       \\\\glbfs14\\WCP\\sw_releases\\3rd_party\\Scripts\\Target_AutoTest\\at_main.pl
     );
     
  if (-e "$cwd\\mtk_tools\\AutoTest\\at_main.pl")
  {
    system("perl $cwd\\mtk_tools\\AutoTest\\at_main.pl $args");
  }
  else
  {                   
    foreach (@script_path)
    {
      next if (!-e);
      system("perl $_ $args");
      last;
    }
  }
}

sub rm_cleanroom {
  my @script_path = qw(
       \\\\mtkrs12\\Software_Management_Material\\Script\\3rd_party\\Scripts\\rm_cleanroom\\rm_cleanroom.pl
       \\\\mtkrfs01\\Public1\\3rd_party\\Scripts\\rm_cleanroom\\rm_cleanroom.pl
       \\\\glbfs14\\WCP\\sw_releases\\3rd_party\\Scripts\\rm_cleanroom\\rm_cleanroom.pl
     );
                   
  foreach (@script_path)
  {
    next if (!-e);
    system("perl $_");
    last;
  }
}

sub CurrTimeStr {
  my($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
  return (sprintf "%4.4d/%2.2d/%2.2d %2.2d:%2.2d", $year+1900, $mon+1, $mday, $hour, $min);
}

sub cp_3rdpartyTool
{
	if ($ENV{'MTK_INTERNAL'} eq 'TRUE')
	{
		if (-e "tools\\thirdParties.pl")
		{
			print("perl tools\\thirdParties.pl -cp \n");
			system("perl tools\\thirdParties.pl -cp");
		}
		else
		{
			warn "tools\\thirdParties.pl does NOT exist!\n";	
			exit 1;
		}
	}
	else
	{
		warn "Lack off thirdParties tools!\n";	
		warn "Please refer to document: SOP_Third_Party_Package_Installation!\n";	
		exit 1;
	}
}

sub Usage {

  warn << "__END_OF_USAGE";

Usage:
  make ["customer"|"mt62xx"] "project" "action" ["modules"]|"file1[ file2[ ...]] | \@files"

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

  file1      = changed source/header's name (init\\include\\init.h, ...)
   => VALID ONLY when action is one of (check_dep remake_dep update_dep)
   => MANDATORY when action is one of (check_dep remake_dep update_dep) and \@files is NOT specified

  \@files     = Specify more changed sources/headers via a file (change list)
   => VALID ONLY when action is one of (check_dep remake_dep update_dep)
   => MANDATORY when action is one of (check_dep remake_dep update_dep) and file1 is NOT specified

Example:
  make gsm new                         (MT6205B EVB new)
  make gprs codegen                    (MT6218B EVB codegen)
  make mt6219 gprs update              (MT6219 EVB update)
  make firefly17_demo gprs new
  make milan_demo gprs c,u init custom
  make mt6219 gprs r init custom drv
  make mt6229 gprs check_dep init\\include\\init.h
  make mt6229 gprs remake_dep \@make\\init\\init.lis
  make mt6229 gprs update_dep init\\src\\init.c
__END_OF_USAGE

  exit 1;
}

sub writeINI {
  @iniFields = qw(plat custom project);
  if ($plat eq "NONE") {$plat = ""; }
  if ($enINI == 1) {
    open (FILE_HANDLE, ">$ini") or die "cannot open $ini\n";
    foreach $m (@iniFields) {
      $value = $${m};
      print FILE_HANDLE "$m = $value\n";
    }
    close FILE_HANDLE;
  }
  if (($action ne "ckmake") && ($action ne "mmi_feature_check") && ($action ne "ck3rdptylic")) {
    system("echo LOCAL_MACHINE=%COMPUTERNAME% >>.\\build\\${custom}\\build.log");
    system("echo CUSTOM=$custom>>.\\build\\${custom}\\build.log");
    system("echo PLATFORM=$plat>>.\\build\\${custom}\\build.log");
    system("echo PROJECT=$project>>.\\build\\${custom}\\build.log");
    system("echo VERNO=$verno>>.\\build\\${custom}\\build.log");
    system("echo ARMLMD_LICENSE_FILE=%ARMLMD_LICENSE_FILE%>>.\\build\\${custom}\\build.log");
    system("echo COMMAND=make @orgARGV>>.\\build\\${custom}\\build.log");
    system("perl -e \"print \'BUILD END TIME=\'\";>>.\\build\\${custom}\\build.log");
    system("perl tools\\time.pl -n>>.\\build\\${custom}\\build.log");
    $time_num=time;
    #mbis end probe
    # to aviod be called twice when enable lsf 
    if (($m_in_lsf != 1)&&($mbis_target_build_with_Modis != 1))
    { 
      &mbis_end_probe;
    }
    #if (($ENV{'MTK_INTERNAL'} eq 'TRUE') && (-d "$BuildInfoServer")) {
      #system("copy /y .\\build\\${custom}\\build.log $BuildInfoServer\\$verno\_$time_num\.log >nul");
    #}
  }
}

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

sub copy_romizing
{
  my ($source, $destination, $rec) = @_;
  print "source=$source\n";
  print "destination=$destination\n";
  print "rec=$rec\n";
  if(-d "$source"){
    if(-e "$source\\$rec") {
      $timestamp_server = (stat("$source\\$rec"))[9];
      $timestamp_local = 0;
      if (-e "$destination\\$rec") {
        $timestamp_local = (stat("$destination\\$rec"))[9];
      }
      if ($timestamp_server > $timestamp_local) {
        print "copy \"$source\*\" to \"$destination\*\" ...\n";
        system("if exist \"$destination\*.c\" del /q \"$destination\*.c\"");
        system("if exist \"$destination\*.cpp\" del /q \"$destination\*.cpp\"");
        system("xcopy /e /Y \"$source\*\" \"$destination\*\" > nul");          
      }
    } else {
      print "$source\\$rec does not exist.\n";
      print "Please execute romizing first.\n";
      exit(1);
    }
  } else {
    print "$source does not exist.\n";
    print "Please execute romizing first.\n";
    exit(1);
  }
}

sub pre_gen
{
  print "pre gen\n";
  if(defined($level) && ($level =~ /VENDOR/i)){
    print "Skip pre_gen for vendor release.\n";
    return 0;
  }
  print "Before submitting into CF machines, pre-check the Makefile, sys_auto_gen\n";
  $ENV{"ACTION"} = "sys_auto_gen";
  system("$delCmd ${makeFolder}~*.tmp *.d > nul 2>&1");
  system("echo CUSTOMER=$custom > ${makeFolder}~buildinfo.tmp");
  system("echo PROJECT=$project >> ${makeFolder}~buildinfo.tmp");
  system("echo APLAT=$plat >> ${makeFolder}~buildinfo.tmp");
  my $timeStr = &CurrTimeStr;
  system("echo BUILD_DATE_TIME=$timeStr>> ${makeFolder}~buildinfo.tmp");
  my $dbg_timeStr = $timeStr;
  $dbg_timeStr =~ s/ /_/g;
  $dbg_timeStr =~ s/:/_/g;
  $dbg_timeStr =~ s/\//_/g;
  # mbis options
  system("echo MBIS_EN=$mbis_en >> ${makeFolder}~buildinfo.tmp");
  system("echo MBIS_EN_OBJ_LOG=$mbis_en_obj_log >> ${makeFolder}~buildinfo.tmp");
  system("echo DBG_BUILD_DATE_TIME=$dbg_timeStr>> ${makeFolder}~buildinfo.tmp");
  system("echo NO_PCIBT=$no_pcibt >> ${makeFolder}~buildinfo.tmp");
  $preTestResult = system("${makeCmd} -f${makeFolder}${myMF} -r -R CUSTOMER=$custom PROJECT=$project $target_option sys_auto_gen");
#  (&writeINI && exit 1) if ($preTestResult != 0);
  if ($preTestResult != 0) {
  	&writeINI;
  	exit 1;
  }
  print "Pass pre-check for Makefile and sys_auto_gen\n";
#  (exit 1) if ($preTestResult != 0);
#  print "Pass mtegen\n";
}

sub localq
{
  my ($islocalpath) = @_;
  my $result = 0;
  print "Check if localq is available .... ";
  system("del /q localq.log") if (-e "localq.log");
  #system("bjobs -u all -q localq >localq.log 2>nul");
  system("bhosts $ENV{\"COMPUTERNAME\"} >localq.log 2>nul");
  open(LOCALQ, "localq.log") || die "Can not open localq.log!";
  while (<LOCALQ>) {
  	next if ($_ =~ /HOST_NAME/ig);
  	$_ =~ /(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/ig;
  	$STATUS = $2;
  	$MAX = $4;
  	$NJOBS = $5;
  }
  close LOCALQ;
  if (($NJOBS < $MAX) && ($STATUS =~ /ok/ig)) {
    print "YES\n";
    print "Enter the local queue.\n";
    if (($action =~ /new/i) && (((lc($action) ne "new_modis") && (lc($action) ne "new_uesim")) || ($pureMoDIS == 1))) {
      &pre_gen();
    }
    if ($islocalpath ne "") {
      if ($RUN_KLOCWORK eq 1) {
        print "bsub -q localq -m $ENV{\"COMPUTERNAME\"} -I kwinject --detach Cgen.exe,DrvGen.exe -T kwinject.trace perl make2.pl -lsf -localq -localpath @orgARGV\n";
        $result = system("bsub -q localq -m $ENV{\"COMPUTERNAME\"} -I kwinject --detach Cgen.exe,DrvGen.exe -T kwinject.trace perl make2.pl -lsf -localq -localpath @orgARGV");
      } else {
        print "bsub -q localq -m $ENV{\"COMPUTERNAME\"} -I perl make2.pl -lsf -localq -localpath @orgARGV\n";
        $result = system("bsub -q localq -m $ENV{\"COMPUTERNAME\"} -I perl make2.pl -lsf -localq -localpath @orgARGV");
      }
    }else{
      if ($RUN_KLOCWORK eq 1) {
        print "bsub -q localq -m $ENV{\"COMPUTERNAME\"} -I kwinject --detach Cgen.exe,DrvGen.exe -T kwinject.trace perl make2.pl -lsf -localq @orgARGV\n";
        $result = system("bsub -q localq -m $ENV{\"COMPUTERNAME\"} -I kwinject --detach Cgen.exe,DrvGen.exe -T kwinject.trace perl make2.pl -lsf -localq @orgARGV");
      } else {
        print "bsub -q localq -m $ENV{\"COMPUTERNAME\"} -I perl make2.pl -lsf -localq @orgARGV\n";
        $result = system("bsub -q localq -m $ENV{\"COMPUTERNAME\"} -I perl make2.pl -lsf -localq @orgARGV");
      }
    }
    &writeINI;
    exit $result >> 8;
  } else {
    print "NO\n";
  }
}

sub gen_romizing
{ 
  my ($source, $make_name, $java_path)  = @_;
  my $is_regen  = 0;
  my $lib_mtime = 0;
    
  if (-e $source)
  {
    foreach (&list_dir($source))
    {
      $lib_mtime = &get_file_mYMD("$source\\$_") if (&get_file_mYMD("$source\\$_") > $lib_mtime);
    }
    my @romizing_checklist;
    push(@romizing_checklist, split(/[\r\n]+/, `robocopy $cwd\\j2me\\vm\\$java_path\\romizing\\src $cwd\\abcdef /S /MAXAGE:$lib_mtime /L /NS /NC /NDL /NJH /NJS /NP`));
    push(@romizing_checklist, split(/[\r\n]+/, `robocopy $cwd\\j2me\\vm\\$java_path\\romizing $cwd\\abcdef proguardConfig.txt *.mak *.pl /MAXAGE:$lib_mtime /L /NS /NC /NDL /NJH /NJS /NP`));
    foreach(@romizing_checklist)
    {
      if (/^\s*(\S+)/i)
      {
        $is_regen = 1;
        last;
      }
    }
  }
  else
  {
    $is_regen = 1;
  }
  
  if ($is_regen)
  {
    chdir("$cwd\\j2me\\vm\\$java_path\\romizing");
    system("call go32.bat $branch $make_name remake");
    chdir("$cwd");
    
    if ($ENV{"verno"})
    {
      system("echo set verno=> verno.bat");
      system("call verno.bat");
    }
  }
  
  print ("call rd /s /q $cwd\\j2me\\vm\\$java_path\\romizing\n");
  system("call rd /s /q $cwd\\j2me\\vm\\$java_path\\romizing");
  
  if ($ENV{"LSF_remote"})
  {
    print ("call rd /s /q " . $ENV{"LSF_remote"} . "\\j2me\\vm\\$java_path\\romizing\n");
    system("call rd /s /q " . $ENV{"LSF_remote"} . "\\j2me\\vm\\$java_path\\romizing");
  }
}

sub list_dir
{
  my $path  = $_[0];
  my @files = ();
  
  if (opendir(FILE, $path)) {
    foreach (readdir(FILE))
    {
      next if ($_ eq ".");
      next if ($_ eq "..");
      push @files, $_;
    }
    closedir(FILE);
  }
  
  return @files;
}

sub get_file_mYMD
{
  my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime((stat($_[0]))[9]);

  return sprintf("%04d%02d%02d", ($year + 1900), ($mon + 1), $mday);
}

sub get_net_path
{
  $current_path=Win32::GetCwd();

  if ($current_path=~/^([ABDG-Z]:)(.*)/i) {
    $disk = $1;
    $folder = $2;
    $folder =~ s/\\$//;
    @disk = `net use $disk`;
    if ($#disk != -1) {
      $disk[1]=~/\s+(\\\\.*)\s*$/;
      $path = $1.$folder;
    }else {
    	@disk = `subst`;
    	foreach $subdisk (@disk) {
    		$subdisk =~ s/\s*$//;
    		if($subdisk =~ /($disk.*)\s*\=\>\s*(.*)/i){
    			$subst_folder= $2;
    			$subst_folder =~ s/://;
    		}
    	}
    	if($subst_folder =~ /^UNC\\(.+)/) {
    		$path = "\\\\".$1;
    	} else {
    		if($subst_folder ne ""){
    		 $path = "\\\\".$ENV{"COMPUTERNAME"}."\\".$subst_folder.$folder;
    	  }else{
    		 $path = "\\\\".$ENV{"COMPUTERNAME"}."\\".$disk.$folder;
    	  }
    	}
    }
  } elsif ($current_path=~/^([CEF]):(.*)/i) {
    $disk = $1;
    $folder = $2;
    if ($ENV{"USERNAME"} =~ /wcxbm/ig) {
      $path = "\\\\".$ENV{"COMPUTERNAME"}."\\".$disk."\$\$".$folder;
    } else {
      $path = "\\\\".$ENV{"COMPUTERNAME"}."\\".$disk.$folder;
    }
  }
  $path =~ s/://g;
  print "path=$path\n";
  return $path;
}

sub mbis_start_probe
{
  my $mbis_log_folder;

  print "mbis_en: $mbis_en\n";
  if ($mbis_en eq "TRUE")
  {
    if (!defined($ENV{"MBIS_BUILD_TIME_TMP"}) || !defined($ENV{"MBIS_BUILD_TIME_LOG"}) || !defined($ENV{"MBIS_BUILD_INFO_LOG"}))
    {
      $mbis_log_folder = ".\\build" . "\\" . $custom . "\\" . "log" . "\\" . "mbis";
      if (!-d "$mbis_log_folder")
      {
         system("md $mbis_log_folder");
      }
      else
      {
        # delete last log file
        if ($mbis_en_save_log ne "TRUE")
        {
          system ("del /q $mbis_log_folder\\*.log");
          system ("del /q $mbis_log_folder\\*.tmp");
        }
      }

      if (!defined($ENV{MBIS_BUILD_TIME_TMP}))
      {
        $ENV{MBIS_BUILD_TIME_TMP} = $mbis_log_folder . "\\". $build_time_string . "_" . "mbis" . "_" . "time" . ".tmp";
        #set title of mbis time tmp file
        system("echo Time Stamp,Item Name,Type,Time>>$ENV{MBIS_BUILD_TIME_TMP}");
        system("echo T_S,TOTAL,A,$build_time_sec >>$ENV{MBIS_BUILD_TIME_TMP}");
      }

      if (!defined($ENV{MBIS_BUILD_TIME_LOG}))
      {
        $ENV{MBIS_BUILD_TIME_LOG} = $mbis_log_folder . "\\". $build_time_string . "_" . "mbis" . "_" . "time" . ".log";
        #set title of mbis time tmp file
        system("echo Item Name,Type,Start Time,End Time,Duration Time>>$ENV{MBIS_BUILD_TIME_LOG}");
      }

      if (!defined($ENV{MBIS_BUILD_INFO_LOG}))
      {
        $ENV{MBIS_BUILD_INFO_LOG} = $mbis_log_folder . "\\". $build_time_string . "_" . "mbis" . "_" . "info" . ".log";
        #set title of mbis time tmp file
        system("echo Information Name,Information Content>>$ENV{MBIS_BUILD_INFO_LOG}");
        system("echo BUILD_START_DATATIME,$build_time_string>>$ENV{MBIS_BUILD_INFO_LOG}");
      }
      system("perl $mbis -s @orgARGVwithFlavor");
    }
  }
  else
  {
    # MBIS_BUILD_TIME_TMP must not be null for makefile expand the command
    $ENV{MBIS_BUILD_TIME_TMP}=tmp;
    print "ENV{MBIS_BUILD_TIME_TMP}: $ENV{MBIS_BUILD_TIME_TMP}\n";
  }
}

sub mbis_info_probe
{
  print "mbis_en: $mbis_en\n";
  if ($mbis_en eq "TRUE")
  {
    if (($ENV{'MTK_INTERNAL'} eq 'TRUE') && (-e "$mbis_conf_file"))
    {
      %mbis_conf = iniToHash($mbis_conf_file);
      $pilot_bm_list = $mbis_conf{'INIT_CONF'}->{'BM_LIST'};
      if ($pilot_bm_list =~ /$ENV{USERNAME}/i)
      {
         system("perl $mbis -i BM_BUILD,1");
      }
      else
      {
         system("perl $mbis -i BM_BUILD,0");
      }
    }
    
    $cur_path=Win32::GetCwd(); 
    system("perl $mbis -i BUILD_MACHINE,$ENV{COMPUTERNAME}");
    system("perl $mbis -i BUILD_FOLDER,$cur_path");
    system("perl $mbis -i CUSTOM_RELEASE,$custom_release");
    if ($mbis_num_proc == 0)
    {
      $mbis_num_proc = $ENV{"NUMBER_OF_PROCESSORS"};
    }
    system("perl $mbis -i NUMBER_OF_PROCESSORS,$mbis_num_proc");
    system("perl $mbis -i LSF,$m_in_lsf");
    system("perl $mbis -i INCREDIBUILD,$mbis_incredibuild");
    system("perl $mbis -i COMPILER,$compiler");
    system("perl $mbis -i USER,$ENV{USERNAME}");
    system("perl $mbis -i PROJECT,$project");
    system("perl $mbis -i CUSTOM,$custom");
    system("perl $mbis -i FLAVOR,$flavor");
    system("perl $mbis -i VERNO,$verno");
    system("perl $mbis -i PLATFORM,$plat");
    system("perl $mbis -i PID,$$");
    if (-e "SubReleaseConfig.ini") 
    {
    	open (FILE_HANDLE, "<SubReleaseConfig.ini") or die "cannot open SubReleaseConfig.ini\n";
			while (<FILE_HANDLE>) {
  			if (/^(\w+)\s*=\s*(.*\S)\s*$/)
  			{
    			$keyname = $1;
    			$${keyname} = $2;
  			}
			}
			close FILE_HANDLE;
    	system("perl $mbis -i USR_SUPPORT,$USR_Support");
    	system("perl $mbis -i USR_PRODUCER,$USR_Producer");
    }
    else
    {
    	system("perl $mbis -i USR_SUPPORT,0");
    	system("perl $mbis -i USR_PRODUCER,0");
    }
    if (-e "dailybuild.txt") 
    {
    	system("perl $mbis -i DAILY_BUILD_PRODUCER,1");
    }
    else
    {
    	system("perl $mbis -i DAILY_BUILD_PRODUCER,0");
    }
    if (-e "ewsprebuild.txt") 
    {
    	system("perl $mbis -i EWS_PREBUILD_PRODUCER,1");
    }
    else
    {
    	system("perl $mbis -i EWS_PREBUILD_PRODUCER,0");
    }
  }
}

sub mbis_end_probe
{
  if ($mbis_en eq "TRUE")
  { 
    system("perl $mbis -e");
  }
}

sub mbis_parse_arg
{
  $mbis_arg_exist = 1;
  foreach $arg (@mbis_arg)
  {
    if ($arg =~ /^en_mbis$/i)
    {
      $arg_mbis_en = "TRUE";
    }
    elsif ($arg =~ /^dis_mbis$/i)
    {
      $arg_mbis_en = "FALSE";
    }
    elsif ($arg =~ /^dis_obj$/i)
    {
      $arg_mbis_en_obj_log = "FALSE";
    }
    elsif ($arg =~ /^en_obj$/i)
    {
      $arg_mbis_en_obj_log = "TRUE";      
    }
    elsif ($arg =~ /^save_log$/i)
    {
      $arg_mbis_en_save_log = "TRUE";
    }
    else
    {
      # with error command
      $mbis_arg_exist = 0;
      return ;
    }
  }

  if ($arg_mbis_en ne "TRUE")
  {
    $arg_mbis_en_obj_log = "FALSE";
    $arg_mbis_en_save_log = "FALSE";
  }

}

sub mbis_init
{
 
  print "ENV{'MTK_INTERNAL'}: $ENV{'MTK_INTERNAL'}\n";
  if (($ENV{'MTK_INTERNAL'} eq 'TRUE') && (-e "$mbis_conf_file"))
  {
    %mbis_conf = iniToHash($mbis_conf_file);
    $mbis_bm_list = $mbis_conf{'INIT_CONF'}->{'BM_LIST'};
    $mbis_project_list = $mbis_conf{'INIT_CONF'}->{'PROJECT_LIST'};
    @mbis_project_array=split /,/, $mbis_project_list;
    $mbis_en = $mbis_conf{'INIT_CONF'}->{'EN_ALL_PROJECT'};
    $mbis_en_obj_log = $mbis_conf{'INIT_CONF'}->{'EN_OBJ_LOG'};
    # force all project enable mbis
    # enable obj log for BM only
    if ($mbis_en eq "TRUE")
    {
      # check bm list
      if ($mbis_bm_list =~ /$ENV{USERNAME}/i)
      {
        $mbis_en = "TRUE";
        $mbis_en_obj_log = "TRUE";
      }
      else
      {
        $mbis_en = "TRUE";
        $mbis_en_obj_log = "FALSE";
      }
    }
    else
    {      
      # check with build user and project list if match
      $project_found = 0;
      if ((defined($flavor)) && ($flavor ne "NONE"))
      {
        foreach (@mbis_project_array)
        {
          $_ =~ /^(.*)_(.*)\((.*)\)/i;
          if ((uc($custom) eq uc($1)) && (uc($project) eq uc($2)) && (uc($flavor) eq uc($3)))
          {
            $project_found = 1;
          }
        }
      }
      else
      {
        foreach (@mbis_project_array)
        {
          $_ =~ /(.+)_(.+)/i;
          if ((uc($custom) eq uc($1)) && (uc($project) eq uc($2)))
          {
            $project_found = 1;
          }
        }
      }

      if (($mbis_bm_list =~ /$ENV{USERNAME}/i) && ($project_found == 1))
      {
        $mbis_en = "TRUE";
      }
      else
      {
        $mbis_en = "FALSE";
      }
    }

    # deal with mbis option from arg
    if ($mbis_en eq "TRUE")
    {
      system("echo MBIS init enable");
      if ($mbis_en_obj_log eq "TRUE")
      {
        system("echo MBIS obj log enable");
      }
 
      if ($mbis_arg_exist == 1)
      {
        $mbis_en = $arg_mbis_en;
        $mbis_en_obj_log = $arg_mbis_en_obj_log;
        $mbis_en_save_log = $arg_mbis_en_save_log;
        if ($mbis_en eq "TRUE")
        {
          system("echo MBIS arg enable");
        }
        else
        {
          system("echo MBIS arg disable");
        }
      }
    }
    else
    {
      $mbis_en_obj_log = "FALSE";
      $mbis_en_save_log = "FALSE";
      system("echo MBIS init disable");
    }
  }
}

sub mbis_success
{
  my $build_custom_folder;
  my @files;
  my $elfname;
  my $elfsize;
  # get elf size
  $build_custom_folder = "build\\$custom";
  opendir (DIR, $build_custom_folder) or die "no folder : $build_custom_folder";
  my @files = grep {/^$custom.*_$project.*\.elf$/}  readdir DIR;
  close DIR;
  if (@files == 1)
  {
    $elfname = pop @files;
    # add elf file name 
    system("perl $mbis -i ELF_FILE,$elfname");
    $elfsize = -s "$build_custom_folder\\$elfname";
    # add elf file size
    system("perl $mbis -i ELF_SIZE,$elfsize");
  }

  # add success flag
  system("perl $mbis -i SUCCESSFUL_BUILD,1");
}

sub CHANGE_FEATURE_VALUE
{
  my ($makefile, $feature_name, $feature_value) = @_;
  open (FILE_HANDLE, $makefile) or die "Cannot open $makefile\n";
  $reading="";
  while (<FILE_HANDLE>) {
    if (/^($feature_name)\s*=\s*(\S+)/) {
      $Original_value = $2;
      $_ =~ s/$Original_value/$feature_value/;
    }
    $reading .= $_;
  }
  close FILE_HANDLE;

  open (MAKEFILE, ">$makefile") or die "Cannot open $makefile\n";
  print MAKEFILE $reading;
  close MAKEFILE;
}

sub chk_vc9
{
	my $Register = "SOFTWARE\\Microsoft\\VCExpress\\9.0\\Setup\\VC";
	my ($key, $type, $data);
	RegOpenKeyEx(HKEY_LOCAL_MACHINE, $Register, 0, KEY_READ, $key) or return 0;
	if (RegQueryValueEx($key, "ProductDir", [], $type, $data, []))
	{
		if (($data ne "") && (-e $data))
		{
			return 1;
		}
	}
	RegCloseKey($key) or die "Can't close HKEY_LOCAL_MACHINE\n";
	return 0;
}

sub error_handle
{
  if(("custpack" ne lc $action) && ("theme_bin" ne lc $action)){
  	print "$action\n";
  my $build_folder = ".\\build\\$custom";
  opendir (DIR, $build_folder) or die "no folder : $build_folder\n";
  my @files = grep {/.+\.bin$/}  readdir DIR;
  close DIR;
  my $flag = 0;
  foreach (@files) {
  	next if($_ =~ /BOOTLOADER|FOTA/i);
  	my $bin_file = $build_folder."\\$_";
  	if (-d "$bin_file") {
      system ("rd /s /q $bin_file");
      $flag = 1;
    } elsif(-e "$bin_file") {
    	system ("del /F /Q $bin_file");
    	$flag = 1;
    }
  }
  print "Some errors happened during the build process. Delete the binary file\n" if($flag);
  }
  else{
    print "Ship delete the binarry file while action is custpack or theme_bin\n";
  }
  if ($check_depend)
  {
    my $res = system("perl tools\\ChkDepMod.pl --step 1 $custom $project $platform");
  }
  exit 1;
}
