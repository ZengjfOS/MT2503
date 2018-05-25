# Make Hacking

## 编译环境

参考：[《WZ203CS-V3.0 开发板 support 文档.pdf》](./refers/WZ203CS-V3.0_dev_board_support_doc.pdf)

## Make.bat

Path: `203CS开发板发布资料\203CS开发板3.0SDK开发包\m203c_sdk_vport_v1.2\Make.bat`

```bat
@ECHO OFF
IF "%1" == "" (
	ECHO More parameter is required. 
	ECHO  - "make clean" may clean the compiling, and "make new" may start to compile.
) ELSE (
	CALL make\gcc\gcc_make.bat %1
)
```

`make new`会调用`make\gcc\gcc_make.bat`，并将`new`作为参数传递过去。

## gcc_make.bat

Path: `203CS开发板发布资料\203CS开发板3.0SDK开发包\m203c_sdk_vport_v1.2\make\gcc\gcc_make.bat`

```bat
@ECHO OFF
IF /i "%1" == "new" (
	@copy /y libs\app_image_bin.cfg build\gcc\app_image_bin.cfg
	make\make.exe -f make/gcc/gcc_makefile  2> build/gcc/build.log
) ELSE (
	IF /i "%1" == "clean" (
		make\make.exe %1 -f make/gcc/gcc_makefile
		IF EXIST build\gcc\build.log (
			@del /f build\gcc\build.log
		)
		IF EXIST build\gcc\app_image_bin.cfg (
			@del /f build\gcc\app_image_bin.cfg
		)
	) ELSE (
		IF /i "%1" == "help" (
			make\make.exe %1 -f make/gcc/gcc_makefile
		) ELSE (
			ECHO Incorect input argument.
		)
	)
)
```

@在bat脚本表示取消命令回显

* `make new`:
  * 拷贝`libs\app_image_bin.cfg`到`build\gcc\app_image_bin.cfg`；
  * 使用gcc_makefile作为make命令执行文件，执行new，错误输出重定向到`build\gcc\build.log`；
* `make clean`:
  * 使用gcc_makefile作为make命令执行文件，执行clean；
  * 如果`build\gcc\build.log`、`build\gcc\app_image_bin.cfg`存在，那就删除；
* `make help`:
  * 使用gcc_makefile作为make命令执行文件，执行help；

## gcc_makefile

Path: `203CS开发板发布资料\203CS开发板3.0SDK开发包\m203c_sdk_vport_v1.2\make\gcc\gcc_makefile`

