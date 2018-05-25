# OpenCPU Quick Start Application Note

## 参考文档

* [ZF_OpenCPU_Quick_Start_Application_Note_V1.1.pdf](./refers/ZF_OpenCPU_Quick_Start_Application_Note_V1.1.pdf)
* [ZF_203C-OpenCPU_User_Guide_V1.0.pdf](./refers/ZF_203C-OpenCPU_User_Guide_V1.0.pdf)

## SDK说明

*  The root directory of OpenCPU SDK.
  * build: All compiling results are output to this directory.
  * custom: This directory is designed as the root directory of your project.  In the subdirectory "custom\config\", you can reconfigure the application according to requirements, such as heap memory size, multitasks and the stack size of tasks, GPIO initial status.  All configuration files for you are named with prerfix "custom_"
  * docs: Store all OpenCPU related documents.
  * example: All example codes are here. Each example file implements an application of independent function. And each example file can be compiled to an executable image bin.
  * include: All APIs head files are stored here.
  * libs: Dependent libraries for compiling.
  * make: All compiling scripts and makefile are placed here.
  * ril: Place the open source codes of OpenCPU RIL.  You can also easily add a new API to implement a standard AT command based on the open source of RIL.
  * tools: Some tools for application development, such as download tool and packaging tool for FOTA.
* The proc_main_task function is the entrance of Embedded Application, just like the main() in C application.
  * Ql_OS_GetMessage is an important system function that the Embedded Application receives messages from message queue of the task

## System Configuration

* custom_feature_def.h: OpenCPU features enabled. Now only include RIL. Developers generally do not need to change this file.
* custom_gpio_cfg.h: Configurations for GPIO initial status, in OpenCPU, there are two ways to initialize GPIOs. One is to configure initial GPIO list in "custom_gpio_cfg.h"; the other way is to call GPIO related API (Please refer to Chapter 5.7.2) to initialize after App starts. 
* custom_heap_cfg.h: Definition of heap size
* custom_task_cfg.h: Multitask configuration, OpenCPU supports multitask processing. Developers only need to simply follow suit to add a record in "custom_task_cfg.h" file to define a new task. OpenCPU supports one main task, and maximum TEN subtasks.
* custom_sys_cfg.c: Other system configurations, including power key, specified GPIO pin for external watchdog, and setting working mode of debug port. All customization items are configured in TLV (Type-Length-Value) in “custom_sys_cfg.c”. 
