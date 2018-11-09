# Task Message Communication

## Task Create

* `config/include/app/app_task_config.h` 
  ```C
  [...省略]
  #define TASK_PRIORITY_ZENGJF_TEST  (KAL_PRIORITY_CLASS10 + 6)

  #define TASK_PRIORITY_DRIVER_TEST  (KAL_PRIORITY_CLASS9 + 6)
  #define TASK_PRIORITY_MBBMSDRV     (KAL_PRIORITY_CLASS9 + 7)
  #define TASK_PRIORITY_CMMB         (KAL_PRIORITY_CLASS9 + 8)
  [...省略]
  /*********MTK RD add task before this line ****************/
  
  /*************************Task CFG Begin****************/
  /* reserve one task index for marking the last of mtk task; It's for stack sharing */
  /*task_indx_type*/
  task_index(INDX_MTKTASKEND)   
  /*module_type and mod_task_g*/
  task_module_map(INDX_MTKTASKEND, MOD_MTKTASKEND)
  task_name("MTKTSK")
  task_queue_name("MTKTSK Q")
  task_priority(255)
  task_stack_size(0)
  null_task_create_entry(NULL)
  task_stack_internalRAM(KAL_FALSE)
  task_external_queue_size(0)
  task_internal_queue_size(0)
  task_boot_mode(NORMAL_M) 
  ///*************************Task CFG END******************/
  
  /*************************Task CFG Begin****************/
  # if 1
  /*task_indx_type*/
  task_index(INDX_ZENGJF_TEST)
  /*module_type and mod_task_g*/
  task_module_map(INDX_ZENGJF_TEST, MOD_ZENGJF_TEST)
  
  /*task's parameters*/
  task_name("ZENGJFTEST")
  task_queue_name("ZENGJFTEST Q")
  task_priority(TASK_PRIORITY_ZENGJF_TEST)
  task_stack_size(2048)
  task_create_function(zengjftest_create)
  task_stack_internalRAM(KAL_FALSE)
  task_external_queue_size(10)
  task_internal_queue_size(0)
  task_boot_mode(NORMAL_M)
  #endif
  /*************************Task CFG END******************/
  
  /*************************Task CFG Begin****************/
  # if 1
  /*task_indx_type*/
  task_index(INDX_ZENGJF_SEND)
  /*module_type and mod_task_g*/
  task_module_map(INDX_ZENGJF_SEND, MOD_ZENGJF_SEND)
  
  /*task's parameters*/
  task_name("ZENGJFSEND")
  task_queue_name("ZENGJFSEND Q")
  task_priority(TASK_PRIORITY_ZENGJF_TEST)
  task_stack_size(2048)
  task_create_function(zengjfsend_create)
  task_stack_internalRAM(KAL_FALSE)
  task_external_queue_size(10)
  task_internal_queue_size(0)
  task_boot_mode(NORMAL_M)
  #endif
  /*************************Task CFG END******************/
  
  /****config customer task at the end of this file ******/
  /*************************Task CFG Begin****************/
  #if 0
  /* under construction !*/
  /* under construction !*/
  /* under construction !*/
  /* under construction !*/
  /* under construction !*/
  /* under construction !*/
  /* under construction !*/
  /* under construction !*/
  /* under construction !*/
  /* under construction !*/
  /* under construction !*/
  /* under construction !*/
  /* under construction !*/
  /* under construction !*/
  /* under construction !*/
  #endif
  /*************************Task CFG END******************/ 
  
  #endif /*TASK_PRIORITY_MACRO*/
  ```
* `config/include/hal/stack_msgs.h`
  ```C
  [...省略]
  #define MSG_ID_NAME(CK_MSG) MSG_ID_##CK_MSG##_CODE_CHECK_POINT, 
  
  typedef enum {
     MSG_ID_INVALID_TYPE = 0,
     #include "user_msgid_hal.h"
     #include "user_msgid_app.h"
  
     MSG_ID_CUSTOM2_CUSTOM1,
     MSG_ID_CUSTOM1_CUSTOM2,
  #if defined (__FLAVOR_VENDOR_SDK__) || defined(__MAUI_SDK_TEST__)
     MSG_ID_MMI_VS_INTQ_REQ,
     MSG_ID_MMI_VS_SEMAPHONE,
     MSG_ID_MMI_VS_MUTEX,
  #endif  
     MSG_ID_ZENGJFTEST,
     MSG_ID_END,
  #if defined(__SMART_PHONE_MODEM__)
     MSG_ID_DUMMY1 = 0x7FFFFFFF,
  #endif 
  } msg_type;
  [...省略]
  ```
* `custom/zengjf/zengjf.h` 
  ```C
  #ifndef __ZENGJF__
  #define __ZENGJF__
  
  static void zengjftest_task(task_entry_struct * task_entry_ptr);
  kal_bool zengjftest_create(comptask_handler_struct **handle);
  static void zengjfsend_task(task_entry_struct * task_entry_ptr);
  kal_bool zengjfsend_create(comptask_handler_struct **handle);
  
  #endif // __ZENGJF__
  ```
