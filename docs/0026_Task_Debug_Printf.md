# Task Debug Printf

* `kal/include/kal_debug.h`
  ```
  #ifndef _KAL_DEBUG_H
  #define _KAL_DEBUG_H
  
  /*************************************************************************
   * Constant definition and check
   *************************************************************************/
  
  #if defined(__MTK_TARGET__) || defined(KAL_ON_NUCLEUS) || defined(KAL_ON_OSCAR) || defined(KAL_ON_THREADX)
  
  #if defined(DEBUG_KAL) && defined(RELEASE_KAL)
  #error "Only one of DEBUG_KAL and RELEASE_KAL can be defined"
  #endif
  
  #if !defined(DEBUG_KAL) && !defined(RELEASE_KAL)
  #error "At least one of DEBUG_KAL or RELEASE_KAL should be defined"
  #endif
  
  #if !defined(__KAL_ASSERT_LEVEL4__) && !defined(__KAL_ASSERT_LEVEL3__) && !defined(__KAL_ASSERT_LEVEL2__) && !defined(__KAL_ASSERT_LEVEL1__) && !defined(__KAL_ASSERT_LEVEL0__)
  #error "At least one of KAL_ASSERT_LEVEL4 or KAL_ASSERT_LEVEL3 or KAL_ASSERT_LEVEL2 or KAL_ASSERT_LEVEL1 or KAL_ASSERT_LEVEL0 should be defined"
  #endif
  
  #endif  /* __MTK_TARGET__ || KAL_ON_NUCLEUS || KAL_ON_OSCAR || KAL_ON_THREADX */
  
  /*************************************************************************
   * Include the common header file
   *************************************************************************/
  #include "kal_release.h"
  
  #ifdef __cplusplus
  extern "C" {
  #endif
  
  /*************************************************************************
   * Define Console or Log Print Functions
   *************************************************************************/
  #if defined (KAL_ON_OSCAR)    /* KAL_ON_OSCAR */
  
  extern void osc_platform_print_msg ( const char *format, ... );
  
  #define kal_print    osc_platform_print_msg
  #define kal_printf   osc_platform_print_msg
  
  #else   /* KAL_ON_OSCAR */
  
  #ifdef DEBUG_KAL
  
  #if !defined(__FUE__)
  extern void kal_debug_print(kal_char* string_to_be_printed);
  extern void dbg_print(char *fmt,...);
  
  #define kal_print( string_to_be_printed ) kal_debug_print( string_to_be_printed )
  #define kal_printf( string_to_be_printed ) dbg_print( string_to_be_printed )
  #else  /* __FUE__ */
  
  extern void fue_dbg_print(kal_char *fmt,...);
  
  #define kal_print( string_to_be_printed ) fue_dbg_print( string_to_be_printed )
  #define kal_printf( string_to_be_printed ) fue_dbg_print( string_to_be_printed )
  
  #endif /* __FUE__ */
  
  #else   /* DEBUG_KAL */
  
  #define kal_print( string_to_be_printed )
  #define kal_printf( string_to_be_printed )
  
  #endif   /* DEBUG_KAL */
  
  #endif   /* KAL_ON_OSCAR */
  
  extern void stack_print(char* string);
  
  #ifdef KAL_ON_OSCAR
  #define system_print osc_platform_print_msg
  #else
   #if !defined(__FUE__)
  #define system_print(s) stack_print(s)
   #else
    #define system_print(s) fue_dbg_print(s)
   #endif
  #endif
  
  #ifdef __cplusplus
  }
  #endif
  
  #endif /* _KAL_DEBUG_H */
  ```
