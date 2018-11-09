
#ifndef __GPS_H__
#define __GPS_H__

#include "mmi_features.h"


#include "MMIDataType.h"


//数据类型
typedef struct
{
    FLOAT    longitude;     //经度
    FLOAT    latitude;      //纬度
    S8       north_south;   //北-南
    S8       east_west;     //东-西
}stu_gps_data;

typedef struct
{
    S32 port;       //GPS 工作端口
    S32 port_handle;//-1:GPS 关闭状态; 否则 GPS 处于打开状态
}stu_gps_handle;


extern stu_gps_data *mmi_gps_get_data(void);
extern void mmi_gps_open(void);
extern void mmi_gps_close(void);


#endif