```Makefile
##==========================================================================
 #                   Quectel OpenCPU
 #
 #              Copyright(c) 2012-2013 Quectel Ltd. All rights reserved.
 #
 #--------------------------------------------------------------------------
 # File Description
 # ----------------
 #      OpenCPU makefile for GCC.
 #
 #--------------------------------------------------------------------------
 #==========================================================================

#-------------------------------------------------------------------------------
# Configure GCC installation path, and GCC version.
# To execute "arm-none-eabi-gcc -v" in command line can get the current gcc version 
#-------------------------------------------------------------------------------
# 安装的编译器的路径
GCC_INSTALL_PATH=D:\Software\mtk2503\install
# 安装的编译器的版本
GCC_VERSION=4.6.1


#-------------------------------------------------------------------------------
#use the following path for 32-bit operating system
#-------------------------------------------------------------------------------
#GCC_INSTALL_PATH=C:\Program Files\CodeSourcery\Sourcery_CodeBench_Lite_for_ARM_EABI 

# 这里是决定哪个程序会被编译进最终的系统，用grep匹配一下，就能找到对应的文件了，
# 目前example下面有不少示例程序，这里就是同构这个宏来决定最终使用那个程序。
# 这个宏定义还会涉及到"203CS开发板发布资料\203CS开发板3.0SDK开发包\m203c_sdk_vport_v1.2\custom\config\custom_task_cfg.h"中对线程的声明
C_PREDEF=-D __EXAMPLE_FOTA_FTP__
#-------------------------------------------------------------------------------
# Configure the Cloud Solution
#-------------------------------------------------------------------------------
# 没有用到云服务器就可以不用这部分，有用到就需要添加对应的库，其实就是看"__EXAMPLE_FOTA_FTP__"有没有用到云端的协议
CLOUD_SOLUTION=
#ZYF_SOLUTION
#ZYF_MQTT_SOLUTION
#ZYF_TEST_SOLUTION
#PAHO_MQTT_SOLUTION
#MY_ZYF_SOLUTION
#ZYF_TRACKER_MQTT_SOLUTION
#-------------------------------------------------------------------------------
# Configure version and out target
#-------------------------------------------------------------------------------
PLATFORM = APPGS3MD
MEMORY   = M32
VERSION  = A01
TARGET   = $(strip $(PLATFORM))$(strip $(MEMORY))$(strip $(VERSION))

#-------------------------------------------------------------------------------
# Configure the include directories
#-------------------------------------------------------------------------------
INCS =  -I $(ENV_INC)               # 头文件目录，GCC编译的时候直接套用就行了： @$(CC) $(C_DEF) $(C_PREDEF) $(CFLAGS) $(INCS) -o $@ $<
INCS += -I ./           \
        -I include      \
        -I ril/inc      \
        -I custom/config   \
        -I custom/fota/inc \

		



#-------------------------------------------------------------------------------
# Configure source code dirctories
#-------------------------------------------------------------------------------
SRC_DIRS=example    \               # 源代码目录，先加载一些主要目录，后面有需要再添加对应的部分
		 custom     \
		 custom\config     \
         custom\fota\src   \
		 ril\src    \



#-------------------------------------------------------------------------------
# Configure source code files to compile in the source code directories
#-------------------------------------------------------------------------------
SRC_SYS=$(wildcard custom/config/*.c)
SRC_SYS_RIL=$(wildcard ril/src/*.c)
SRC_EXAMPLE=$(wildcard example/*.c)
SRC_CUS=$(wildcard custom/*.c)
SRC_FOTA=$(wildcard custom/fota/src/*.c)


# 将.c文件，换成.o文件，方便后边自动推到编译
OBJS=\
	 $(patsubst %.c, $(OBJ_DIR)/%.o, $(SRC_SYS))        \
	 $(patsubst %.c, $(OBJ_DIR)/%.o, $(SRC_SYS_RIL))    \
	 $(patsubst %.c, $(OBJ_DIR)/%.o, $(SRC_EXAMPLE))    \
	 $(patsubst %.c, $(OBJ_DIR)/%.o, $(SRC_CUS))        \
	 $(patsubst %.c, $(OBJ_DIR)/%.o, $(SRC_FOTA))      \


# 根据判断，添加依赖的头文件目录，源代码目录和源代码文件，并将.c转换成.o存在OBJS中
ifeq ($(strip $(CLOUD_SOLUTION)),ZYF_SOLUTION)
     INCS +=-I cloud/zyf_app/zyf_config
	 INCS +=-I cloud/zyf_app/zyf_custom
	 INCS +=-I cloud/zyf_app/zyf_protocol
	 SRC_DIRS +=cloud\zyf_app\zyf_config
	 SRC_DIRS +=cloud\zyf_app\zyf_custom
	 SRC_DIRS +=cloud\zyf_app\zyf_protocol
	 SRC_CLOUD =$(wildcard cloud/zyf_app/zyf_config/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_app/zyf_custom/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_app/zyf_protocol/*.c)
	 OBJS +=$(patsubst %.c, $(OBJ_DIR)/%.o, $(SRC_CLOUD))
	 C_PREDEF +=-D __$(CLOUD_SOLUTION)__

else ifeq ($(strip $(CLOUD_SOLUTION)),ZYF_TEST_SOLUTION)
	INCS +=-I cloud/zfy_test_app
	SRC_DIRS +=cloud\zfy_test_app
	SRC_CLOUD =$(wildcard cloud/zfy_test_app/*.c)
	OBJS +=$(patsubst %.c, $(OBJ_DIR)/%.o, $(SRC_CLOUD))
	C_PREDEF +=-D __$(CLOUD_SOLUTION)__
	 
else ifeq ($(strip $(CLOUD_SOLUTION)),ZYF_MQTT_SOLUTION)

	 INCS +=-I cloud/zyf_mqtt_ble_app/zyf_mqtt/auth
	 INCS +=-I cloud/zyf_mqtt_ble_app/zyf_mqtt/mqtt
	 INCS +=-I cloud/zyf_mqtt_ble_app/zyf_mqtt/mqtt/MQTTPacket
	 INCS +=-I cloud/zyf_mqtt_ble_app/zyf_mqtt/system
	 INCS +=-I cloud/zyf_mqtt_ble_app/zyf_mqtt/utility
	 INCS +=-I cloud/zyf_mqtt_ble_app/zyf_mqtt/platform
	 INCS +=-I cloud/zyf_mqtt_ble_app/zyf_mqtt/platform/network
	 INCS +=-I cloud/zyf_mqtt_ble_app/zyf_mqtt/platform/os
	 INCS +=-I cloud/zyf_mqtt_ble_app/zyf_mqtt/platform/ssl
	 INCS +=-I cloud/zyf_mqtt_ble_app/zyf_mqtt
	 INCS +=-I cloud/zyf_mqtt_ble_app/zyf_ble
	 INCS +=-I cloud/zyf_mqtt_ble_app/zyf_config
	 INCS +=-I cloud/zyf_mqtt_ble_app/zyf_custom
	 INCS +=-I cloud/zyf_mqtt_ble_app/zyf_protocol
	 
	 SRC_DIRS +=cloud\zyf_mqtt_ble_app\zyf_mqtt\auth
	 SRC_DIRS +=cloud\zyf_mqtt_ble_app\zyf_mqtt\mqtt
	 SRC_DIRS +=cloud\zyf_mqtt_ble_app\zyf_mqtt\mqtt\MQTTPacket
	 SRC_DIRS +=cloud\zyf_mqtt_ble_app\zyf_mqtt\system
	 SRC_DIRS +=cloud\zyf_mqtt_ble_app\zyf_mqtt\utility
	 SRC_DIRS +=cloud\zyf_mqtt_ble_app\zyf_mqtt\platform
	 SRC_DIRS +=cloud\zyf_mqtt_ble_app\zyf_mqtt\platform\network
	 SRC_DIRS +=cloud\zyf_mqtt_ble_app\zyf_mqtt\platform\os
	 SRC_DIRS +=cloud\zyf_mqtt_ble_app\zyf_mqtt\platform\ssl
	 SRC_DIRS +=cloud\zyf_mqtt_ble_app\zyf_mqtt
	 SRC_DIRS +=cloud\zyf_mqtt_ble_app\zyf_ble
	 SRC_DIRS +=cloud\zyf_mqtt_ble_app\zyf_config
	 SRC_DIRS +=cloud\zyf_mqtt_ble_app\zyf_custom
	 SRC_DIRS +=cloud\zyf_mqtt_ble_app\zyf_protocol
	 
	 
	 SRC_CLOUD =$(wildcard cloud/zyf_mqtt_ble_app/zyf_mqtt/auth/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_ble_app/zyf_mqtt/mqtt/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_ble_app/zyf_mqtt/mqtt/MQTTPacket/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_ble_app/zyf_mqtt/system/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_ble_app/zyf_mqtt/utility/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_ble_app/zyf_mqtt/platform/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_ble_app/zyf_mqtt/platform/network/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_ble_app/zyf_mqtt/platform/os/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_ble_app/zyf_mqtt/platform/ssl/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_ble_app/zyf_mqtt/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_ble_app/zyf_ble/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_ble_app/zyf_config/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_ble_app/zyf_custom/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_ble_app/zyf_protocol/*.c)
	
	 OBJS +=$(patsubst %.c, $(OBJ_DIR)/%.o, $(SRC_CLOUD))
	 C_PREDEF +=-D __$(CLOUD_SOLUTION)__

else ifeq ($(strip $(CLOUD_SOLUTION)),PAHO_MQTT_SOLUTION)

	 INCS +=-I cloud/paho_mqtt/MQTTPacket/src
	 INCS +=-I cloud/paho_mqtt/MQTTPacket
	 INCS +=-I cloud/paho_mqtt/user_custom
	 SRC_DIRS +=cloud\paho_mqtt\MQTTPacket
	 SRC_DIRS +=cloud\paho_mqtt\user_custom
	 SRC_DIRS +=cloud\paho_mqtt\MQTTPacket\src
	 SRC_CLOUD =$(wildcard cloud/paho_mqtt/MQTTPacket/*.c)
	 SRC_CLOUD +=$(wildcard cloud/paho_mqtt/MQTTPacket/src/*.c)
	 SRC_CLOUD +=$(wildcard cloud/paho_mqtt/user_custom/*.c)
	 OBJS +=$(patsubst %.c, $(OBJ_DIR)/%.o, $(SRC_CLOUD))
	 C_PREDEF +=-D __$(CLOUD_SOLUTION)__
	 
else ifeq ($(strip $(CLOUD_SOLUTION)),MY_ZYF_SOLUTION)
     INCS +=-I cloud/my_zyf_test_app/zyf_config
	 INCS +=-I cloud/my_zyf_test_app/zyf_custom
	 INCS +=-I cloud/my_zyf_test_app/zyf_protocol
	 SRC_DIRS +=cloud\my_zyf_test_app\zyf_config
	 SRC_DIRS +=cloud\my_zyf_test_app\zyf_custom
	 SRC_DIRS +=cloud\my_zyf_test_app\zyf_protocol
	 SRC_CLOUD =$(wildcard cloud/my_zyf_test_app/zyf_config/*.c)
	 SRC_CLOUD +=$(wildcard cloud/my_zyf_test_app/zyf_custom/*.c)
	 SRC_CLOUD +=$(wildcard cloud/my_zyf_test_app/zyf_protocol/*.c)
	 OBJS +=$(patsubst %.c, $(OBJ_DIR)/%.o, $(SRC_CLOUD))
	 C_PREDEF +=-D __$(CLOUD_SOLUTION)__
	 
else ifeq ($(strip $(CLOUD_SOLUTION)),ZYF_JT_SOLUTION)
     INCS +=-I cloud/zyf_app_tjd/zyf_config
	 INCS +=-I cloud/zyf_app_tjd/zyf_custom
	 INCS +=-I cloud/zyf_app_tjd/zyf_protocol
	 SRC_DIRS +=cloud\zyf_app_tjd\zyf_config
	 SRC_DIRS +=cloud\zyf_app_tjd\zyf_custom
	 SRC_DIRS +=cloud\zyf_app_tjd\zyf_protocol
	 SRC_CLOUD =$(wildcard cloud/zyf_app_tjd/zyf_config/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_app_tjd/zyf_custom/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_app_tjd/zyf_protocol/*.c)
	 OBJS +=$(patsubst %.c, $(OBJ_DIR)/%.o, $(SRC_CLOUD))
	 C_PREDEF +=-D __$(CLOUD_SOLUTION)__
	 
else ifeq ($(strip $(CLOUD_SOLUTION)),ZYF_TRACKER_MQTT_SOLUTION)

	 INCS +=-I cloud/zyf_mqtt_tracker_app/zyf_mqtt/auth
	 INCS +=-I cloud/zyf_mqtt_tracker_app/zyf_mqtt/mqtt
	 INCS +=-I cloud/zyf_mqtt_tracker_app/zyf_mqtt/mqtt/MQTTPacket
	 INCS +=-I cloud/zyf_mqtt_tracker_app/zyf_mqtt/system
	 INCS +=-I cloud/zyf_mqtt_tracker_app/zyf_mqtt/utility
	 INCS +=-I cloud/zyf_mqtt_tracker_app/zyf_mqtt/platform
	 INCS +=-I cloud/zyf_mqtt_tracker_app/zyf_mqtt/platform/network
	 INCS +=-I cloud/zyf_mqtt_tracker_app/zyf_mqtt/platform/os
	 INCS +=-I cloud/zyf_mqtt_tracker_app/zyf_mqtt/platform/ssl
	 INCS +=-I cloud/zyf_mqtt_tracker_app/zyf_mqtt
	 INCS +=-I cloud/zyf_mqtt_tracker_app/zyf_ble
	 INCS +=-I cloud/zyf_mqtt_tracker_app/zyf_config
	 INCS +=-I cloud/zyf_mqtt_tracker_app/zyf_custom
	 INCS +=-I cloud/zyf_mqtt_tracker_app/zyf_protocol
	 
	 SRC_DIRS +=cloud\zyf_mqtt_tracker_app\zyf_mqtt\auth
	 SRC_DIRS +=cloud\zyf_mqtt_tracker_app\zyf_mqtt\mqtt
	 SRC_DIRS +=cloud\zyf_mqtt_tracker_app\zyf_mqtt\mqtt\MQTTPacket
	 SRC_DIRS +=cloud\zyf_mqtt_tracker_app\zyf_mqtt\system
	 SRC_DIRS +=cloud\zyf_mqtt_tracker_app\zyf_mqtt\utility
	 SRC_DIRS +=cloud\zyf_mqtt_tracker_app\zyf_mqtt\platform
	 SRC_DIRS +=cloud\zyf_mqtt_tracker_app\zyf_mqtt\platform\network
	 SRC_DIRS +=cloud\zyf_mqtt_tracker_app\zyf_mqtt\platform\os
	 SRC_DIRS +=cloud\zyf_mqtt_tracker_app\zyf_mqtt\platform\ssl
	 SRC_DIRS +=cloud\zyf_mqtt_tracker_app\zyf_mqtt
	 SRC_DIRS +=cloud\zyf_mqtt_tracker_app\zyf_ble
	 SRC_DIRS +=cloud\zyf_mqtt_tracker_app\zyf_config
	 SRC_DIRS +=cloud\zyf_mqtt_tracker_app\zyf_custom
	 SRC_DIRS +=cloud\zyf_mqtt_tracker_app\zyf_protocol
	 
	 
	 SRC_CLOUD =$(wildcard cloud/zyf_mqtt_tracker_app/zyf_mqtt/auth/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_tracker_app/zyf_mqtt/mqtt/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_tracker_app/zyf_mqtt/mqtt/MQTTPacket/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_tracker_app/zyf_mqtt/system/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_tracker_app/zyf_mqtt/utility/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_tracker_app/zyf_mqtt/platform/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_tracker_app/zyf_mqtt/platform/network/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_tracker_app/zyf_mqtt/platform/os/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_tracker_app/zyf_mqtt/platform/ssl/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_tracker_app/zyf_mqtt/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_tracker_app/zyf_ble/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_tracker_app/zyf_config/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_tracker_app/zyf_custom/*.c)
	 SRC_CLOUD +=$(wildcard cloud/zyf_mqtt_tracker_app/zyf_protocol/*.c)
	
	 OBJS +=$(patsubst %.c, $(OBJ_DIR)/%.o, $(SRC_CLOUD))
	 C_PREDEF +=-D __$(CLOUD_SOLUTION)__

else
     # 当前代码中 CLOUD_SOLUTION= ，所以只会执行这一部分内容，其他的if判断都不能被匹配
     #other solutions to append
endif
#-------------------------------------------------------------------------------
# Configure user reference library
#-------------------------------------------------------------------------------
USERLIB=libs/gcc/app_start.lib      # 目前未知这是什么库

.PHONY: all
all:
#	$(warning <-- make all, C_PREDEF=$(C_PREDEF) -->)
    # 在使用make all的情况下，或者直接执行make的情况下，再次执行make new，相当于执行make new；
	@$(MAKE) new -f make/gcc/gcc_makefile

include make\gcc\gcc_makefiledef    # 加载gcc_makefiledef文件

export GCC_INSTALL_PATH C_PREDEF OBJS USERLIB SRC_DIRS
```

