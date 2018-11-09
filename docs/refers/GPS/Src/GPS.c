
#include "mmi_features.h"

#include "GPS.h"
#include "mdi_gps.h"
#include "gps_common.h"

static stu_gps_handle g_gps_handle = {0,-1};
static stu_gps_data g_gps_data = {0x00};


static void em_minigps_nmea_gga_callback(mdi_gps_nmea_gga_struct *param)
{
    mdi_gps_nmea_gga_struct *gga_data = param;
}

static void em_minigps_nmea_rmc_callback(mdi_gps_nmea_rmc_struct *param)
{
    mdi_gps_nmea_rmc_struct *rmc_data = param;
    U8 trace_data[128]={0x00};

    g_gps_data.latitude = rmc_data->latitude;
    g_gps_data.longitude = rmc_data->longitude;
    g_gps_data.north_south = rmc_data->north_south;
    g_gps_data.east_west = rmc_data->east_west;
    
    sprintf(trace_data, "lat:%f, lng:%f", g_gps_data.latitude, g_gps_data.longitude);
    kal_prompt_trace(MOD_XDM, "-gps-%d(%s)--%s--", __LINE__, (U8*)trace_data,__FILE__);  
}

static void em_minigps_nmea_gsa_callback(mdi_gps_nmea_gsa_struct *param)
{
    mdi_gps_nmea_gsa_struct *gsa_data = param;
}

static void em_minigps_nmea_gsv_callback(mdi_gps_nmea_gsv_struct *param)
{
    mdi_gps_nmea_gsv_struct *gsv_data = param;
}

static void em_minigps_nmea_string_callback(const U8 *buffer, U32 length)
{

}

static void em_minigps_nmea_gagsa_callback(void *param)
{
    gps_common_nmea_gsa_struct *gsa_data = (gps_common_nmea_gsa_struct*)param;
}

static void em_minigps_nmea_gagsv_callback(void *param)
{
    gps_common_nmea_gsv_struct *gsv_data = (gps_common_nmea_gsv_struct*)param;
}

static void em_minigps_nmea_glgsa_callback(void *param)
{
    gps_common_nmea_gsa_struct *gsa_data = (gps_common_nmea_gsa_struct*)param;
}

static void em_minigps_nmea_glgsv_callback(void *param)
{
    gps_common_nmea_gsv_struct *gsv_data = (gps_common_nmea_gsv_struct*)param;
}

static void em_minigps_gps_callback(mdi_gps_parser_info_enum type, void *buffer, U32 length)
{
    kal_prompt_trace(MOD_XDM, "--%d(gps:%s)--%s--", __LINE__, (U8*)buffer,__FILE__);
/*
	switch(type)
    {
        case MDI_GPS_PARSER_NMEA_GGA:
            em_minigps_nmea_gga_callback(buffer);
            break;
        case MDI_GPS_PARSER_NMEA_RMC:
            em_minigps_nmea_rmc_callback(buffer);
            break;
        case MDI_GPS_PARSER_NMEA_GSA:
            em_minigps_nmea_gsa_callback(buffer);
            break;
        case MDI_GPS_PARSER_NMEA_GSV:
            em_minigps_nmea_gsv_callback(buffer);
            break;
        case MDI_GPS_PARSER_RAW_DATA:
            em_minigps_nmea_string_callback(buffer, length);
            break;
        case MDI_GPS_PARSER_NMEA_GAGSA:
            em_minigps_nmea_gagsa_callback(buffer);
            break;
        case MDI_GPS_PARSER_NMEA_GAGSV:
            em_minigps_nmea_gagsv_callback(buffer);
            break;
        case MDI_GPS_PARSER_NMEA_GLGSA:
            em_minigps_nmea_glgsa_callback(buffer);
            break;
        case MDI_GPS_PARSER_NMEA_GLGSV:
            em_minigps_nmea_glgsv_callback(buffer);
            break;
    }
*/
}

void mmi_gps_open(void)
{        
//#if defined(__MTK_TARGET__)
    g_gps_handle.port = mdi_get_gps_port();
    if (g_gps_handle.port >= 0 && g_gps_handle.port_handle == -1)
    {  
   	//这个函数为何不能用?? 	
	g_gps_handle.port_handle = mdi_gps_uart_open((U16)g_gps_handle.port, MDI_GPS_UART_MODE_LOCATION, em_minigps_gps_callback);
	
	if (g_gps_handle.port_handle>=0 || MDI_RES_GPS_UART_ERR_PORT_ALREADY_OPEN==g_gps_handle.port_handle)
        {
            mdi_gps_set_work_port((U8)g_gps_handle.port);
        } 
       
        g_gps_handle.port_handle = mdi_gps_uart_open((U16)g_gps_handle.port, MDI_GPS_UART_MODE_RAW_DATA, em_minigps_gps_callback);        
	
    }
//#else
//    g_gps_handle.port_handle = 1;
//#endif
	kal_prompt_trace(MOD_XDM, "port:%d handle:%d",g_gps_handle.port, g_gps_handle.port_handle);
}

//关闭 GPS
void mmi_gps_close(void)
{        
    
	if(g_gps_handle.port_handle != -1)
	{
        	kal_prompt_trace(MOD_XDM, "--mmi_gps_close--%d-%s-", __LINE__, __FILE__);
    #if defined(__MTK_TARGET__)
        mdi_gps_uart_close(g_gps_handle.port, MDI_GPS_UART_MODE_LOCATION, em_minigps_gps_callback);
        mdi_gps_uart_close(g_gps_handle.port, MDI_GPS_UART_MODE_RAW_DATA, em_minigps_gps_callback);
    #endif
		g_gps_handle.port_handle = -1;
        	memset(&g_gps_data, 0x00, sizeof(g_gps_data));
	}
}

stu_gps_data *mmi_gps_get_data(void)
{
    return &g_gps_data;
}

