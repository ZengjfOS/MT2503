# Hacking launcher

## 参考文档

* [在MTK平台里，，函数kal_prompt_trace起什么作用？？？Kal_prompt_trace的参数有表示什么？](https://zhidao.baidu.com/question/386832952.html)

## Hacking mmi_idle_launch_internal

```C
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
    // MMI_ID mmi_frm_group_create (MMI_ID parent_id, MMI_ID group_id, mmi_proc_fun proc, void *user_data)
    this_gid = mmi_frm_group_create(
                base_group_id,
                GRP_ID_IDLE_MAIN,
                mmi_idle_main_evt_hdlr,
                NULL);

    MMI_ASSERT(this_gid != GRP_ID_INVALID);
    mmi_frm_group_enter(this_gid, MMI_FRM_NODE_NONE_FLAG);

    obj = mmi_idle_launch_new_obj();                   ------------+
                                                                   |
    /*                                                             |
     * Emit the event.                                             |
     */                                                            |
    mmi_idle_emit_launched(obj);                                   |
}                                                                  |
                                                                   |
mmi_idle_obj_struct * mmi_idle_launch_new_obj(void)    <-----------+
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
    obj = (mmi_idle_obj_struct *)mmi_factory_new_obj(             -----------+
                                    mmi_idle_get_cfg_table(),     ---------+ |
                                    mmi_idle_buffer_malloc);               | |
    MMI_ASSERT(obj);                                                       | |
                                                                           | |
    /*                                                                     | |
    * Run the idle object.                                                 | |
    */                                                                     | |
    MMI_ASSERT(obj->on_create);                                            | |
    obj->on_create(obj, GRP_ID_IDLE_MAIN);         ------------------------*-*---+
                                                                           | |   |
    MMI_ASSERT(obj->on_run);                                               | |   |
    obj->on_run(obj);                              ------------------------*-*---*-+
                                                                           | |   | |
    g_mmi_idle_cntx.obj = obj;                                             | |   | |
    return obj;                                                            | |   | |
}                                                                          | |   | |
                                                                           | |   | |
const mmi_factory_cfg_struct *mmi_idle_get_cfg_table(void)       <---------+ |   | |
{                                                                            |   | |
    /*----------------------------------------------------------------*/     |   | |
    /* Local Variables                                                */     |   | |
    /*----------------------------------------------------------------*/     |   | |
                                                                             |   | |
    /*----------------------------------------------------------------*/     |   | |
    /* Code Body                                                      */     |   | |
    /*----------------------------------------------------------------*/     |   | |
    return g_mmi_idle_cfg_tbl;                        -------------------+   |   | |
}                                                                        |   |   | |
                                                                         |   |   | |
/* This table registers the idle object. */                              |   |   | |
const static mmi_factory_cfg_struct g_mmi_idle_cfg_tbl[] =       <-------+   |   | |
{                                                                            |   | |
                                                                             |   | |
    [...省略]                                                                |   | |
                                                                             |   | |
#if defined(__MMI_VUI_LAUNCHER__)                                            |   | |
    MMI_FACTORY_CFG_ADD(                                                     |   | |
        MMI_IDLE_TYPE_LAUNCHER,                                              |   | |
        sizeof(mmi_idle_launcher_struct),                                    |   | |
        mmi_idle_obj_on_want_to_run,                                         |   | |
        (mmi_factory_on_init_cb)mmi_idle_launcher_on_init,       ------------*+  | |
        (mmi_factory_on_deinit_cb)mmi_idle_obj_on_deinit),                   ||  | |
#endif /* defined(__MMI_VUI_LAUNCHER__) */                                   ||  | |
                                                                             ||  | |
    [...省略]                                                                ||  | |
                                                                             ||  | |
    MMI_FACTORY_CFG_END()                                                    ||  | |
};                                                                           ||  | |
                                                                             ||  | |
/* For the detail information, please refer to the FactoryGprot.h */         ||  | |
mmi_factory_obj_struct *mmi_factory_new_obj(                <----------------+|  | |
    const mmi_factory_cfg_struct *cfg_table,                                  |  | |
    mmi_factory_malloc_func_ptr alloc)                                        |  | |
{                                                                             |  | |
    /*----------------------------------------------------------------*/      |  | |
    /* Local Variables                                                */      |  | |
    /*----------------------------------------------------------------*/      |  | |
    U16 type;                                                                 |  | |
                                                                              |  | |
    /*----------------------------------------------------------------*/      |  | |
    /* Code Body                                                      */      |  | |
    /*----------------------------------------------------------------*/      |  | |
    type = mmi_factory_get_favorite_type(cfg_table);           -----------+   |  | |
                                                                          |   |  | |
    if (type == MMI_FACTORY_TYPE_INVALID)                                 |   |  | |
    {                                                                     |   |  | |
        return NULL;                                                      |   |  | |
    }                                                                     |   |  | |
                                                                          |   |  | |
    return mmi_factory_new_obj_ex(type, cfg_table, alloc);   -------------*-+ |  | |
}                                                                         | | |  | |
                                                                          | | |  | |
/* For the detail information, please refer to the FactoryGprot.h */      | | |  | |
S16 mmi_factory_get_favorite_type(                    <-------------------+ | |  | |
    const mmi_factory_cfg_struct *cfg_table)                                | |  | |
{                                                                           | |  | |
    /*----------------------------------------------------------------*/    | |  | |
    /* Local Variables                                                */    | |  | |
    /*----------------------------------------------------------------*/    | |  | |
    const mmi_factory_cfg_struct *cfg;                                      | |  | |
                                                                            | |  | |
    /*----------------------------------------------------------------*/    | |  | |
    /* Code Body                                                      */    | |  | |
    /*----------------------------------------------------------------*/    | |  | |
    for (cfg = &cfg_table[0]; cfg; cfg = mmi_factory_get_next_cfg(cfg))     | |  | |
    {                                                                       | |  | |
        if (cfg->on_want_to_run && cfg->on_want_to_run())  -------+         | |  | |
        {                                                         |         | |  | |
            return cfg->type;                                     |         | |  | |
        }                                                         |         | |  | |
    }                                                             |         | |  | |
                                                                  |         | |  | |
    return MMI_FACTORY_TYPE_INVALID;                              |         | |  | |
}                                                                 |         | |  | |
                                                                  |         | |  | |
MMI_BOOL mmi_idle_obj_on_want_to_run(void)            <-----------+         | |  | |
{                                                                           | |  | |
    /*----------------------------------------------------------------*/    | |  | |
    /* Local Variables                                                */    | |  | |
    /*----------------------------------------------------------------*/    | |  | |
                                                                            | |  | |
    /*----------------------------------------------------------------*/    | |  | |
    /* Code Body                                                      */    | |  | |
    /*----------------------------------------------------------------*/    | |  | |
    return MMI_TRUE;                                                        | |  | |
}                                                                           | |  | |
                                                                            | |  | |
/* For the detail information, please refer to the FactoryGprot.h */        | |  | |
mmi_factory_obj_struct *mmi_factory_new_obj_ex(         <-------------------+ |  | |
    U16 type,                                                                 |  | |
    const mmi_factory_cfg_struct *cfg_table,                                  |  | |
    mmi_factory_malloc_func_ptr alloc_func)                                   |  | |
{                                                                             |  | |
    /*----------------------------------------------------------------*/      |  | |
    /* Local Variables                                                */      |  | |
    /*----------------------------------------------------------------*/      |  | |
    const mmi_factory_cfg_struct *cfg;                                        |  | |
    mmi_factory_obj_struct *obj;                                              |  | |
                                                                              |  | |
    /*----------------------------------------------------------------*/      |  | |
    /* Code Body                                                      */      |  | |
    /*----------------------------------------------------------------*/      |  | |
    cfg = mmi_factory_get_cfg(type, cfg_table);         --------------+       |  | |
    if (!cfg)                                                         |       |  | |
    {                                                                 |       |  | |
        return NULL;                                                  |       |  | |
    }                                                                 |       |  | |
                                                                      |       |  | |
    // p = (mmi_idle_launcher_struct *)obj;                           |       |  | |
    obj = (mmi_factory_obj_struct *)alloc_func(cfg->size);            |       |  | |
                                                                      |       |  | |
    kal_mem_set(obj, 0, cfg->size);                                   |       |  | |
                                                                      |       |  | |
    obj->type = type;                                                 |       |  | |
                                                                      |       |  | |
    if (cfg->on_init)                                                 |       |  | |
    {                                                                 |       |  | |
        cfg->on_init(obj);                    ------------------------*-------+  | |
    }                                                                 |       |  | |
                                                                      |       |  | |
    return obj;                                                       |       |  | |
}                                                                     |       |  | |
                                                                      |       |  | |
const mmi_factory_cfg_struct *mmi_factory_get_cfg(          <---------+       |  | |
    U16 type,                                                                 |  | |
    const mmi_factory_cfg_struct *cfg_table)                                  |  | |
{                                                                             |  | |
    /*----------------------------------------------------------------*/      |  | |
    /* Local Variables                                                */      |  | |
    /*----------------------------------------------------------------*/      |  | |
    const mmi_factory_cfg_struct *cfg;                                        |  | |
                                                                              |  | |
    /*----------------------------------------------------------------*/      |  | |
    /* Code Body                                                      */      |  | |
    /*----------------------------------------------------------------*/      |  | |
    for (cfg = &cfg_table[0]; cfg; cfg = mmi_factory_get_next_cfg(cfg))       |  | |
    {                                                                         |  | |
        if (cfg->type == type)                                                |  | |
        {                                                                     |  | |
            return cfg;                                                       |  | |
        }                                                                     |  | |
    }                                                                         |  | |
                                                                              |  | |
    return NULL;                                                              |  | |
}                                                                             |  | |
                                                                              |  | |
void mmi_idle_launcher_on_init(mmi_idle_obj_struct *obj)           <----------+  | |
{                                                                                | |
    /*----------------------------------------------------------------*/         | |
    /* Local Variables                                                */         | |
    /*----------------------------------------------------------------*/         | |
    mmi_idle_launcher_struct *p;                                                 | |
    U32 *capability;                                                             | |
                                                                                 | |
    /*----------------------------------------------------------------*/         | |
    /* Code Body                                                      */         | |
    /*----------------------------------------------------------------*/         | |
    mmi_idle_obj_on_init(obj);                      -------------+               | |
                                                                 |               | |
    p = (mmi_idle_launcher_struct *)obj;                         |               | |
                                                                 |               | |
    /* Member variable. */                                       |               | |
    p->type = MMI_IDLE_TYPE_LAUNCHER;                            |               | |
                                                                 |               | |
    /* Member function. */                                       |               | |
    p->on_enter = mmi_idle_launcher_on_enter;       -------------*---------------*-*-+
                                                                 |               | | |
    /* Change the capabilities. */                               |               | | |
    capability = &obj->capability;                               |               | | |
                                                                 |               | | |
    *capability &= ~ENABLE_SOFT_KEY_AREA;                        |               | | |
    *capability &= ~ENABLE_CENTER_SOFT_KEY;                      |               | | |
    *capability &= ~ENABLE_END_KEY;                              |               | | |
}                                                                |               | | |
                                                                 |               | | |
void mmi_idle_obj_on_init(mmi_idle_obj_struct *obj)     <--------+               | | |
{                                                                                | | |
    /*----------------------------------------------------------------*/         | | |
    /* Local Variables                                                */         | | |
    /*----------------------------------------------------------------*/         | | |
                                                                                 | | |
    /*----------------------------------------------------------------*/         | | |
    /* Code Body                                                      */         | | |
    /*----------------------------------------------------------------*/         | | |
    MMI_ASSERT(obj);                                                             | | |
                                                                                 | | |
    obj->capability = ENABLE_FULL;                                               | | |
                                                                                 | | |
    /* Member function. */                                                       | | |
    obj->on_create = mmi_idle_obj_on_create;               ----------------------+ | |
    obj->on_close = mmi_idle_obj_on_close;                                       | | |
    obj->on_run = mmi_idle_obj_on_run;                                           | | |
    obj->on_enter = mmi_idle_obj_on_enter;                                       | | |
    obj->on_exit = mmi_idle_obj_on_exit;                                         | | |
    obj->on_update_service_area = mmi_idle_obj_on_update_service_area;           | | |
    obj->on_before_idle_display = mmi_idle_obj_on_before_idle_display;           | | |
}                                                                                | | |
                                                                                 | | |
mmi_id mmi_idle_obj_on_create(mmi_idle_obj_struct *obj, mmi_id parent_gid) <-----+ | |
{                                                                                  | |
    /*----------------------------------------------------------------*/           | |
    /* Local Variables                                                */           | |
    /*----------------------------------------------------------------*/           | |
    mmi_id this_gid;                                                               | |
                                                                                   | |
    /*----------------------------------------------------------------*/           | |
    /* Code Body                                                      */           | |
    /*----------------------------------------------------------------*/           | |
    MMI_ASSERT(obj);                                                               | |
                                                                                   | |
    this_gid = mmi_frm_group_create(                                               | |
                parent_gid,                                                        | |
                GRP_ID_AUTO_GEN,                                                   | |
                mmi_idle_obj_evt_hdlr,          ----------------------+            | |
                obj);                                                 |            | |
                                                                      |            | |
    MMI_ASSERT(this_gid != GRP_ID_INVALID);                           |            | |
                                                                      |            | |
    obj->parent_gid = parent_gid;                                     |            | |
    obj->this_gid = this_gid;                                         |            | |
                                                                      |            | |
    return this_gid;                                                  |            | |
}                                                                     |            | |
                                                                      |            | |
static mmi_ret mmi_idle_obj_evt_hdlr(mmi_event_struct *event)  <------+            | |
{                                                                                  | |
    /*----------------------------------------------------------------*/           | |
    /* Local Variables                                                */           | |
    /*----------------------------------------------------------------*/           | |
    mmi_idle_obj_struct *obj;                                                      | |
                                                                                   | |
    /*----------------------------------------------------------------*/           | |
    /* Code Body                                                      */           | |
    /*----------------------------------------------------------------*/           | |
    MMI_ASSERT(event && event->user_data);                                         | |
                                                                                   | |
    obj = (mmi_idle_obj_struct *)event->user_data;                                 | |
                                                                                   | |
    switch (event->evt_id)                                                         | |
    {                                                                              | |
        case EVT_ID_GROUP_DEINIT:                                                  | |
            mmi_factory_delete_obj(                                                | |
                (mmi_factory_obj_struct *)obj,                                     | |
                mmi_idle_get_cfg_table(),                                          | |
                mmi_idle_buffer_free);                                             | |
            mmi_idle_launch_new_obj();                                             | |
            break;                                                                 | |
                                                                                   | |
        default:                                                                   | |
            break;                                                                 | |
    }                                                                              | |
                                                                                   | |
    return MMI_RET_OK;                                                             | |
}                                                                                  | |
                                                                                   | |
void mmi_idle_obj_on_run(mmi_idle_obj_struct *obj)            <--------------------+ |
{                                                                                    |
    /*----------------------------------------------------------------*/             |
    /* Local Variables                                                */             |
    /*----------------------------------------------------------------*/             |
                                                                                     |
    /*----------------------------------------------------------------*/             |
    /* Code Body                                                      */             |
    /*----------------------------------------------------------------*/             |
    MMI_ASSERT(obj);                                                                 |
                                                                                     |
    mmi_frm_group_enter(obj->this_gid, MMI_FRM_NODE_SMART_CLOSE_FLAG);               |
                                                                                     |
    mmi_frm_scrn_first_enter(                                                        |
        obj->this_gid,                                                               |
        SCR_ID_IDLE_MAIN,                                                            |
        (FuncPtr)mmi_idle_obj_enter,       ----------------------------+             |
        obj);                                                          |             |
}                                                                      |             |
                                                                       |             |
static void mmi_idle_obj_enter(mmi_scrn_essential_struct *param)  <----+             |
{                                                                                    |
    /*----------------------------------------------------------------*/             |
    /* Local Variables                                                */             |
    /*----------------------------------------------------------------*/             |
    mmi_idle_obj_struct *obj;                                                        |
    MMI_BOOL ret;                                                                    |
                                                                                     |
    /*----------------------------------------------------------------*/             |
    /* Code Body                                                      */             |
    /*----------------------------------------------------------------*/             |
    MMI_ASSERT(param && param->user_data);                                           |
                                                                                     |
    obj = (mmi_idle_obj_struct *)param->user_data;                                   |
                                                                                     |
    ret = mmi_frm_scrn_enter(                                                        |
            param->group_id,                                                         |
            param->scrn_id,                                                          |
            (FuncPtr)mmi_idle_obj_exit,                                              |
            (FuncPtr)mmi_idle_obj_enter,                                             |
            MMI_FRM_FULL_SCRN);                                                      |
                                                                                     |
    if (!ret)                                                                        |
    {                                                                                |
        MMI_IDLE_LOG((TRC_MMI_IDLE_OBJ_ENTER, 500));                                 |
        return;                                                                      |
    }                                                                                |
                                                                                     |
    MMI_IDLE_LOG((TRC_MMI_IDLE_OBJ_ENTER, 200));                                     |
                                                                                     |
    /* Fail-safe to avoid APP from deleting the idle screen incorrectly. */          |
    mmi_frm_scrn_set_leave_proc(                                                     |
        param->group_id,                                                             |
        param->scrn_id,                                                              |
        mmi_idle_obj_leave_proc);                                                    |
                                                                                     |
    /* Enter idle screen and update the service area. */                             |
    MMI_ASSERT(obj && obj->on_enter && obj->on_update_service_area);                 |
    obj->on_enter(obj);                                            ------------------+
    obj->on_update_service_area(obj);                                                |
                                                                                     |
   // mmi_idle_wrap_soft_key_hdlr();                                                 |
                                                                                     |
    /* Emit the event if this isn't used to draw the background. */                  |
    if (!mmi_is_redrawing_bk_screens())                                              |
    {                                                                                |
        mmi_idle_emit_enter(obj);                                                    |
        mmi_idle_notify_event();                                                     |
    }                                                                                |
}                                                                                    |
                                                                                     |
static void mmi_idle_launcher_on_enter(mmi_idle_obj_struct *obj)   <-----------------+
{
    /*----------------------------------------------------------------*/
    /* Local Variables                                                */
    /*----------------------------------------------------------------*/
    mmi_idle_launcher_struct *p;

    /*----------------------------------------------------------------*/
    /* Code Body                                                      */
    /*----------------------------------------------------------------*/
    p = (mmi_idle_launcher_struct *)obj;

    /* Venus Category Screen: */
    vapp_desktop_create(p->this_gid);

    ExitCategoryFunction = vapp_desktop_release;

    /* Key handler: */
    mmi_idle_set_handler((mmi_idle_obj_struct *)p);             ----------------+
                                                                                |
    ClearKeyEvents();                                                           |
}                                                                               |
                                                                                |
void mmi_idle_set_handler(mmi_idle_obj_struct *obj)             <---------------+
{
    /*----------------------------------------------------------------*/
    /* Local Variables                                                */
    /*----------------------------------------------------------------*/
    U32 capability;

    /*----------------------------------------------------------------*/
    /* Code Body                                                      */
    /*----------------------------------------------------------------*/
    MMI_ASSERT(obj);

    capability = obj->capability;

#ifdef __MMI_IDLE_CLASSIC_AND_MAINMENU_SUPPORT__
    if (capability & ENABLE_LEFT_SOFT_KEY)
    {
        if (!(obj->capability & ENABLE_SOFT_KEY_AREA))
        {
            //SetKeyHandler(EntryMainMenuFromIdleScreen, KEY_LSK, KEY_EVENT_DOWN);
            SetKeyDownHandler(EntryMainMenuFromIdleScreen, KEY_LSK);
        }
        else
        {
            SetLeftSoftkeyFunction(EntryMainMenuFromIdleScreen, KEY_EVENT_UP); ---+
            ChangeLeftSoftkey(STR_ID_IDLE_MAIN_MENU, 0);                          |
        }                                                                         |
    }                                                                             |
#endif /*__MMI_IDLE_CLASSIC_AND_MAINMENU_SUPPORT__*/                              |
                                                                                  |
#ifndef __MMI_BTD_BOX_UI_STYLE__                                                  |
    if (capability & ENABLE_RIGHT_SOFT_KEY)                                       |
    {                                                                             |
        mmi_idle_set_right_soft_key_hdlr();                    -----------------+ |
    }                                                                           | |
#else                                                                           | |
  SetKeyHandler(mmi_scr_locker_launch, KEY_RSK, KEY_EVENT_UP);                  | |
#endif                                                                          | |
                                                                                | |
    [...省略]                                                                   | |
}                                                                               | |
                                                                                | |
static void mmi_idle_set_right_soft_key_hdlr(void)             <----------------+ |
{                                                                                 |
    /*----------------------------------------------------------------*/          |
    /* Local Variables                                                */          |
    /*----------------------------------------------------------------*/          |
    U16 str_id = 0;                                                               |
    FuncPtr hdlr = NULL;                                                          |
                                                                                  |
    /*----------------------------------------------------------------*/          |
    /* Code Body                                                      */          |
    /*----------------------------------------------------------------*/          |
    /*                                                                            |
     * Get the handler and string.                                                |
     */                                                                           |
                                                                                  |
#ifdef __MMI_BT_DIALER_SUPPORT__                                                  |
    {                                                                             |
        if (GetIdleScreenBTDialerConnectionStatus())                              |
        {                                                                         |
            str_id = STR_ID_IDLE_BTDIALER_DISCONNECT;                             |
            hdlr = mmi_idle_BT_dialer_disconnect;                                 |
        }                                                                         |
        else                                                                      |
        {                                                                         |
            str_id = STR_ID_IDLE_BTDIALER_CONNECT;                                |
            hdlr   = mmi_idle_BT_dialer_connect;                                  |
        }                                                                         |
    }                                                                             |
#else                                                                             |
    {                                                                             |
        str_id = STR_ID_IDLE_CONTACT;                                             |
        hdlr   = mmi_phb_idle_launch;                                             |
    }                                                                             |
#endif                                                                            |
                                                                                  |
    /*                                                                            |
     * Set the handler and string.                                                |
     */                                                                           |
    mmi_idle_set_rsk_hdlr(hdlr);                   ---------+                     |
    mmi_idle_set_rsk_view(str_id, 0);              ---------|--------------+      |
}                                                           |              |      |
                                                            |              |      |
static void mmi_idle_set_rsk_hdlr(FuncPtr hdlr)    ---------+              |      |
{                                                                          |      |
    /*----------------------------------------------------------------*/   |      |
    /* Local Variables                                                */   |      |
    /*----------------------------------------------------------------*/   |      |
    mmi_idle_obj_struct *obj = mmi_idle_get_obj();                         |      |
                                                                           |      |
    /*----------------------------------------------------------------*/   |      |
    /* Code Body                                                      */   |      |
    /*----------------------------------------------------------------*/   |      |
    MMI_ASSERT(obj);                                                       |      |
                                                                           |      |
    if (hdlr)                                                              |      |
    {                                                                      |      |
        if (!(obj->capability & ENABLE_SOFT_KEY_AREA))                     |      |
        {                                                                  |      |
            //SetKeyHandler(hdlr, KEY_RSK, KEY_EVENT_DOWN);                |      |
            SetKeyDownHandler(hdlr, KEY_RSK);                              |      |
        }                                                                  |      |
        else                                                               |      |
        {                                                                  |      |
            SetRightSoftkeyFunction(hdlr, KEY_EVENT_UP);                   |      |
        }                                                                  |      |
    }                                                                      |      |
}                                                                          |      |
                                                                           |      |
static void mmi_idle_set_rsk_view(U16 string_id, U16 image_id)    <--------+      |
{                                                                                 |
    /*----------------------------------------------------------------*/          |
    /* Local Variables                                                */          |
    /*----------------------------------------------------------------*/          |
    mmi_idle_obj_struct *obj = mmi_idle_get_obj();                                |
                                                                                  |
    /*----------------------------------------------------------------*/          |
    /* Code Body                                                      */          |
    /*----------------------------------------------------------------*/          |
    MMI_ASSERT(obj);                                                              |
                                                                                  |
    if (obj->capability & ENABLE_SOFT_KEY_AREA)                                   |
    {                                                                             |
        ChangeRightSoftkey(string_id, image_id);                                  |
    }                                                                             |
}                                                                                 |
                                                                                  |
void EntryMainMenuFromIdleScreen(void)            <-------------------------------+
{
    /*----------------------------------------------------------------*/
    /* Local Variables                                                */
    /*----------------------------------------------------------------*/

    /*----------------------------------------------------------------*/
    /* Code Body                                                      */
    /*----------------------------------------------------------------*/
    goto_main_menu();
}
```

