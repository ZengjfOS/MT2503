# Task Init Sequence Hacking

## 参考文档

* [mtk架构分析资料详解](https://blog.csdn.net/qq_39902554/article/details/77855385)
* [MTK task](https://blog.csdn.net/hua_zai_arm/article/details/72792655)
* [MTK进阶——TASK创建及使用](https://blog.csdn.net/sheldon4090/article/details/6796737)
* [MTK task](https://blog.csdn.net/junjie319/article/details/8823042)

## Print Log

* `config/src/hal/task_config.c`
  ```C
  kal_bool
  stack_init_comp_info(void)
  {
      [...省略]
      /* Initialize global task info structure array */
      system_print("zengjf\n");                 <--------------打印输出
  
      for (task_indx = 0; task_indx < KALTotalTasks; task_indx++)
      {
  
          task_info_g[ task_indx ].task_name_ptr   =  RPS_NO_TASK_NAME;
          task_info_g[ task_indx ].task_qname_ptr  =  RPS_QNAME_NIL;
          task_info_g[ task_indx ].task_priority   = RPS_TASK_PRIORITY_NIL;
          task_info_g[ task_indx ].task_stack_size = RPS_STACK_SIZE_NIL;
          task_info_g[ task_indx ].task_id         = KAL_NILTASK_ID;
          task_info_g[ task_indx ].task_ext_qid    = KAL_NILQ_ID;
          task_info_g[ task_indx ].task_int_qid_ptr= NULL;
          task_info_g[ task_indx ].task_entry_func = NULL;
          task_info_g[ task_indx ].task_init_func  = NULL;
          task_info_g[ task_indx ].task_ext_qsize  = RPS_QSIZE_NIL;
      }
      [...省略]
  }
  ```
* system_print("zengjf");
  ```
  OSC> main: MediaTek OSCAR START......
  System > Initializing system memory...
  System > Creating buffer pool...
  System > Initializing KAL resource...
  zengjf                            <--------------打印输出
  System > Creating task and queue...
  System > Initializing task...
  System > System initialization done!
  device.main_lcd_width*device.main_lcd_height=240,320
  SIM Card detected:c
  SIM inserted!
  [...省略]
  ```

## Hacking Task

* `config/include/app/app_task_config.h`
  ```C
  /*************************Task CFG Begin****************/
  /*task_indx_type*/
  task_index(INDX_MMI) 
  /*module_type and mod_task_g*/
  #ifdef WISDOM_MMI
  /* under construction !*/
  /* under construction !*/
  #else
  task_module_map(INDX_MMI, MOD_MMI)
  #endif
  /* MOD_MMI is used by HAL file, please don't delete or modify it */
  
  /*task's parameters*/
  task_name("MMI")
  task_queue_name("MMI Q")
  task_priority(TASK_PRIORITY_MMI)
  
  #if defined(NEPTUNE_MMI)
  #if defined(__LOW_COST_SUPPORT_ULC__)
  task_stack_size(3072)
  #else /* __LOW_COST_SUPPORT_ULC__ */
  task_stack_size(4096)
  #endif /* __LOW_COST_SUPPORT_ULC__ */
  #else  /* Default value */
  #if defined(WISDOM_MMI)
  #if defined(OPERA_BROWSER) /* MMI: + 4 KB */
  /* under construction !*/
  #else
  /* under construction !*/
  #endif
  #else  /* WISDOM_MMI */
  #ifdef __MOBILE_VIDEO_SUPPORT__
  task_stack_size(20480)
  #else
  #if defined(__MRE_PACKAGE_FULL__) || defined(__MRE_PACKAGE_NORMAL__)
  task_stack_size(16348) /* MRE APP opera need 16KB */
  #elif defined(OPERA_BROWSER) /* MMI: + 4 KB */
  task_stack_size(10240)
  #else
  task_stack_size(6144)
  #endif
  #endif
  #endif /* WISDOM_MMI */
  #endif /* NEPTUNE_MMI */    
  #ifdef MMI_NOT_PRESENT
  null_task_create_entry(NULL)
  #elif !defined(WISDOM_MMI)
  task_create_function(mmi_create)
  #else
  /* under construction !*/
  #endif
  task_stack_internalRAM(KAL_FALSE)
  #if defined(WISDOM_MMI)
  /* under construction !*/
  /* under construction !*/
  #else
     #if (defined(__GEMINI__)) && (GEMINI_PLUS >= 4)
  /* under construction !*/
     #else
        task_external_queue_size(30)
     #endif
  task_internal_queue_size(0)
  #endif
  task_boot_mode(NORMAL_M | USB_M)
  /*************************Task CFG END******************/
  ```
* `custom/system/ULTRA2503D_11C_BB/custom_config.h`
  ```C
  #ifndef _CUSTOM_CONFIG_H
  #define _CUSTOM_CONFIG_H
  
  #include "stack_config.h"
  
  #endif /* _CUSTOM_CONFIG_H */
  ```
* `config/include/hal/stack_config.h`
  ```C
  /*define all macros as empty*/
  #define task_name(p1)
  #define task_queue_name(p1)
  #define task_priority(p1)
  #define task_stack_size(p1)
  #define null_task_create_entry(p1)
  #define compatible_code(p1)
  #define task_create_function(p1)
  #define task_stack_internalRAM(p1)
  #define task_external_queue_size(p1)
  #define task_internal_queue_size(p1)
  #define task_boot_mode(p1)
  #define MODULE_ID_MAP_TO_NULL_TASK_CAN_ALLOCATE_ILM(p1)
  #define MODULE_ID_FOR_PRINT_TRACE(p1)
  #define task_module_map(task, mod)
  #define task_index(p1)
  
  #undef task_index
  #define task_index(p1) p1, 
  typedef enum {
      #include "hal_task_config.h"
      #include "app_task_config.h"
      /*Total number of build time tasks*/
      RPS_TOTAL_STACK_TASKS,
  }task_indx_type;
  
  typedef enum {
      /*I. MOD ID MAP to hal task or NULL*/
      #undef task_module_map
      #undef task_index
      #undef compatible_code
      #undef MODULE_ID_MAP_TO_NULL_TASK_CAN_ALLOCATE_ILM
      
      #define task_index(p1) 
      #define task_module_map(task, mod) mod,
      #define compatible_code(expr) expr,
      #define MODULE_ID_MAP_TO_NULL_TASK_CAN_ALLOCATE_ILM(mod) mod,
      #include "hal_task_config.h"
      #undef task_module_map
      #undef task_index
      #undef compatible_code
      #undef MODULE_ID_MAP_TO_NULL_TASK_CAN_ALLOCATE_ILM
      /*II. MOD ID MAP to HISR*/
      MOD_HISR_BEGIN,
      #define X_HISR_CONST(a,b,c,d,e,f,g) 
      #define X_HISR_MOD(a,h) h,
      #include "hisr_config_internal.h"
      #undef X_HISR_CONST
      #undef X_HISR_MOD
      MOD_HISR_END,
      MOD_APP_BEGIN = (MOD_HISR_BEGIN + KAL_MAX_NUM_HISRS + 1),
      /*III. MOD ID MAP to app task or NULL*/        
      #undef task_module_map
      #undef task_index
      #undef compatible_code
      #undef MODULE_ID_MAP_TO_NULL_TASK_CAN_ALLOCATE_ILM
      
      #define task_index(p1) 
      #define task_module_map(task, mod) mod,
      #define compatible_code(expr) expr,
      #define MODULE_ID_MAP_TO_NULL_TASK_CAN_ALLOCATE_ILM(mod) mod,
      /*I. MOD ID MAP to task*/
      #include "app_task_config.h"
      #undef task_module_map
      #undef compatible_code
      #undef MODULE_ID_MAP_TO_NULL_TASK_CAN_ALLOCATE_ILM    
      #define task_module_map(task, mod)
      #define compatible_code(expr)
      #define MODULE_ID_MAP_TO_NULL_TASK_CAN_ALLOCATE_ILM(mod)
      LAST_MOD_ID,     /*size of module_ilm_g*/
      /*boundary check for mod_task_g, module_ilm_g. 
       * Once module_ilm_g size not bound to this macro, 
       * this macro can be moved to LAST_TASK_MOD_ID_BOUND
       * to save some memory in mod_task_g */
      RPS_TOTAL_STACK_MODULES = LAST_MOD_ID,           
      /*IV. ******MOD id for print trace**********/
      MOD_LIBRARY_BEGIN = 300, 
      #undef MODULE_ID_MAP_TO_NULL_TASK_CAN_ALLOCATE_ILM
      #undef MODULE_ID_FOR_PRINT_TRACE
  
      #define MODULE_ID_MAP_TO_NULL_TASK_CAN_ALLOCATE_ILM(mod)
      #define MODULE_ID_FOR_PRINT_TRACE(mod) mod,
     #include "hal_task_config.h"
     #include "app_task_config.h" 
     
      MOD_BOUNDARY,   
      /* remember that the maximum module id should be lower than 512 */
      END_OF_MOD_ID = 384 
  }module_type;
  ```
* `config/src/hal/syscomp_config.c`
  ```C
  #undef task_name
  #undef task_queue_name
  #undef task_priority
  #undef task_stack_size
  #undef null_task_create_entry
  #undef compatible_code
  #undef task_create_function
  #undef task_stack_internalRAM
  #undef task_external_queue_size
  #undef task_internal_queue_size
  #undef task_boot_mode
  #undef MODULE_ID_MAP_TO_NULL_TASK_CAN_ALLOCATE_ILM
  #undef MODULE_ID_FOR_PRINT_TRACE
  #undef task_index
  #undef task_module_map
  
  #define task_name(p1)
  #define task_queue_name(p1)
  #define task_priority(p1)
  #define task_stack_size(p1)
  #define null_task_create_entry(p1)
  #define compatible_code(p1)
  #define task_create_function(p1)
  #define task_stack_internalRAM(p1)
  #define task_external_queue_size(p1)
  #define task_internal_queue_size(p1)
  #define task_boot_mode(p1)
  //#define MODULE_ID_MAP_TO_NULL_TASK_CAN_ALLOCATE_ILM(p1)
  #define MODULE_ID_FOR_PRINT_TRACE(p1)
  //#define task_module_map(task, mod)
  #define task_index(p1)
  
  #define task_module_map(task, mod) task,
  #define MODULE_ID_MAP_TO_NULL_TASK_CAN_ALLOCATE_ILM(p1) INDX_NIL,
  /**RPS_TOTAL_STACK_MODULES: boundary check when access mod_task_g*/
  task_indx_type mod_task_g[RPS_TOTAL_STACK_MODULES] =
  {
      #include "hal_task_config.h"
      INDX_NIL,/* MOD_HISR_BEGIN */    
      INDX_NIL,
      INDX_NIL,
      INDX_NIL,
      INDX_NIL,
      INDX_NIL,
      INDX_NIL,
      INDX_NIL,
      INDX_NIL,
      INDX_NIL,
      INDX_NIL,
      INDX_NIL,
      INDX_NIL,
      INDX_NIL,
      INDX_NIL,
      INDX_NIL,
      INDX_NIL,
      INDX_NIL,
      INDX_NIL,
      INDX_NIL,
      INDX_NIL, 
      INDX_NIL,/*MOD_APP_BEGIN */   
      #include "app_task_config.h"
  };
  
  #undef task_name
  #undef task_queue_name
  #undef task_priority
  #undef task_stack_size
  #undef task_create_function
  #undef compatible_code 
  #undef null_task_create_entry
  #undef task_stack_internalRAM
  #undef task_external_queue_size
  #undef task_internal_queue_size
  #undef task_boot_mode
  #undef MODULE_ID_MAP_TO_NULL_TASK_CAN_ALLOCATE_ILM
  #undef MODULE_ID_FOR_PRINT_TRACE
  #undef task_index
  #undef task_module_map
  
  #define task_index(p1)
  #define task_module_map(task, mod)
  #define compatible_code(p1)
  #define MODULE_ID_MAP_TO_NULL_TASK_CAN_ALLOCATE_ILM(p1)
  #define MODULE_ID_FOR_PRINT_TRACE(p1)
  
  #define task_name(p1)                       {p1, 
  #define task_queue_name(p1)                  p1,   
  #define task_priority(p1)                    p1,
  #define task_stack_size(p1)                  (p1 + TASK_STACK_COMMON_PLUS),
  #define null_task_create_entry(p1)          (kal_create_func_ptr)TASK_NO_CREATE_PATTERN,
  #define task_create_function(p1)             p1,
  #define task_stack_internalRAM(p1)           p1,
  #define task_external_queue_size(p1)         p1, 
  #define task_internal_queue_size(p1)         p1,
  #define task_boot_mode(p1)                   p1},
  
  /**
   * typedef struct {
   *    kal_char             *comp_name_ptr;
   *    kal_char             *comp_qname_ptr;
   *    kal_uint32           comp_priority;
   *    kal_uint32           comp_stack_size;
   *    kal_create_func_ptr  comp_create_func;
   *    kal_bool             comp_internal_ram_stack;
   *    kal_uint8            comp_ext_qsize;
   *    kal_uint8            comp_int_qsize;
   *    kal_uint8            comp_boot_mode;
   * } comptask_info_struct;
   */
  const comptask_info_struct sys_comp_config_tbl[RPS_TOTAL_STACK_TASKS] =
  {
      #include "hal_task_config.h"
      #include "app_task_config.h"
  };
  ```
* `config/src/hal/task_config.c`
  ```C
  kal_bool
  stack_init_comp_info(void)
  {
     kal_uint32 task_indx, module_id;
     kal_uint8 boot_flag;
  
     kal_bool result = KAL_TRUE;
     comptask_handler_struct *comp_handler = NULL;
  #ifdef SPLIT_SYS
     kal_uint8 mask_offset;
     kal_uint8 mask_pos;
     kal_uint32 i;
  #endif /* SPLIT_SYS */
     
     KALTotalTasks = RPS_TOTAL_STACK_TASKS;
     KALTotalModules = RPS_TOTAL_STACK_MODULES;
     
     task_info_g = (task_info_struct *)kal_sys_mem_alloc(sizeof(task_info_struct) * KALTotalTasks);
     ASSERT(task_info_g != NULL);
     
     /* Initialize global task info structure array */
     // 给每个task结构赋默认值
     for (task_indx = 0; task_indx < KALTotalTasks; task_indx++)
     {
  
        task_info_g[ task_indx ].task_name_ptr   =  RPS_NO_TASK_NAME;
        task_info_g[ task_indx ].task_qname_ptr  =  RPS_QNAME_NIL;
        task_info_g[ task_indx ].task_priority   = RPS_TASK_PRIORITY_NIL;
        task_info_g[ task_indx ].task_stack_size = RPS_STACK_SIZE_NIL;
        task_info_g[ task_indx ].task_id         = KAL_NILTASK_ID;
        task_info_g[ task_indx ].task_ext_qid    = KAL_NILQ_ID;
        task_info_g[ task_indx ].task_int_qid_ptr= NULL;
        task_info_g[ task_indx ].task_entry_func = NULL;
        task_info_g[ task_indx ].task_init_func  = NULL;
        task_info_g[ task_indx ].task_ext_qsize  = RPS_QSIZE_NIL;
     }
  
     /* assume that the normal mode is the default setting */
  
  #ifdef SPLIT_SYS
     /* Transfer tst routing table module id to task id */
     for (i=MOD_NIL+1; i<LAST_MOD_ID; i++)
     {
        mask_offset = i / 8;
        mask_pos = i % 8;
  
        if (tst_routing_table[mask_offset] & (0x1 << mask_pos)) {
           /* On MNT PC side */
           mask_offset = mod_task_g[i] / 32;
           mask_pos = mod_task_g[i] % 32;
  
           utonmnt_task_mask_g[mask_offset] |= (0x1 << mask_pos);
        } else {
           /* On Target side */
           mask_offset = mod_task_g[i] / 32;
           mask_pos = mod_task_g[i] % 32;
  
           utontarget_task_mask_g[mask_offset] |= (0x1 << mask_pos);
        }
     }
  
     /* Both MNT, Target side need TST/TST Reader Tasks */
     i = INDX_TST;
     mask_offset = mod_task_g[i] / 32;
     mask_pos = mod_task_g[i] % 32;
     utonmnt_task_mask_g[mask_offset] &= ~(0x1 << mask_pos);
     utontarget_task_mask_g[mask_offset] &= ~(0x1 << mask_pos);
  
     i = INDX_TST_READER;
     mask_offset = mod_task_g[i] / 32;
     mask_pos = mod_task_g[i] % 32;
     utonmnt_task_mask_g[mask_offset] &= ~(0x1 << mask_pos);
     utontarget_task_mask_g[mask_offset] &= ~(0x1 << mask_pos);
  
  #ifdef __MTK_TARGET__
     redirect_task_mask_g = (kal_uint32*)&utonmnt_task_mask_g;
  #else
     redirect_task_mask_g = (kal_uint32*)&utontarget_task_mask_g;
  #endif /* __MTK_TARGET__ */
  
  #endif /* SPLIT_SYS */
  
     /* Initialize global task info structure array according to component info */
     // 使用全局的sys_comp_config_tbl初始化task_info_g任务数组
     for (task_indx = 0; task_indx < KALTotalTasks; task_indx++)
     {
         task_info_g[ task_indx ].task_name_ptr   = sys_comp_config_tbl[task_indx].comp_name_ptr;
         task_info_g[ task_indx ].task_qname_ptr  = sys_comp_config_tbl[task_indx].comp_qname_ptr;
         task_info_g[ task_indx ].task_priority   = sys_comp_config_tbl[task_indx].comp_priority;
         task_info_g[ task_indx ].task_stack_size = sys_comp_config_tbl[task_indx].comp_stack_size;
  #ifdef __SYS_INTERN_RAM__
         task_info_g[ task_indx ].task_internal_ram_stack = sys_comp_config_tbl[task_indx].comp_internal_ram_stack;
  #endif /* __SYS_INTERN_RAM__ */
  
         task_info_g[ task_indx ].task_stack_size = sys_comp_config_tbl[task_indx].comp_stack_size;
             task_info_g[ task_indx].task_ext_qsize = sys_comp_config_tbl[task_indx].comp_ext_qsize;
  
         task_info_g[ task_indx ].task_int_qsize = sys_comp_config_tbl[task_indx].comp_int_qsize;
  
         /*Check whether the task should be created or mis-configured*/
         if ((sys_comp_config_tbl[task_indx].comp_create_func == (kal_create_func_ptr)TASK_NO_CREATE_PATTERN ) 
  #ifdef SPLIT_SYS
                 || (*(redirect_task_mask_g + (task_indx >> 5)) & (0x1 << (task_indx & 31)))
  #endif /* SPLIT_SYS */
            )
         {
             continue; 
         }
         else if((sys_comp_config_tbl[task_indx].comp_create_func == (kal_create_func_ptr)KAL_FALSE) ||
                 (sys_comp_config_tbl[task_indx].comp_create_func == (kal_create_func_ptr)KAL_TRUE))
         {/*
             This is task mis-configured case. This occurs code like 
              #ifdef xxx
                  task_create_function(yyy)
              #endif
             missing the null_task_create_entry as the else branch.
           
             The assumption is that task_stack_internalRAM(KAL_FALSE or KAL_TRUE)
             following task create function
         */
              kal_fatal_error_handler(KAL_ERROR_KALINIT_INIT_FAILED, task_indx);
         }
         else if (sys_comp_config_tbl[task_indx].comp_create_func(&comp_handler) != KAL_TRUE)
         {
             continue;
         }
  
         /* component task entry function */
         /*Null task_entry_func indicates the task will not create*/
         task_info_g[ task_indx ].task_entry_func =
             comp_handler->comp_entry_func;
  
         /* component task initialization handler */
         task_info_g[ task_indx ].task_init_func =
             comp_handler->comp_init_func;
  
         /* component task configuration handler */
         task_info_g[ task_indx ].task_cfg_func =
             comp_handler->comp_cfg_func;
  
         /* component task reset handler */
         task_info_g[ task_indx ].task_reset_func =
             comp_handler->comp_reset_func;
  
         /* component task termination handler */
         task_info_g[ task_indx ].task_end_func =
             comp_handler->comp_end_func;
  
  #ifdef __MULTI_BOOT__
         if (INT_BootMode() == MTK_FACTORY_MODE)
         {
                boot_flag = sys_comp_config_tbl[task_indx].comp_boot_mode & FACTORY_M;
                if(0 == boot_flag)
                {
                    task_info_g[ task_indx ].task_entry_func = NULL;
                    for(module_id = 0; module_id < KALTotalModules; module_id++)
                    {
                      if(task_indx == mod_task_g[module_id])
                      {
                          mod_task_g[module_id] = INDX_NIL;
                      }
                    }
                }
         }
  #ifdef __USB_ENABLE__
         else if( INT_USBBoot() )
         {
             boot_flag = sys_comp_config_tbl[task_indx].comp_boot_mode & USB_M;
             if(0 == boot_flag)
             {
                 task_info_g[ task_indx ].task_entry_func = NULL;
                 for(module_id = 0; module_id < KALTotalModules; module_id++)
                 {
                     if(task_indx == mod_task_g[module_id])
                     {
                         mod_task_g[module_id] = INDX_NIL;
                     }
                 }
             }
         }
  #endif /* __MULTI_BOOT__ */
        else 
  #endif /* __USB_ENABLE__ */
         {
             boot_flag = sys_comp_config_tbl[task_indx].comp_boot_mode & NORMAL_M;
             if(boot_flag == 0)
             {
                 task_info_g[ task_indx ].task_entry_func = NULL;
                 for(module_id = 0; module_id < KALTotalModules; module_id++)
                 {
                     if(task_indx == mod_task_g[module_id])
                     {
                         mod_task_g[module_id] = INDX_NIL;
                     }
                 }
             }
         }
         /*
         mask_offset = task_indx / 32;
         mask_pos = task_indx % 32;    */
     }
        
     result = stack_init_module_info();
  
     return result;
  }

  kal_bool
  stack_init_module_info( void )
  {
     /* According to feature customization,
        remap mod_task_g to overwrite internal configuration */
     remap_mod_task_g();
  
     return KAL_TRUE;
  }
  ```
* `plutommi/Framework/Tasks/TasksSrc/TaskInit.c`
  ```C
  kal_bool mmi_create(comptask_handler_struct **handle)
  {
      /*----------------------------------------------------------------*/
      /* Local Variables                                                */
      /*----------------------------------------------------------------*/
  
      static comptask_handler_struct mmi_handler_info = 
      {
          MMI_task,   /* task entry function */
          MMI_Init,   /* task initialization function */
          NULL,
          NULL,       /* task reset handler */
          NULL,       /* task termination handler */
      };
  
      /*----------------------------------------------------------------*/
      /* Code Body                                                      */
      /*----------------------------------------------------------------*/
      *handle = &mmi_handler_info;
      return KAL_TRUE;
  }
  ```
* `custom/system/ULTRA2503D_11C_BB/custom_config.c`
  ```C
  void remap_mod_task_g(void)
  {
  #if defined(OBIGO_Q05A)
     mod_task_g[MOD_WAP] = INDX_MMI;
  #endif
  #ifndef OBIGO_Q03C_MMS_V02
     mod_task_g[MOD_MMS] = mod_task_g[MOD_WAP];
  #endif
     return;
  }
  ```
* `plutommi/Framework/Tasks/TasksSrc/MMITask.c`
  ```C
  MMI_BOOL MMI_Init(task_indx_type task_indx)
  {
      /*----------------------------------------------------------------*/
      /* Local Variables                                                */
      /*----------------------------------------------------------------*/
  
      /*----------------------------------------------------------------*/
      /* Code Body                                                      */
      /*----------------------------------------------------------------*/
      #ifdef __DRM_SUPPORT__
      mmi_mutex_trace = kal_create_mutex("mmi_trace");
      #endif
  
      InitFileSystem();
      applib_mime_init();
      mmi_frm_init_key_event();
      mmi_frm_fix_mem_init();
      mmi_frm_event_flag_create();
      mmi_frm_init_scenario();
  
  #if defined(__MTK_TARGET__) && defined(__DCM_WITH_COMPRESSION_MAUI_INIT__)
      /* mmi_frm_appmem_stage1_init is called in the end of MAUI init. */
  #else
      mmi_frm_appmem_stage1_init();
  #endif
  
      /* 
       * initial the system service timer 
       */
      L4InitTimer();
      setup_UI_wrappers();
  
      mmi_fe_init();
  #ifdef GUI_INPUT_BOX_CACHE_SUPPORT
      /* init the editor cache mutext */
      gui_inputs_cache_init_mutex();
  #endif /* GUI_INPUT_BOX_CACHE_SUPPORT */
  
      return MMI_TRUE;
  }
  [...省略]

  void MMI_task(oslEntryType *entry_param)
  {
      /*----------------------------------------------------------------*/
      /* Local Variables                                                */
      /*----------------------------------------------------------------*/
      MYQUEUE Message;
      oslMsgqid qid;
  
      U32 count = 0;
      U32 queue_node_number = 0;
  
  
      /*----------------------------------------------------------------*/
      /* Code Body                                                      */
      /*----------------------------------------------------------------*/
      qid = task_info_g[entry_param->task_indx].task_ext_qid;
      mmi_ext_qid = qid;
      mmi_frm_nvram_cache_validate();
      InitEventHandlersBeforePowerOn();
      mmi_frm_set_event_flag(MMI_EVT_F_NOT_IN_NVRAM);
      mmi_frm_set_event_flag(MMI_EVT_F_NOT_IN_GDD);
      mmi_frm_set_event_flag(MMI_EVT_F_SCRM_ALLOC);
  
      while (1)
      {
          {
  
              if (g_keypad_flag == MMI_TRUE)
              {
                  mmi_frm_key_handle(NULL);
              //#ifdef __VENUS_UI_ENGINE__
              //    vfx_mmi_check_update();
              //#endif  
  
              //#if defined(__MMI_TOUCH_SCREEN__) && defined(__MTK_TARGET__)
                  /* MAUI_01901848
                   * END key down->mmi_pen_disable
                   * so during the END key down, mmi_frm_pen_flush_queue will always return MMI_FALSE
                   * g_has_switch_screen will not has the opportunity to reset to MMI_FALSE;
                   * If the END key's up event is handle here(the upper function) and the Message
                   * MSG_ID_TP_EVENT_IND is in the MMI external queue and it is the first message in the queue
                   * that need to be handled and the first pen event is pen down in the pen event buffer.
                   * After pen down is handled in the protocol event handler, pen abort will be generated
                   * The behavior is not right, so we add reset_context_for_new_screen here.
                   */
                  /* Make sure there should be a new start for pen event when entering new screen */
              //#ifdef __MMI_VUI_3D_CUBE_APP__
              //    if (!vadp_p2v_uc_is_in_venus())
              //#endif
              //    {
              //        mmi_frm_pen_reset_context_for_new_screen();
              //    }
              //#endif                
                                
              }
              
              if (g_pen_flag == MMI_TRUE)
              {
              #ifdef __MMI_TOUCH_SCREEN__
                  mmi_frm_pen_handle();
              #endif
              //#if defined(__MMI_TOUCH_SCREEN__) && defined(__MTK_TARGET__)
              //#ifdef __MMI_VUI_3D_CUBE_APP__
              //    if (!vadp_p2v_uc_is_in_venus())
              //#endif
              //    {
              //        /* Make sure there should be a new start for pen event when entering new screen */
              //        mmi_frm_pen_reset_context_for_new_screen();
              //    }                
              //#endif
              }
  
              /* Get Total count in external queue */
              queue_node_number = msg_get_extq_messages();
  
              if ((g_pen_flag == MMI_FALSE) && (queue_node_number == 0) && (OslNumOfCircularQMsgs() == 0) && (g_keypad_flag == MMI_FALSE)&& vm_appcomm_queue_is_empty())
              {
                  U8 flag = 0;
                  //ilm_struct ilm_ptr;
  
                  /* MMI task suspends for the queue */
              #ifdef __VENUS_UI_ENGINE__
                  vfx_mmi_onidle();
              #endif
                  if((g_pen_flag == MMI_FALSE) && (queue_node_number == 0) && (OslNumOfCircularQMsgs() == 0) && (g_keypad_flag == MMI_FALSE) && vm_appcomm_queue_is_empty())
                  {
                      MMI_TRACE(MMI_FW_TRC_G6_FRM_DETAIL, TRC_MMI_FRM_TASK_SUSPEND_EXTERNAL_Q);
                      OslReceiveMsgExtQ(mmi_ext_qid, &Message);
                      kal_set_active_module_id(MOD_MMI);
  
                  /* put Message in circular queue */
                  //ilm_ptr.src_mod_id = Message.src_mod_id;
                  //ilm_ptr.dest_mod_id = Message.dest_mod_id;
                  //ilm_ptr.msg_id = Message.msg_id;
                  //ilm_ptr.sap_id = Message.sap_id;
                  //ilm_ptr.local_para_ptr = Message.local_para_ptr;
                  //ilm_ptr.peer_buff_ptr = Message.peer_buff_ptr;
  
                      flag = OslWriteCircularQ(&Message);
                      MMI_ASSERT(flag == 1);
                  }
                  else
                  {
                      mmi_frm_invoke_post_event();
                      mmi_frm_fetch_msg_from_extQ_to_circularQ();
                  }
                  /* TIMER use special data in the local_para_ptr field. Can NOT treat as general ILM */
                  //if (Message.src_mod_id != MOD_TIMER)
                  //{
                  //    hold_local_para(ilm_ptr.local_para_ptr);
                  //    hold_peer_buff(ilm_ptr.peer_buff_ptr);
                  //    OslFreeInterTaskMsg(&Message);
                  //}
              }
              else
              {
                  mmi_frm_fetch_msg_from_extQ_to_circularQ();
              }
  
              count = OslNumOfCircularQMsgs();
              while (count > 0)
              {
                  /* 
                   * Notify Venus UI in each message done 
                   */
                  #ifdef __VENUS_UI_ENGINE__
                  vfx_mmi_before_process_msg();
                  #endif                
              
                  kal_set_active_module_id(MOD_MMI);
  
                  if (OslReadCircularQ(&Message))
                  {
                      MMI_TRACE(MMI_FW_TRC_G1_FRM, TRC_MMI_FRM_TASK_MSG_HANDLE_BEGIN, Message.msg_id, Message.oslSrcId, Message.oslDestId);
  
                      #if defined(OBIGO_Q05A)
                      if (Message.dest_mod_id == MOD_WAP)
                      {
                      //#if defined(OBIGO_Q05A)
                          extern void mmi_wap_handle_msg(void *msgPtr);
  
                          mmi_wap_handle_msg((void*)&Message);
                      //#endif /* OBIGO_Q05A */ 
                      }
                      //#if defined(OBIGO_Q05A)
                      else if (Message.dest_mod_id == MOD_MMS)
                      {
                          extern void mmi_wap_handle_msg(void *msgPtr);
                          mmi_wap_handle_msg((void*)&Message);
                      }
                      //#endif /* OBIGO_Q05A */ 
                      //else
                      #endif
                      {
                          switch (Message.msg_id)
                          {
                              case MSG_ID_TIMER_EXPIRY:
                              {
                                  //kal_uint16 msg_len;
  
                                  //EvshedMMITimerHandler(get_local_para_ptr(Message.oslDataPtr, &msg_len));
                                  EvshedMMITimerHandler(&Message);
                              }
                                  break;
  
                              case MSG_ID_MMI_EQ_POWER_ON_IND:
                              {
                                  mmi_eq_power_on_ind_struct *p = (mmi_eq_power_on_ind_struct*) Message.oslDataPtr;
  
                                  srv_bootup_set_mode(p);
  #if defined(__MMI_FE_VECTOR_FONT_ON_FILE_SYSTEM__)
                                  if(p->poweron_mode == POWER_ON_PRECHARGE || p->poweron_mode == POWER_ON_CHARGER_IN ||
                                  /*  p->poweron_mode == POWER_ON_ALARM || */ p->poweron_mode == POWER_ON_EXCEPTION
                              #ifdef __MMI_USB_SUPPORT__
                                      || p->poweron_mode == POWER_ON_USB
                              #endif
                                      )
                                  {
                                      mmi_fe_reset_font_boot_mode();
                                  }
  #endif
  
                                  /* To initialize data/time */
                                  SetDateTime((void*)&(p->rtc_time));
                                  gdi_init();
                              #ifdef __VENUS_UI_ENGINE__
                                  vfx_mmi_sys_init();
                              #endif
  
                                  MMI_TRACE(MMI_FW_TRC_G1_FRM, TRC_MMI_FRM_TASK_POWER_PROC_BEGIN, p->poweron_mode);
                                  mmi_frm_start_scenario(MMI_SCENARIO_ID_DEFAULT);
                                  switch (p->poweron_mode)
                                  {
                                      case POWER_ON_KEYPAD:
                                          //mmi_frm_start_scenario(MMI_SCENARIO_ID_DEFAULT);
                                      #ifdef __MMI_DUAL_SIM_SINGLE_CALL__
  /* under construction !*/
                                      #endif
  
                                          g_charbat_context.PowerOnCharger = 0;
  
                                          /* disk check */
                                  #if defined(__FLIGHT_MODE_SUPPORT__) && defined(__MMI_TELEPHONY_SUPPORT__)
                                          g_phnset_cntx.curFlightMode = p->flightmode_state;
                                  #endif 
  
                                          break;
  
                                      case POWER_ON_PRECHARGE:
                                      case POWER_ON_CHARGER_IN:
                             /************************************** 
                              * Always send charger-in indication
                              * to avoid fast repeating charger 
                              * in-out b4 power-on completes
                              * Lisen 04/13/2004
                             ***************************************/
                                          //mmi_frm_start_scenario(MMI_SCENARIO_ID_DEFAULT);
                                          InitializeChargingScr();
                                          if (!srv_charbat_is_charger_connect())
                                          {
                                              //QuitSystemOperation();
                                          #ifdef __COSMOS_MMI_PACKAGE__    
                                              srv_shutdown_exit_system(VAPP_DEVICE);
                                          #else
                                              srv_shutdown_exit_system(APP_CHARGER);
                                          #endif
                                          }
                                          break;
  
                                      case POWER_ON_ALARM:
                                      #ifdef __MMI_SUBLCD__
                                          gdi_lcd_set_active(GDI_LCD_SUB_LCD_HANDLE);
                                          gdi_layer_clear(GDI_COLOR_BLACK);
                                          gdi_lcd_set_active(GDI_LCD_MAIN_LCD_HANDLE);
                                      #endif /* __MMI_SUBLCD__ */ 
                                          gdi_layer_clear(GDI_COLOR_BLACK);
                                          //mmi_frm_start_scenario(MMI_SCENARIO_ID_DEFAULT);
  
                                          srv_reminder_pwr_on_hdlr(p);
                                          
                                          break;
                                      case POWER_ON_EXCEPTION:
  
                                      #ifdef __MMI_DUAL_SIM_SINGLE_CALL__
  /* under construction !*/
                                      #endif
                                          break;
  
                                      #ifdef __MMI_USB_SUPPORT__
                                      case POWER_ON_USB:
                             /***************************************
                              * Because Aux task will not init in USB boot mode 
                              * Interrupt service routine for clam detection CLAM_EINT_HISR() 
                              * is not register, force the clam state to open 
                              * If Aux task is necessary in USB mode, this tircky could be removed 
                              * Robin 1209 
                              ***************************************/
                                          //mmi_frm_start_scenario(MMI_SCENARIO_ID_DEFAULT);                                        
                                      #if defined(__COSMOS_MMI_PACKAGE__) && defined(__MMI_USB_SUPPORT__)
                                      {
                                          extern void vapp_usb_launch_usbmode(void);
                                          vapp_usb_launch_usbmode();
                                      }
                                      #else
                                          #ifdef __MMI_USB_SUPPORT__
                                              mmi_usb_boot_init();
                                          #endif
                                      #endif
                             /***************************************
                              * To disable keypad tone state 
                              ***************************************/
                                          mmi_frm_kbd_set_tone_state(MMI_KEY_TONE_DISABLED);
                                          break;
                                      #endif /* __MMI_USB_SUPPORT__ */ 
  
                                      default:
                                          break;
                                  }
  
                              #if defined(__FLIGHT_MODE_SUPPORT__) && defined(__MMI_TELEPHONY_SUPPORT__)
                                  mmi_flight_mode_power_on_ind_hdlr(p);
                              #endif
  
                                  srv_bootup_power_on_ind_hdlr(p);
                                  
                                  MMI_TRACE(MMI_FW_TRC_G1_FRM, TRC_MMI_FRM_TASK_POWER_PROC_END, p->poweron_mode);
                              }
                                  break;
  
                              default:
                              #ifdef __MULTI_VCARD_SUPPORT__
                                  {
                                  extern void vcard_app_common_hdlr(void *ilm);
                                  vcard_app_common_hdlr((void*)&Message);
                                  }
                              #endif
                                  mmi_frm_execute_current_protocol_handler(
                                      (U16) Message.oslMsgId,
                                      (void*)Message.oslDataPtr,
                                      (int)Message.oslSrcId,
                                      (void*)&Message);
                                  break;
                          }
  
                      }
  
                      OslFreeInterTaskMsg(&Message);
                      mmi_frm_invoke_post_event();
                      mmi_frm_send_log_by_bt();
                      //#ifdef __COSMOS_MMI_PACKAGE__
                      //mmi_frm_temp_check_all_free();
                      //#endif
                      MMI_TRACE(MMI_FW_TRC_G1_FRM, TRC_MMI_FRM_TASK_MSG_HANDLE_END, Message.oslMsgId, Message.oslSrcId, Message.oslDestId);
                  }   /* OslReadCircularQ(&Message) */
                  //queue_node_number = msg_get_extq_messages();
                  count--;
                  
              /* for MRE message dispatcher */
                  vm_appcomm_dispatch_msg();
              //#if defined(__MMI_TOUCH_SCREEN__) && defined(__MTK_TARGET__)
              //#ifdef __MMI_VUI_3D_CUBE_APP__
              //    if (!vadp_p2v_uc_is_in_venus())
              //#endif
              //    {
              //        /* Make sure there should be a new start for pen event when entering new screen */
              //        mmi_frm_pen_reset_context_for_new_screen();
              //    }                
              //#endif
              }
              /* for MRE message dispatcher */
              vm_appcomm_dispatch_msg();
          }     
      }
  }
  ```
