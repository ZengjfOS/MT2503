# Example GPIO Hacking

```C
/*****************************************************************************
*  Copyright Statement:
*  --------------------
*  This software is protected by Copyright and the information contained
*  herein is confidential. The software may not be copied and the information
*  contained herein may not be used or disclosed except with the written
*  permission of Quectel Co., Ltd. 2013
*
*****************************************************************************/
/*****************************************************************************
 *
 * Filename:
 * ---------
 *   example_gpio.c
 *
 * Project:
 * --------
 *   OpenCPU
 *
 * Description:
 * ------------
 *   This example demonstrates how to program a GPIO pin in OpenCPU.
 *   This example choose PINNAME_STATUS pin as GPIO.
 *
 *   All debug information will be output through DEBUG port.
 *
 *   The "Enum_PinName" enumeration defines all the GPIO pins.
 *
 * Usage:
 * ------
 *   Compile & Run:
 *
 *     Set "C_PREDEF=-D __EXAMPLE_GPIO__" in gcc_makefile file. And compile the 
 *     app using "make clean/new".
 *     Download image bin to module to run.
 *
 * Author:
 * -------
 * -------
 *
 *============================================================================
 *             HISTORY
 *----------------------------------------------------------------------------
 * 
 ****************************************************************************/
#ifdef __EXAMPLE_GPIO__             // 宏定义，makefile中指定需要的
#include "ql_trace.h"
#include "ql_system.h"
#include "ql_gpio.h"
#include "ql_stdlib.h"
#include "ql_error.h"
#include "ql_uart.h"


#define DEBUG_ENABLE 1
#if DEBUG_ENABLE > 0
#define DEBUG_PORT  UART_PORT1
#define DBG_BUF_LEN   512
static char DBG_BUFFER[DBG_BUF_LEN];
#define APP_DEBUG(FORMAT,...) {\                        // debug宏
    Ql_memset(DBG_BUFFER, 0, DBG_BUF_LEN);\
    Ql_sprintf(DBG_BUFFER,FORMAT,##__VA_ARGS__); \
    if (UART_PORT2 == (DEBUG_PORT)) \
    {\
        Ql_Debug_Trace(DBG_BUFFER);\
    } else {\
        Ql_UART_Write((Enum_SerialPort)(DEBUG_PORT), (u8*)(DBG_BUFFER), Ql_strlen((const char *)(DBG_BUFFER)));\
    }\
}
#else
#define APP_DEBUG(FORMAT,...) 
#endif


static void CallBack_UART_Hdlr(Enum_SerialPort port, Enum_UARTEventType msg, bool level, void* customizedPara)
{
     
}




static void GPIO_Program(void)
{
    // Specify a GPIO pin
    Enum_PinName  gpioPin = PINNAME_NETLIGHT;

    // Define the initial level for GPIO pin
    Enum_PinLevel gpioLvl = PINLEVEL_HIGH;

    // Initialize the GPIO pin (output high level, pull up)
    Ql_GPIO_Init(gpioPin, PINDIRECTION_OUT, gpioLvl, PINPULLSEL_PULLUP);
    APP_DEBUG("<-- Initialize GPIO pin (PINNAME_STATUS): output, high level, pull up -->\r\n");

    // Get the direction of GPIO
    APP_DEBUG("<-- Get the GPIO direction: %d -->\r\n", Ql_GPIO_GetDirection(gpioPin));

    // Get the level value of GPIO
    APP_DEBUG("<-- Get the GPIO level value: %d -->\r\n\r\n", Ql_GPIO_GetLevel(gpioPin));

    // Set the GPIO level to low after 500ms.
    APP_DEBUG("<-- Set the GPIO level to low after 500ms -->\r\n");
    Ql_Sleep(500);
    Ql_GPIO_SetLevel(gpioPin, PINLEVEL_LOW);
    APP_DEBUG("<-- Get the GPIO level value: %d -->\r\n\r\n", Ql_GPIO_GetLevel(gpioPin));

    // Set the GPIO level to high after 500ms.
    APP_DEBUG("<-- Set the GPIO level to high after 500ms -->\r\n");
    Ql_Sleep(500);
    Ql_GPIO_SetLevel(gpioPin, PINLEVEL_HIGH);
    APP_DEBUG("<-- Get the GPIO level value: %d -->\r\n", Ql_GPIO_GetLevel(gpioPin));
}

/************************************************************************/
/* The entrance for this example application                            */
/************************************************************************/
void proc_main_task(s32 taskId)
{
    s32 ret;
    ST_MSG msg;

    // Register & open UART port
    ret = Ql_UART_Register(UART_PORT1, CallBack_UART_Hdlr, NULL);
    if (ret < QL_RET_OK)
    {
        Ql_Debug_Trace("Fail to register serial port[%d], ret=%d\r\n", UART_PORT1, ret);
    }
    ret = Ql_UART_Open(UART_PORT1, 115200, FC_NONE);
    if (ret < QL_RET_OK)
    {
        Ql_Debug_Trace("Fail to open serial port[%d], ret=%d\r\n", UART_PORT1, ret);
    }
    
    APP_DEBUG("\r\n<-- OpenCPU: GPIO Example -->\r\n");

    // Start to program GPIO pin
    GPIO_Program();

    // Start message loop of this task
    while (TRUE)
    {
        Ql_OS_GetMessage(&msg);
        switch(msg.message)
        {
        case MSG_ID_USER_START:
            break;
        default:
            break;
        }
    }
}

#endif //__EXAMPLE_GPIO__
```

## Output

```Shell
<-- OpenCPU: GPIO Example -->
<-- Initialize GPIO pin (PINNAME_STATUS): output, high level, pull up -->
<-- Get the GPIO direction: 1 -->
<-- Get the GPIO level value: 1 -->

<-- Set the GPIO level to low after 500ms -->
<-- Get the GPIO level value: 0 -->

<-- Set the GPIO level to high after 500ms -->
<-- Get the GPIO level value: 1 -->
```