## gcc_makefiledef

Path: `203CS开发板发布资料\203CS开发板3.0SDK开发包\m203c_sdk_vport_v1.2\make\gcc\gcc_makefiledef`

```Makefile
##==========================================================================
 #                   Quectel OpenCPU
 #
 #              Copyright(c) 2012-2013 Quectel Ltd. All rights reserved.
 #
 #--------------------------------------------------------------------------
 # File Description
 # ----------------
 #      OpenCPU makefile definition.
 #
 #--------------------------------------------------------------------------
 #
 #  Created by   :     Stanley YONG
 #        Date   :     December 18, 2012
 #==========================================================================

#-------------------------------------------------------------------------------
# Configure environment path
#-------------------------------------------------------------------------------
BIN_DIR=build\gcc
$(info $(OBJS))                     # 从这里可以看出定了OBJ_DIR定义前后的OBJS的变化
OBJ_DIR=$(BIN_DIR)\obj
$(info $(OBJS))                     # 从这里可以看出定了OBJ_DIR定义前后的OBJS的变化
BUILDLOG=$(BIN_DIR)/build.log
ENV_PATH=$(strip $(GCC_INSTALL_PATH))/bin
ENV_INC='$(strip $(GCC_INSTALL_PATH))/arm-none-eabi/include'
ENV_LIB_EABI='$(strip $(GCC_INSTALL_PATH))/arm-none-eabi/lib/thumb'
ENV_LIB_GCC='$(strip $(GCC_INSTALL_PATH))/lib/gcc/arm-none-eabi/$(GCC_VERSION)/thumb'

#-------------------------------------------------------------------------------
# Configure compiling utilities
#-------------------------------------------------------------------------------
CC='$(ENV_PATH)/arm-none-eabi-gcc.exe'
LD='$(ENV_PATH)/arm-none-eabi-ld.exe'
OBJCOPY='$(ENV_PATH)/arm-none-eabi-objcopy.exe'
RM='$(ENV_PATH)/cs-rm.exe'
MAKE=make/make.exe
HEADGEN=make/GFH_Generator.exe
#-------------------------------------------------------------------------------
# Configure standard reference library
#-------------------------------------------------------------------------------
STDLIB=$(ENV_LIB_EABI)/libm.a $(ENV_LIB_EABI)/libc.a $(ENV_LIB_EABI)/libcs3.a $(ENV_LIB_GCC)/libgcc.a

#-------------------------------------------------------------------------------
# Configure compiling options
#-------------------------------------------------------------------------------
SFLAGS=-c -mlong-calls -march=armv5te -mlittle-endian -mthumb-interwork -mfpu=vfp -mfloat-abi=soft -Wall -Wstrict-prototypes -Os
CFLAGS=-c -mlong-calls -march=armv5te -mlittle-endian -mthumb-interwork -mfpu=vfp -mfloat-abi=soft -Wall -Wstrict-prototypes -std=c99 -Os \
       -ffunction-sections -pipe -ftracer -fivopts

C_DEF=-D MT6252 -D __OCPU_COMPILER_GCC__
LDFLAGS=-Rbuild -X --gc-sections -T libs/gcc/linkscript.ld -nostartfiles
OBJCOPYFLAGS=

#-------------------------------------------------------------------------------
# Definition for compiling procedure
#-------------------------------------------------------------------------------
# new命令依赖CreateDir和$(BIN_DIR)/$(TARGET).bin，然后执行@$(HEADGEN) $(BIN_DIR)/$(TARGET).bin
new: CreateDir $(BIN_DIR)/$(TARGET).bin
	@$(HEADGEN) $(BIN_DIR)/$(TARGET).bin

# 先要生成elf
$(BIN_DIR)/$(TARGET).bin: $(BIN_DIR)/$(TARGET).elf
	@$(OBJCOPY) $(OBJCOPYFLAGS) -O binary $< $@
	@echo ----------------------------------------------------
	@echo - GCC Compiling Finished Sucessfully.
	@echo - The target image is in the '$(BIN_DIR)' directory.
	@echo ----------------------------------------------------

# efl需要先将.o全部生成完毕，生成.o依赖.S、.c
$(BIN_DIR)/$(TARGET).elf: $(OBJS)
	@$(LD) $(LDFLAGS) -Map $(BIN_DIR)/$(TARGET).map -o $@ $(OBJS) $(USERLIB) $(STDLIB)

# 利用%通配符，从OBJS中截取相对路径、文件名，从而定位源代码文件，自动推导
$(OBJ_DIR)/%.o: %.S
    @echo - Building  $@  From src $<
	@$(CC) $(C_DEF) $(SFLAGS) -o $@ $<

# 利用%通配符，从OBJS中截取相对路径、文件名，从而定位源代码文件，自动推导
$(OBJ_DIR)/%.o: %.c
#	$(warning <-- Start to CC, C_PREDEF=$(C_PREDEF) -->)
    @echo - Building  $@  From src $<
	@$(CC) $(C_DEF) $(C_PREDEF) $(CFLAGS) $(INCS) -o $@ $<

CreateDir:
	@$(RM) -f $(BIN_DIR)/$(TARGET).bin
	@if not exist $(BIN_DIR) (md $(BIN_DIR))
	@if not exist $(OBJ_DIR) (md $(OBJ_DIR))
    # for循环迭代创建SRC_DIRS目录
	@for /d %%y in ($(SRC_DIRS)) do \
		@if not exist $(OBJ_DIR)/%%y ( \
			(@echo creating direcotry $(OBJ_DIR)\%%y) & \
			(md $ $(OBJ_DIR)\%%y))

clean:
	@$(RM) -f $(OBJS) $(BUILDLOG) \
	    $(BIN_DIR)/$(TARGET).map \
		$(BIN_DIR)/$(TARGET).bin \
		$(BIN_DIR)/$(TARGET).elf 
	@echo -------------------
	@echo clean finished.
	@echo -------------------

.PHONY: all clean CreateDir
```