* `DEBUG_KAL`：查出debug kal标记位置
  ```
  $ grep DEBUG_KAL * -r
  Option.mak:  ifeq ($(strip $(KAL_DEBUG_LEVEL)),RICH_DEBUG_KAL)
  Option.mak:    COM_DEFS += DEBUG_KAL DEBUG_BUF2 DEBUG_BUF3 DEBUG_ITC DEBUG_SWLA DEBUG_TIMER
  Option.mak:     DEP_DEBUG_COMPILE_OPTION =DEBUG_KAL DEBUG_BUF2 DEBUG_BUF3 DEBUG_ITC DEBUG_SWLA DEBUG_TIMER
  Option.mak:  ifeq ($(strip $(KAL_DEBUG_LEVEL)),NORMAL_DEBUG_KAL)
  Option.mak:    COM_DEFS += DEBUG_KAL DEBUG_BUF2 DEBUG_ITC
  Option.mak:     DEP_DEBUG_COMPILE_OPTION =DEBUG_KAL DEBUG_BUF2 DEBUG_ITC
  Option.mak:  ifeq ($(strip $(KAL_DEBUG_LEVEL)),SLIM_DEBUG_KAL)
  Option.mak:    COM_DEFS += DEBUG_KAL DEBUG_BUF1
  Option.mak:    DEP_DEBUG_COMPILE_OPTION = DEBUG_KAL DEBUG_BUF1
  ULTRA2503D_11C_GPRS.mak:  #   RICH_DEBUG_KAL > NORMAL_DEBUG_KAL > SLIM_DEBUG_KAL > RELEASE_KAL.
  ULTRA2503D_11C_GPRS.mak:  #   Default Setting : MT6251, MT6252, MT6253 => SLIM_DEBUG_KAL
  ULTRA2503D_11C_GPRS.mak:  #   Other Platform Project => NORMAL_DEBUG_KAL
  ULTRA2503D_11C_GPRS.mak:  #   SLIM_DEBUG_KAL: .
  ULTRA2503D_11C_GPRS.mak:  #   RICH_DEBUG_KAL: .
  ULTRA2503D_11C_GPRS.mak:  #   NORMAL_DEBUG_KAL: .
  ULTRA2503D_11C_GPRS.mak(KAL_TRACE_OUTPUT=FULL):KAL_DEBUG_LEVEL = SLIM_DEBUG_KAL
  ULTRA2503D_11C_GPRS.mak(KAL_TRACE_OUTPUT=FULL):  #   RICH_DEBUG_KAL > NORMAL_DEBUG_KAL > SLIM_DEBUG_KAL > RELEASE_KAL.
  ULTRA2503D_11C_GPRS.mak(KAL_TRACE_OUTPUT=FULL):  #   Default Setting : MT6251, MT6252, MT6253 => SLIM_DEBUG_KAL
  ULTRA2503D_11C_GPRS.mak(KAL_TRACE_OUTPUT=FULL):  #   Other Platform Project => NORMAL_DEBUG_KAL
  ULTRA2503D_11C_GPRS.mak(KAL_TRACE_OUTPUT=FULL):  #   SLIM_DEBUG_KAL: .
  ULTRA2503D_11C_GPRS.mak(KAL_TRACE_OUTPUT=FULL):  #   RICH_DEBUG_KAL: .
  ULTRA2503D_11C_GPRS.mak(KAL_TRACE_OUTPUT=FULL):  #   NORMAL_DEBUG_KAL: .
  ULTRA2503D_11C_GPRS.mak(KAL_TRACE_OUTPUT=NONE):  #   RICH_DEBUG_KAL > NORMAL_DEBUG_KAL > SLIM_DEBUG_KAL > RELEASE_KAL.
  ULTRA2503D_11C_GPRS.mak(KAL_TRACE_OUTPUT=NONE):  #   Default Setting : MT6251, MT6252, MT6253 => SLIM_DEBUG_KAL
  ULTRA2503D_11C_GPRS.mak(KAL_TRACE_OUTPUT=NONE):  #   Other Platform Project => NORMAL_DEBUG_KAL
  ULTRA2503D_11C_GPRS.mak(KAL_TRACE_OUTPUT=NONE):  #   SLIM_DEBUG_KAL: .
  ULTRA2503D_11C_GPRS.mak(KAL_TRACE_OUTPUT=NONE):  #   RICH_DEBUG_KAL: .
  ULTRA2503D_11C_GPRS.mak(KAL_TRACE_OUTPUT=NONE):  #   NORMAL_DEBUG_KAL: .
  ```
* `KAL_DEBUG_LEVEL`：查出kal debug level位置
  ```
  $ grep KAL_DEBUG_LEVEL * -r
  build/ULTRA2503D_11C/ULTRA2503D_11C_GPRS.mak:KAL_DEBUG_LEVEL = RELEASE_KAL
  custom/system/ULTRA2503D_11C_BB/scat_config/FeatureBased/ObjListGen/object.list.backup:KAL_DEBUG_LEVEL = RELEASE_KAL
  make/Option.mak:  ifneq ($(strip $(KAL_DEBUG_LEVEL)), RELEASE_KAL)
  make/Option.mak:    $(warning ERROR: Please set KAL_DEBUG_LEVEL=RELEASE_KAL when  IC_TEST_TYPE = IC_BURNIN_TEST )
  make/Option.mak:ifdef KAL_DEBUG_LEVEL
  make/Option.mak:  ifeq ($(strip $(KAL_DEBUG_LEVEL)),RICH_DEBUG_KAL)
  make/Option.mak:  ifeq ($(strip $(KAL_DEBUG_LEVEL)),NORMAL_DEBUG_KAL)
  make/Option.mak:  ifeq ($(strip $(KAL_DEBUG_LEVEL)),SLIM_DEBUG_KAL)
  make/Option.mak:  ifeq ($(strip $(KAL_DEBUG_LEVEL)),RELEASE_KAL)
  make/ULTRA2503D_11C_GPRS.mak:KAL_DEBUG_LEVEL = RELEASE_KAL
  make/ULTRA2503D_11C_GPRS.mak(KAL_TRACE_OUTPUT=FULL):KAL_DEBUG_LEVEL = SLIM_DEBUG_KAL
  make/ULTRA2503D_11C_GPRS.mak(KAL_TRACE_OUTPUT=NONE):KAL_DEBUG_LEVEL = RELEASE_KAL
  grep: MoDIS_VC9/MoDIS.ncb: Device or resource busy
  tools/factory_option.mak:KAL_DEBUG_LEVEL = NORMAL_DEBUG_KAL
  Binary file tools/GLBOptionSwtichRef/Feature_Option_Guide_MUST_READ.xls matches
  tools/GLBOptionSwtichRef/ULTRA2503D_11C_GPRS.mak:KAL_DEBUG_LEVEL = RELEASE_KAL
  ```
* `KAL_ON_OSCAR`：查出kal on oscar添加位置
  ```
  $ grep KAL_ON_OSCAR * -r
  modisConfig.mak:MODIS_EN_OPTION += DUMMYL1 L1_NOT_PRESENT KAL_ON_OSCAR UNIT_TEST
  ```
