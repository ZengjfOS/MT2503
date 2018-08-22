# Init Analysis

## 参考文档

* Nucleus PLUS操作系统相关资料：
  * [Nucleus PLUS应用系统示例](https://blog.csdn.net/suipingsp/article/details/32703507)
  * [Nucleus PLUS的启动、运行线程和中断处理](https://blog.csdn.net/suipingsp/article/details/32321491)
  * [Nucleus PLUS任务调度](https://blog.csdn.net/suipingsp/article/details/34423651)
  * [Nucleus PLUS系统架构和组件](https://blog.csdn.net/suipingsp/article/details/34831763)
  * [Nucleus PLUS Reference Manual](http://read.pudn.com/downloads178/ebook/827709/tech-reference/plus_ref.pdf)
* MTK功能机：
  * [nucleus实时操作系统MTK手机软件系统工程和配置简介](https://blog.csdn.net/feimor/article/details/5686509)
  * [MTK平台学习---TASK的创建](https://blog.csdn.net/xiaoweiboy/article/details/6785427)
* 《东哥MTK笔记.pdf》

## 初始化流程

* Application_Initialize
  * systemInitialization();
  * HWDInitialization();
    * USC_Start();
    * OSTD_Init();
    * RM_Init();
    * L1SM_Init();
    * HW_Divider_Initialization();
    * Drv_Init_Phase1();
      * DclPMU_Initialize();
      * drv_hisr_init();
      * lpwr_init();
      * DclPWM_Initialize();
      * DclSADC_Initialize();
      * custom_drv_init();
      * DclAUX_Initialize();
  * Drv_Init_Phase2();
  * stack_init_comp_info();


## Task初始化

* `config/src/hal/syscomp_config.c`
  ```C
  [...省略]
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
  [...省略]
  ```
* `config/include/hal/hal_task_config.h`
  ```C
  /*************************Task CFG Begin****************/
  /*task_indx_type*/
  task_index(INDX_IPERF2)  
  /*module_type and mod_task_g*/
  task_module_map(INDX_IPERF2, MOD_IPERF2)

  /*task's parameters*/
  task_name("IPERF2")                       {"IPERF2",
  task_queue_name("IPERF2 Q")                   "IPERF2 Q",
  task_priority(TASK_PRIORITY_IPERF4)           TASK_PRIORITY_IPERF2,
  task_stack_size(4096)                         4096 + TASK_STACK_COMMON_PLUS,
  task_create_function(iperf4_create)           iperf2_create,
  task_stack_internalRAM(KAL_FALSE)             KAL_FALSE,
  task_external_queue_size(20)                  20,
  task_internal_queue_size(0)                   0,
  task_boot_mode(NORMAL_M)                  NORMAL_M},

  /*************************Task CFG END******************/
  ```
* `config/include/app/app_task_config.h`
  ```C
  /*************************Task CFG Begin****************/
  /*task_indx_type*/
  task_index(INDX_VRT)
  /*module_type and mod_task_g*/
  task_module_map(INDX_VRT, MOD_VRT)

  /*task's parameters*/
  task_name("VRT")
  task_queue_name("VRT Q")
  task_priority(TASK_PRIORITY_VRT)
  #ifdef __VENUS_3D_UI_ENGINE__
  task_stack_size(4096+1024*6)
  #else
  task_stack_size(4096)
  #endif
  #ifdef __VENUS_UI_ENGINE__
  task_create_function(vrt_create)
  #else
  null_task_create_entry(NULL)
  #endif
  task_stack_internalRAM(KAL_FALSE)
  task_external_queue_size(30)
  task_internal_queue_size(0)
  task_boot_mode(NORMAL_M | USB_M)
  /*************************Task CFG END******************/
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
  ```

## IdleClassic Hacking

* `plutommi/mmi/Idle/IdleSrc/IdleFactory.c`
  ```C
  [...省略]
  /* This table registers the idle object. */
  /*
   * <Factory>
   *
   * DESCRIPTION
   *  factory configuration table structure
   * ELEMENTS
   *  type                                    : [IN] object type ID
   *  size                                    : [IN] object size
   *  mmi_factory_on_want_to_run_cb       : [IN] want to run function
   *  mmi_factory_on_init_cb              : [IN] init function
   *  mmi_factory_on_deinit_cb            : [IN] deinit function
   *
   * typedef struct
   * {
   *     S16                                 type;
   *     U16                                 size;
   *     mmi_factory_on_want_to_run_cb       on_want_to_run;
   *     mmi_factory_on_init_cb              on_init;
   *     mmi_factory_on_deinit_cb            on_deinit;
   * } mmi_factory_cfg_struct;
   */
  const static mmi_factory_cfg_struct g_mmi_idle_cfg_tbl[] =
  {
      [...省略]

  #if defined(__MMI_VUI_LAUNCHER__)
      MMI_FACTORY_CFG_ADD(
          MMI_IDLE_TYPE_LAUNCHER,
          sizeof(mmi_idle_launcher_struct),
          mmi_idle_obj_on_want_to_run,
          (mmi_factory_on_init_cb)mmi_idle_launcher_on_init,
          (mmi_factory_on_deinit_cb)mmi_idle_obj_on_deinit),
  #endif /* defined(__MMI_VUI_LAUNCHER__) */

      /**
       * {
       *  MMI_IDLE_TYPE_LAUNCHER,
       *  sizeof(mmi_idle_launcher_struct),
       *  mmi_idle_obj_on_want_to_run,
       *  (mmi_factory_on_init_cb)mmi_idle_launcher_on_init,
       *  (mmi_factory_on_deinit_cb)mmi_idle_obj_on_deinit
       * },
       */
  #ifdef __MMI_IDLE_CLASSIC_AND_MAINMENU_SUPPORT__
      MMI_FACTORY_CFG_ADD(
          MMI_IDLE_TYPE_CLASSIC,
          sizeof(mmi_idle_classic_struct),
          mmi_idle_obj_on_want_to_run,
          (mmi_factory_on_init_cb)mmi_idle_classic_on_init,
          (mmi_factory_on_deinit_cb)mmi_idle_obj_on_deinit),
  #endif

      MMI_FACTORY_CFG_END()
  };
  [...省略]
  ```
* `plutommi/mmi/Idle/IdleSrc/IdleFactory.c`
  ```C
  [...省略]
  /*****************************************************************************
   * FUNCTION
   *  mmi_idle_get_cfg_table
   * DESCRIPTION
   *  This function gets the idle configure table.
   * PARAMETERS
   *  void
   * RETURNS
   *  Idle type.
   *****************************************************************************/
  const mmi_factory_cfg_struct *mmi_idle_get_cfg_table(void)
  {
      /*----------------------------------------------------------------*/
      /* Local Variables                                                */
      /*----------------------------------------------------------------*/

      /*----------------------------------------------------------------*/
      /* Code Body                                                      */
      /*----------------------------------------------------------------*/
      return g_mmi_idle_cfg_tbl;
  }
  [...省略]
  ```
* `plutommi/mmi/Idle/IdleSrc/IdleMain.c`
  ```C
  mmi_idle_obj_struct * mmi_idle_launch_new_obj(void)
  {
      /*----------------------------------------------------------------*/
      /* Local Variables                                         */
      /*----------------------------------------------------------------*/
      mmi_idle_obj_struct *obj;

      /*----------------------------------------------------------------*/
      /* Code Body                                              */
      /*----------------------------------------------------------------*/
      MMI_IDLE_LOG((TRC_MMI_IDLE_LAUNCH, 300));
      /*
       * New the object.
       */
      obj = (mmi_idle_obj_struct *)mmi_factory_new_obj(
                                      mmi_idle_get_cfg_table(),
                                      mmi_idle_buffer_malloc);
      MMI_ASSERT(obj);

      /*
      * Run the idle object.
      */
      MMI_ASSERT(obj->on_create);
      obj->on_create(obj, GRP_ID_IDLE_MAIN);

      MMI_ASSERT(obj->on_run);
      obj->on_run(obj);

      g_mmi_idle_cntx.obj = obj;
      return obj;
  }

  [...省略]
  /*
  * lauch idle internal
  */
  static void mmi_idle_launch_internal(mmi_id base_group_id)
  {
      /*----------------------------------------------------------------*/
      /* Local Variables                                                */
      /*----------------------------------------------------------------*/
      mmi_idle_obj_struct *obj;
  //    mmi_frm_node_struct group_info;
      mmi_id this_gid;
  //    mmi_ret ret;

      /*----------------------------------------------------------------*/
      /* Code Body                                                      */
      /*----------------------------------------------------------------*/
      MMI_IDLE_LOG((TRC_MMI_IDLE_LAUNCH, 200));

      /*
       * Create.
       */
      this_gid = mmi_frm_group_create(
                  base_group_id,
                  GRP_ID_IDLE_MAIN,
                  mmi_idle_main_evt_hdlr,
                  NULL);

      MMI_ASSERT(this_gid != GRP_ID_INVALID);
      mmi_frm_group_enter(this_gid, MMI_FRM_NODE_NONE_FLAG);

      obj = mmi_idle_launch_new_obj();

      /*
       * Emit the event.
       */
      mmi_idle_emit_launched(obj);
  }

  [...省略]
  /* idle app proc*/
  static MMI_RET mmi_idle_app_proc(mmi_event_struct *evt)
  {
      /*----------------------------------------------------------------*/
      /* Local Variables                                                */
      /*----------------------------------------------------------------*/

      /*----------------------------------------------------------------*/
      /* Code Body                                                      */
      /*----------------------------------------------------------------*/
      switch(evt->evt_id)
      {
      #ifdef __MMI_IDLE_APP_NOT_USE_ASMv2__
          case EVT_ID_GROUP_ENTER:
      #else
          case EVT_ID_APP_ENTER:
      #endif
                  {
                          mmi_idle_launch_internal(APP_IDLE);
                          break;
                  }

          default:
              break;
          }
          return MMI_RET_OK;
  }

  [...省略]
  /* For the detail information, please refer to the IdleGprot.h */
  void mmi_idle_launch(mmi_id base_group_id)
  {
      /*----------------------------------------------------------------*/
      /* Local Variables                                                */
      /*----------------------------------------------------------------*/
  #ifdef __MMI_IDLE_APP_NOT_USE_ASMv2__
      mmi_id this_gid;

      /*----------------------------------------------------------------*/
      /* Code Body                                                      */
      /*----------------------------------------------------------------*/
      MMI_IDLE_LOG((TRC_MMI_IDLE_LAUNCH, 201));
      this_gid = mmi_frm_group_create(
                  GRP_ID_ROOT,
                  APP_IDLE,
                  mmi_idle_app_proc,
                  NULL);

      mmi_frm_group_enter(this_gid, MMI_FRM_NODE_NONE_FLAG);
  #else
      MMI_IDLE_LOG((TRC_MMI_IDLE_LAUNCH, 200));
      mmi_frm_app_launch(APP_IDLE, 0, base_group_id, mmi_idle_app_proc,
                          0,MMI_FRM_APP_LAUNCH_AFTER_BASE | MMI_FRM_APP_USE_SEND_WAY);
  #endif
  }
  ```
* `plutommi/mmi/Factory/FactorySrc/Factory.c`
  ```C
  [...省略]
  /* For the detail information, please refer to the FactoryGprot.h */
  mmi_factory_obj_struct *mmi_factory_new_obj_ex(
      U16 type,
      const mmi_factory_cfg_struct *cfg_table,
      mmi_factory_malloc_func_ptr alloc_func)
  {
      /*----------------------------------------------------------------*/
      /* Local Variables                                                */
      /*----------------------------------------------------------------*/
      const mmi_factory_cfg_struct *cfg;
      mmi_factory_obj_struct *obj;
  
      /*----------------------------------------------------------------*/
      /* Code Body                                                      */
      /*----------------------------------------------------------------*/
      cfg = mmi_factory_get_cfg(type, cfg_table);
      if (!cfg)
      {
          return NULL;
      }
  
      obj = (mmi_factory_obj_struct *)alloc_func(cfg->size);
  
      kal_mem_set(obj, 0, cfg->size);
  
      obj->type = type;
  
      if (cfg->on_init)
      {
          cfg->on_init(obj);
      }
  
      return obj;
  }
  
  /* For the detail information, please refer to the FactoryGprot.h */
  mmi_factory_obj_struct *mmi_factory_new_obj(
      const mmi_factory_cfg_struct *cfg_table,
      mmi_factory_malloc_func_ptr alloc)
  {
      /*----------------------------------------------------------------*/
      /* Local Variables                                                */
      /*----------------------------------------------------------------*/
      U16 type;
  
      /*----------------------------------------------------------------*/
      /* Code Body                                                      */
      /*----------------------------------------------------------------*/
      type = mmi_factory_get_favorite_type(cfg_table);
  
      if (type == MMI_FACTORY_TYPE_INVALID)
      {
          return NULL;
      }
  
      return mmi_factory_new_obj_ex(type, cfg_table, alloc);
  }
  [...省略]
  ```
* `plutommi/mmi/Idle/IdleSrc/IdleClassic.c`
  ```C
  void mmi_idle_classic_on_init(mmi_idle_obj_struct *obj)
  {
      /*----------------------------------------------------------------*/
      /* Local Variables                                                */
      /*----------------------------------------------------------------*/
      mmi_idle_classic_struct *p;
  #if defined(__MMI_TOUCH_IDLESCREEN_SHORTCUTS__) || defined(__MMI_BT_BOX_IDLE_SHORTCUTS__)
      U32 *capability;
  #endif
  
      /*----------------------------------------------------------------*/
      /* Code Body                                                      */
      /*----------------------------------------------------------------*/
      mmi_idle_obj_on_init(obj);
  
      p = (mmi_idle_classic_struct *)obj;
  
      /* Member variable. */
      p->type = MMI_IDLE_TYPE_CLASSIC;
  
      /* Member function. */
      p->on_enter = mmi_idle_classic_on_enter;
      p->on_update_service_area = mmi_idle_classic_on_update_service_indication;
  
          /*for __MMI_TOUCH_IDLESCREEN_SHORTCUTS__, the softkey area is owned by shortcut */
  #if defined(__MMI_TOUCH_IDLESCREEN_SHORTCUTS__) || defined(__MMI_BT_BOX_IDLE_SHORTCUTS__)
   #if !defined(__MMI_BT_DIALER_SUPPORT__)
      /* Change the capabilities. */
      capability = &obj->capability;
  
      *capability &= ~ENABLE_CENTER_SOFT_KEY;
      *capability &= ~ENABLE_SOFT_KEY_AREA;
   #endif
   #if defined(__MMI_BT_BOX_IDLE_SHORTCUTS__)
      capability = &obj->capability;
      *capability &= ~ENABLE_NAVIGATION_KEY;
      *capability &= ~ENABLE_LEFT_SOFT_KEY;
      *capability &= ~ENABLE_RIGHT_SOFT_KEY;
   #endif
  #endif
  }
  [...省略]

  /*****************************************************************************
   * FUNCTION
   *  mmi_idle_classic_on_enter
   * DESCRIPTION
   *  This function enters the idle screen.
   * PARAMETERS
   *  obj             : [IN]          Idle object
   * RETURNS
   *  void
   *****************************************************************************/
  static void mmi_idle_classic_on_enter(mmi_idle_obj_struct *obj)
  {
      /*----------------------------------------------------------------*/
      /* Local Variables                                                */
      /*----------------------------------------------------------------*/
      mmi_idle_classic_struct *p;
  #if defined(__MMI_SEARCH_WEB_GOOGLE__)
      const U8 *image;
      const WCHAR *string;
  #endif
  
      /*----------------------------------------------------------------*/
      /* Code Body                                                      */
      /*----------------------------------------------------------------*/
      MMI_ASSERT(obj);
  
      p = (mmi_idle_classic_struct *)obj;
  
  #if defined(MMI_IDLE_CLASSIC_CSK_SUPPORT)
      EnableCenterSoftkey(0, IMG_GLOBAL_DIAL_PAD_CSK);
  #endif
  
  #if 0//defined(__MMI_CALENDAR_ON_IDLE_SCREEN__)
  /* under construction !*/
  /* under construction !*/
  /* under construction !*/
  /* under construction !*/
  #endif /* defined(__MMI_CALENDAR_ON_IDLE_SCREEN__) */
  
  #if 0
  #ifdef __MMI_OP01_DCD__
  /* under construction !*/
  /* under construction !*/
  /* under construction !*/
  /* under construction !*/
  #endif /* __MMI_OP01_DCD__ */
  #endif
  
  #if defined(__MMI_IDLE_SCREEN_ICON_SHORTCUT__)
      mmi_idle_classic_init_icon_shct(p);
  #endif
  
  #if defined(__MMI_SEARCH_WEB_GOOGLE__)
      if(mmi_search_web_get_idle_hint(&image, &string))
      {
          idle_screen_enable_search_bar(image, string, mmi_idle_classic_search_bar_trigger_by_touch_hdlr);
      }
  #endif
  
      gui_sse_setup_scenario(GUI_SSE_SCENARIO_ENTER_IDLE);
  
      ShowCategory33Screen(
          STR_ID_IDLE_MAIN_MENU,
          0,
          STR_ID_IDLE_CONTACT,
          0,
          NULL);
  
      mmi_idle_set_handler((mmi_idle_obj_struct *)p);
  
  #ifndef __MMI_PHNSET_SLIM__
      mmi_phnset_save_wallpaper_to_speedup();
  #endif
  
      ClearKeyEvents();
  
      mmi_idle_sublcd_display();
  
  #if !defined(__MMI_TOUCH_IDLESCREEN_SHORTCUTS__) || defined(__MMI_BT_DIALER_SUPPORT__)
      if(mmi_scr_locker_is_locked())
      {
          // softkey needs to update after show category
          // TODO: framework should emit the event after show category
          // then update can be done by scrlocker self.
        #ifndef __MMI_BTD_BOX_UI_STYLE__
          wgui_softkey_update();
        #endif /*__MMI_BTD_BOX_UI_STYLE__*/
      }
  #endif
  }
  ```
* `plutommi/mmi/Bootup/BootupSrc/BootupFlow.c`
  ```C
  [...省略]
  /*****************************************************************************
   * FUNCTION
   *  mmi_bootup_flow_completed
   * DESCRIPTION
   *  Query if current screen is interruptable. Only ultra-high priority events
   *  can interrupt booting screens; such as incoming call.
   * PARAMETERS
   *  evt     [IN] mmi_frm_proc_completed_evt_struct *
   * RETURNS
   *  void
   *****************************************************************************/
  static mmi_ret mmi_bootup_flow_completed(mmi_event_struct *evt)
  {
      /*----------------------------------------------------------------*/
      /* Local Variables                                                */
      /*----------------------------------------------------------------*/

      /*----------------------------------------------------------------*/
      /* Code Body                                                      */
      /*----------------------------------------------------------------*/
      mmi_frm_proc_seq_destroy(g_mmi_bootup_flow_cntx.main_flow);
      g_mmi_bootup_flow_cntx.main_flow = NULL;

      if (srv_shutdown_is_running())
      {
          return MMI_RET_OK;
      }

      /*
       * [MAUI_02288699]
       * We should close waiting first, otherwise it may be shown during
       * accessing NVRAM on BEFORE_IDLE event.
       */
      mmi_bootup_waiting_screen_close(GRP_ID_BOOTUP);

      mmi_bootup_notify_before_idle();

      mmi_idle_launch(GRP_ID_BOOTUP);

      /* Clear leave proc of the base screen, to allow being closed */
      mmi_frm_scrn_set_leave_proc(GRP_ID_BOOTUP, SCR_ID_BOOTUP_BASE, NULL);

      mmi_frm_group_close(GRP_ID_BOOTUP);

      /* Change service status first */
      srv_bootup_notify_completed();
      /* Notify application finally */
      mmi_bootup_notify_completed();

      return MMI_RET_OK;
  }

  [...省略]
  /*****************************************************************************
   * FUNCTION
   *  mmi_bootup_flow_start
   * DESCRIPTION
   *  Start booting flow.
   *  This function is the handler of EVT_ID_BOOTUP_START.
   * PARAMETERS
   *  evt     [IN] srv_bootup_start_evt_struct*
   * RETURNS
   *  Always MMI_RET_OK
   *****************************************************************************/
  mmi_ret mmi_bootup_flow_start(mmi_event_struct *evt)
  {
      /*----------------------------------------------------------------*/
      /* Local Variables                                                */
      /*----------------------------------------------------------------*/

      /*----------------------------------------------------------------*/
      /* Code Body                                                      */
      /*----------------------------------------------------------------*/
      MMI_ASSERT(evt->evt_id == EVT_ID_SRV_BOOTUP_START);

      MMI_TRACE(MMI_BOOTUP_TRC_GROUP, TRC_MMI_BOOTUP_FLOW_START);

      g_mmi_bootup_flow_cntx.interrupt.disabled_count = 0;

      g_mmi_bootup_flow_cntx.main_flow = mmi_frm_proc_seq_create(
          mmi_frm_proc_allocate_id(),
          g_mmi_bootup_main_flow,
          sizeof(g_mmi_bootup_main_flow) / sizeof(g_mmi_bootup_main_flow[0]));

      mmi_frm_proc_seq_set_status_callback(
          g_mmi_bootup_flow_cntx.main_flow,
          mmi_bootup_flow_stop_check,
          &(g_mmi_bootup_flow_cntx));

      mmi_frm_proc_post_complete_execute(
          MMI_FRM_PROC_ID_BOOTUP_MAIN,
          mmi_bootup_flow_completed,
          &(g_mmi_bootup_flow_cntx),
          g_mmi_bootup_flow_cntx.main_flow);

      return MMI_RET_OK;
  }
  [...省略]
  ```
* `plutommi/Customer/CustomerInc/mmi_rp_callback_mgr_config.h`
  ```C
  MMI_FRM_CB_REG_BEGIN(EVT_ID_SRV_BOOTUP_START)
  MMI_FRM_CB_REG(mmi_bootup_flow_start)
  MMI_FRM_CB_REG_END(EVT_ID_SRV_BOOTUP_START)
  ```