* `custom/zengjf/zengjf.c` 
  ```C
  /***************************************************************************** 
   * Include
   *****************************************************************************/ 
  #include "kal_trace.h"
  #include "stack_msgs.h"         /* enum for message IDs */
  #include "app_ltlcom.h"         /* Task message communiction */
  #include "syscomp_config.h"
  #include "task_config.h"        /* Task creation */
  #include "dcl.h"
  #include "gps_main.h"
  #include "gps_init.h"
  #include "gps_sm.h"
  #include "gps_trc.h"
  #include "stack_ltlcom.h"
  #include "stack_config.h"
  #include "kal_general_types.h"
  #include "kal_public_api.h"
  #include "kal_internal_api.h"
  
  static void zengjftest_task(task_entry_struct * task_entry_ptr)
  {
      kal_uint32 my_index;
      ilm_struct current_ilm;
  
      kal_get_my_task_index(&my_index);
      system_print("zengjftest_task start...\n");
  
      while (1)
      {
          receive_msg_ext_q(task_info_g[task_entry_ptr->task_indx].task_ext_qid,&current_ilm);
          stack_set_active_module_id( my_index, current_ilm.dest_mod_id );
  
          if (current_ilm.msg_id == MSG_ID_ZENGJFTEST)
          {
              system_print("zengjftest_task receive message\n");
          }   
  
          free_ilm(&current_ilm);
      }
  }
  
  kal_bool zengjftest_create(comptask_handler_struct **handle)
  {
      /*----------------------------------------------------------------*/
      /* Local Variables                                                */
      /*----------------------------------------------------------------*/
  
      static comptask_handler_struct mmi_handler_info = 
      {
          zengjftest_task,   /* task entry function */
          NULL,   /* task initialization function */
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
  
  static void zengjfsend_task(task_entry_struct * task_entry_ptr)
  {
      kal_uint32 my_index;
  
      kal_get_my_task_index(&my_index);
      kal_sleep_task(20);
      system_print("zengjfsend_task start...\n");
      kal_sleep_task(20);
  
      while (1)
      {
          ilm_struct *ilm_ptr = allocate_ilm(MOD_ZENGJF_SEND);
          ilm_ptr->src_mod_id = MOD_ZENGJF_SEND;
          ilm_ptr->dest_mod_id = MOD_ZENGJF_TEST;
          ilm_ptr->msg_id = MSG_ID_ZENGJFTEST;
          ilm_ptr->sap_id = 0;
          ilm_ptr->peer_buff_ptr = NULL;
          ilm_ptr->local_para_ptr = NULL;
  
          msg_send_ext_queue(ilm_ptr);
          kal_sleep_task(200);
      }
  }
  
  kal_bool zengjfsend_create(comptask_handler_struct **handle)
  {
      /*----------------------------------------------------------------*/
      /* Local Variables                                                */
      /*----------------------------------------------------------------*/
  
      static comptask_handler_struct mmi_handler_info = 
      {
          zengjfsend_task,   /* task entry function */
          NULL,   /* task initialization function */
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
* `make/config/config.mak`
  ```
  [...省略]
  #  Define include path lists to INC_DIR
  INC_DIR = interface\hwdrv \
            tst\include \
            tst\local_inc\
            hal\system\DP\inc\
            custom\zengjf
  [...省略]
  ```
* `make/custom/custom.mak`
  ```
  [...省略]
  INC_DIR += tst\local_inc \
  		   custom\zengjf
  
  SRC_LIST += custom\zengjf\zengjf.c
  [...省略]
  ```

## Console Output

```Shell
OSC> main: MediaTek OSCAR START......
System > Initializing system memory...
System > Creating buffer pool...
System > Initializing KAL resource...
zengjf
System > Creating task and queue...
System > Initializing task...
System > System initialization done!
zengjftest_task start...

MMI task
device.main_lcd_width*device.main_lcd_height=240,320
zengjfsend_task start...
zengjftest_task receive message

SIM Card detected:c
SIM inserted!
3V tech SIM: SIM reset@3.0VSIMcardReset@3.0Vsst:FF 3F FF FF 00 00 FC 33 00 0C 00
 00 00 00 00
IMSI_ReadPLMNSELexistTestSIM_AND!TestSIMSIM_MMRR_READYLongMSISDNNormal Speed SIM
RL =1, GEA = 0x70, SM =1, PFC = 1MS GPRS = 1, multislot =12, ext dyn = 1[app tre
e]
id = [0x0005] (G: [0x027a2048]): [1]
  id = [0x8248] (G: [0x027a4d54]): [2]
    id = [0x8249] (S: [0x027a4db8]  FULL SCRN)
    id = [0x824d] (S: [0x027a4e1c]  FULL SCRN)
[background tree]
id = [0x004a] (G: [0x027a2090]): [0]
zengjftest_task receive message
[app tree]
id = [0x0005] (G: [0x027a2048]): [1]
  id = [0x6cee] (G: [0x027a4e80]): [1]
    id = [0x6cef] (G: [0x027a4e1c]): [1]
      id = [0x0007] (G: [0x027a4ee4]): [1]
        id = [0x6cf0] (S: [0x027a4f48]  FULL SCRN)
[background tree]
id = [0x004a] (G: [0x027a2090]): [0]
zengjftest_task receive message
zengjftest_task receive message
zengjftest_task receive message
zengjftest_task receive message
[...省略]
```
