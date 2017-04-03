//
//  PJHelper.m
//  ipjsua
//
//  Created by Vinh Thien on 11/10/16.
//  Copyright © 2016 Teluu. All rights reserved.
//

#import "xaax_sip_helper.h"

#import <pjlib.h>
#import <pjsua.h>
#import <pj/log.h>

#import "xaax_sqlite_helper.h"

#define THIS_FILE	"xaax_sip_helper.m"

struct tcall
{
    char * remote_contact_id;
    char * remote_contact_name;
    const char * remote_username;
    const char * domain;
    int call_history_id;
    
};

struct tacc
{
    //pjsua_acc_config * config;
    //pjsua_acc_info * info;
    const char * username;
    const char * domain;
    char * password;
    const char * transport;
    const char * port;
};

struct tdigit_tone
{
    pj_pool_t          *pool;
    pjmedia_port       *tonegen;
    pjsua_conf_port_id  toneslot;
};

struct tsip
{
    struct tdigit_tone *digit_tone;
};

static struct tsip *sip_data;

pj_status_t status;

static void on_all_accounts_return( int acc_id, const char * username, const char * password, const char * domain, const char * port );
static void on_incoming_call( pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata );
static void on_call_state( pjsua_call_id call_id, pjsip_event *e );
static void on_call_media_state( pjsua_call_id call_id );
static void on_reg_state( pjsua_acc_id acc_id );
static void error_exit( const char *title, pj_status_t status );

// MARK: PROTOTYPE PRIVATE METHODS

void xaax_call_init_tonegen(struct tdigit_tone *cd, pjsua_call_id call_id);
void xaax_call_deinit_tonegen(struct tdigit_tone *cd);
void xaax_call_play_digit_for_call(const char digit, pjsua_call_id call_id);
int xaax_get_account_id (pjsua_acc_id *ret_acc_id, const char *username, const char *domain, const char *port);
static void xaax_uri_parse ( const char *uri, char ** username, char ** domain);
static char * extract_between(const char *str, const char *p1, const char *p2);
static int get_call_id_by_remote( const char * remote_username, pjsua_call_id *call_id );
static void remove_char(char *str, char garbage);


void (*cb_registration_update)(const char * username, const char * domain, xaax_status_t status);
void (*cb_call_update)(const char * remote_username, const char * remote_contact_name, const char * domain, long duration, xaax_status_t status);


void xaax_init(const char * db_name) {
    /* Create pjsua */
    status = pjsua_create();
    if ( status != PJ_SUCCESS ) {
        error_exit( "Error in pjsua_create()", status );
    }
    
    /* Init pjsua */
    pjsua_config cfg;
    
    // Init the logging config structure
    pjsua_logging_config log_cfg;
    pjsua_logging_config_default(&log_cfg);
    log_cfg.console_level = 5;
    
    pjsua_config_default( &cfg );
    cfg.cb.on_incoming_call = &on_incoming_call;
    cfg.cb.on_call_media_state = &on_call_media_state;
    cfg.cb.on_call_state = &on_call_state;
    cfg.cb.on_reg_state = &on_reg_state;
    
//    cfg.outbound_proxy = ""
    
    
    // Configure the media information for the endpoint.
//    pjsua_media_config media_config;
//    pjsua_media_config_default(&media_config);
    
    //cfg.stun_host = pj_str("stun.l.google.com:19302");
//    media_config.enable_ice = false;
//    mediaConfig.clock_rate = (unsigned int)cfg.clockRate == 0 ? PJSUA_DEFAULT_CLOCK_RATE : (unsigned int)cfg.clockRate;
//    mediaConfig.snd_clock_rate = (unsigned int)cfg.sndClockRate;
    
    
    status = pjsua_init( &cfg, &log_cfg, NULL );
    if ( status != PJ_SUCCESS ) {
        error_exit( "Error in pjsua_init()", status );
    }
    
    /* Add UDP transport */
    {
        pjsua_transport_config cfg;
        
        pjsua_transport_config_default( &cfg );
        cfg.port = 10020;
        //cfg.port = 5060;
//        cfg.port_range
        status = pjsua_transport_create( PJSIP_TRANSPORT_UDP, &cfg, NULL );
        if ( status != PJ_SUCCESS ) {
            error_exit( "Error creating transport", status );
        }
    }
    
    /* Add TCP transport */
//    {
//        pjsua_transport_config cfg;
//        
//        pjsua_transport_config_default( &cfg );
//        cfg.port = 5060;
//        status = pjsua_transport_create( PJSIP_TRANSPORT_TCP, &cfg, NULL );
//        if ( status != PJ_SUCCESS ) {
//            error_exit( "Error creating transport", status );
//        }
//    }
    
    
    /* Start pjsua */
    status = pjsua_start();
    if ( status != PJ_SUCCESS ) {
        error_exit( "Error starting pjsua", status );
    }
    
    /* Enable Codecs */
    unsigned count;
    pjsua_codec_info c[32];
    pj_status_t status = pjsua_enum_codecs(c, &count);
    if (status == PJ_SUCCESS) {
        for (int index = 0; index < count; index++) {
            pjsua_codec_info codec_info = c[index];
            if (index == 5 || index == 6) { // PCMU || PCMA
                pjsua_codec_set_priority(&codec_info.codec_id,
                                     PJMEDIA_CODEC_PRIO_NORMAL);
            } else {
                pjsua_codec_set_priority(&codec_info.codec_id,
                                         PJMEDIA_CODEC_PRIO_DISABLED);
            }
        }
    }
    
    /* Init SIP DATA */
    sip_data = malloc(sizeof(struct tsip));
    
    /*
    struct tdigit_tone *digit_tone = malloc(sizeof(struct tdigit_tone));
    digit_tone->pool = NULL;
    digit_tone->tonegen = NULL;
    digit_tone->toneslot = 0;
    sip_data->digit_tone = digit_tone;
    */
    /* Init DB */
    init_db(db_name);
    set_cb_all_accounts_returned(on_all_accounts_return);
    
}

void xaax_deinit(void) {
    close_db();
    xaax_call_deinit_tonegen(sip_data->digit_tone);
    free(sip_data);
    pjsua_destroy();
}

const char* get_current_incall_remote_username(void) {
    for (pjsua_call_id call_id = 0; call_id < pjsua_call_get_max_count(); call_id++) {
        if (pjsua_call_is_active(call_id)) {
            struct tcall *call_data = pjsua_call_get_user_data(call_id);
            return call_data->remote_username;
        }
    }
    return "";
}

int get_default_account (const char **username, char **password, const char **domain, const char **transport, const char **displayName, const char **proxy, const char **port) {
    if (pjsua_acc_get_count() == 0) {
        return -1;
    }
    pjsua_acc_id default_acc_id = pjsua_acc_get_default();
    if (default_acc_id != PJSUA_INVALID_ID) {

        struct tacc* acc = pjsua_acc_get_user_data(default_acc_id);
        *username = acc->username;
        *domain = acc->domain;
        *transport = acc->transport;
        *port = acc->port;
        select_password_from_account(*username, *domain, password);
        return 0;
    }
    return -1;
}


int xaax_refresh_accounts(void) {
    int acc_count = pjsua_acc_get_count();
    if (acc_count == 0) {
        int count = 0 ;
        select_all_accounts(&count);
        if (count == 0) {
            return 1;
        }
    }
    return 0;
}


void xaax_add_account(const char * username,
                      const char * password,
                      const char * domain,
                      const char * transport,
                      const char * port) {
    
    pjsua_acc_id acc_id;
    int result = xaax_get_account_id(&acc_id, username, domain, port);
    if (result == PJ_TRUE) {
        pjsua_acc_set_default(acc_id);
        pjsua_acc_set_registration(acc_id, PJ_TRUE);
    } else {
        char tmp[256];
        sprintf(tmp, "sip:%s@%s:%s", username, domain, port);
        char *contact = malloc(sizeof(tmp) + 3);
        sprintf(contact, "%s", tmp);
        
        sprintf(tmp, "sip:%s:%s;transport=%s", domain, port, transport);
        char *reg_uri = malloc(sizeof(tmp) + 3);
        sprintf(reg_uri, "%s", tmp);
        
        sprintf(tmp, "%s", domain);
        char *realm = malloc(sizeof(tmp) + 3);
        sprintf(realm, "%s", tmp);
        
        
        
        pjsua_acc_config acc_cfg;
        
        pjsua_acc_config_default(&acc_cfg);
        acc_cfg.id = pj_str(contact);
        acc_cfg.reg_uri = pj_str(reg_uri);
        acc_cfg.cred_count = 1;
        acc_cfg.cred_info[0].scheme = pj_str("Digest");
        acc_cfg.cred_info[0].realm = pj_str("*"); // or try realm
        acc_cfg.cred_info[0].username = pj_str(strdup(username));
        acc_cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
        acc_cfg.cred_info[0].data = pj_str(strdup(password));
        
        acc_cfg.media_stun_use = PJSUA_STUN_USE_DEFAULT;
        acc_cfg.sip_stun_use = PJSUA_STUN_USE_DEFAULT;
        
        pjsua_transport_config cfg;
        pjsua_transport_config_default( &cfg );
        cfg.port = 4000;
        acc_cfg.rtp_cfg = cfg;
        
        
        
//        acc_cfg.rtp_cfg = app_config.rtp_cfg;
    //    app_config_init_video(&acc_cfg);
        
        PJ_LOG(3,(THIS_FILE,"regAcc: reguri=%s dom=%s user=%s pass=%s", reg_uri,domain,username,password));
        
        pjsua_acc_id p_acc_id;
        status = pjsua_acc_add(&acc_cfg, PJ_TRUE, &p_acc_id);
        if (status != PJ_SUCCESS) {
            pjsua_perror(THIS_FILE, "Error adding new account", status);
            return;
        }
        
        sprintf(tmp, "%s", password);
        char * password_store = malloc(sizeof(tmp) + 3);
        sprintf(password_store, "%s", tmp);
        
        sprintf(tmp, "%s", username);
        char * username_store = malloc(sizeof(tmp) + 3);
        sprintf(username_store, "%s", tmp);
        
        sprintf(tmp, "%s", domain);
        char * domain_store = malloc(sizeof(tmp) + 3);
        sprintf(domain_store, "%s", tmp);
        
        sprintf(tmp, "%s", transport);
        char * transport_store = malloc(sizeof(tmp) + 3);
        sprintf(transport_store, "%s", tmp);
        
        sprintf(tmp, "%s", port);
        char * port_store = malloc(sizeof(tmp) + 3);
        sprintf(port_store, "%s", tmp);
        
        
        pjsua_acc_info info;
        pjsua_acc_get_info(p_acc_id, &info);
        struct tacc *acc = malloc (sizeof (struct tacc));
        //acc->config = &acc_cfg;
        //acc->info = &info;
        acc->username = username_store;
        acc->domain = domain_store;
        acc->password = password_store;
        acc->transport = transport_store;
        acc->port = port_store;
        pjsua_acc_set_user_data(p_acc_id, acc);
    }
    
}

void xaax_check_account_registration(const char * username,
                      const char * domain) {
    for (int acc_id=0; acc_id<(int)pjsua_acc_get_count(); acc_id++) {
        if (!pjsua_acc_is_valid(acc_id)) {
            pjsua_acc_info info;
            pjsua_acc_get_info(acc_id, &info);
            char * tmp_username;
            char * tmp_domain;
            xaax_uri_parse(info.acc_uri.ptr, &tmp_username, &tmp_domain);
            if (strcmp(tmp_domain, domain) == 0 &&
                    strcmp(tmp_username, username)) {
                on_reg_state(acc_id);
                return;
            }
            
        }
    }
}

void xaax_remove_all_account() {
    for (pjsua_acc_id acc_id = 0; acc_id < pjsua_acc_get_count(); acc_id++) {
        if (pjsua_acc_is_valid(acc_id)) {
            pjsua_acc_del(acc_id);
        }
    }
    
}

void xaax_send_dtmf(const char * remote_username, const char digit) {
    pjsua_call_id callid;
    int i = get_call_id_by_remote(remote_username, &callid);
    if (i == PJ_SUCCESS) {
        const pj_str_t digit_str = pj_str(strdup(&digit));
        pjsua_call_dial_dtmf(callid, &digit_str);
    }
    
}

int xaax_count_active_calls ( void ) {
    return pjsua_call_get_count();
}

int xaax_make_single_call(const char * username, const char * contact_id, const char * contact_name )
{
    pjsua_acc_id default_acc_id = pjsua_acc_get_default();
    
    struct tacc *acc = pjsua_acc_get_user_data(default_acc_id);
    
    char callee_uri[256];
    sprintf(callee_uri, "sip:%s@%s:%s", username, acc->domain, acc->port);
    pj_str_t uri = pj_str(callee_uri);
    pjsua_call_id p_call_id;
    
    char tmp[256];
    sprintf(tmp, "%s", contact_id);
    char *tmp_contact_id = malloc(sizeof(tmp) + 3);
    sprintf(tmp_contact_id, "%s", tmp);
    
    sprintf(tmp, "%s", contact_name);
    char *tmp_contact_name = malloc(sizeof(tmp) + 3);
    sprintf(tmp_contact_name, "%s", tmp);
    
    
    struct tcall *tcall_save = malloc(sizeof(struct tcall));
    
    tcall_save->remote_contact_name = tmp_contact_name;
    tcall_save->remote_contact_id = tmp_contact_id;
    
    pjsua_call_set_user_data(p_call_id, tcall_save);
    
    pj_status_t status = pjsua_call_make_call(default_acc_id, &uri, 0, tcall_save, NULL, &p_call_id);
    if (status != PJ_SUCCESS) {
        pjsua_perror(THIS_FILE, "Error making call", status);
        return -1;
    }

    return p_call_id;
}

bool xaax_hangup_call_by_callid (int callid) {
    pjsua_call_id call_id = callid;
    pj_str_t reason = pj_str("User end call");
    pjsua_call_hangup(call_id, 500, &reason, NULL);
    return true;
}

bool xaax_hangup_call_by_remote (const char * remote_username) {
    pjsua_call_id callid;
    int i = get_call_id_by_remote(remote_username, &callid);
    if (i == PJ_SUCCESS) {
        pj_str_t reason = pj_str("User end call");
        pj_status_t status = pjsua_call_hangup(callid, 500, &reason, NULL);
        
        return (PJ_SUCCESS == status);
    }
    return false;
}

void xaax_accept_call_by_callid (int callid) {
    pjsua_call_id call_id = callid;
    pjsua_call_answer( call_id, 200, NULL, NULL );
}

void xaax_accept_call_by_remote (const char * remote_username) {
    pjsua_call_id callid;
    int i = get_call_id_by_remote(remote_username, &callid);
    if (i == PJ_SUCCESS) {
        pjsua_call_answer( callid, 200, NULL, NULL );
    }
}

void xaax_pause_call_by_callid (int callid) {
    pjsua_call_id call_id = callid;
    pjsua_call_set_hold( call_id, NULL );
}

void xaax_pause_call_by_remote (const char * remote_username) {
    pjsua_call_id callid;
    int i = get_call_id_by_remote(remote_username, &callid);
    if (i == PJ_SUCCESS) {
        pjsua_call_set_hold( callid, NULL );
    }
}

void xaax_resume_call_by_callid (int callid) {
    pjsua_call_id call_id = callid;
    pjsua_call_set_hold( call_id, NULL );
}

void xaax_resume_call_by_remote (const char * remote_username) {
    pjsua_call_id callid;
    int i = get_call_id_by_remote(remote_username, &callid);
    if (i == PJ_SUCCESS) {
        pjsua_call_set_hold( callid, NULL );
    }
}

void xaax_mute_by_callid (int call_id) {
    pjsua_call_info ci;
    pjsua_call_get_info(call_id, &ci);
    pjsua_conf_port_id audio_port_id = ci.conf_slot;
    if( audio_port_id != 0 ) {
        NSLog(@"WC_SIPServer microphone disconnected from call");
        pjsua_conf_disconnect(0, audio_port_id);
    }
}

void xaax_mute_by_remote (const char * remote_username) {
    pjsua_call_id callid;
    int i = get_call_id_by_remote(remote_username, &callid);
    if (i == PJ_SUCCESS) {
        pjsua_call_info ci;
        pjsua_call_get_info(callid, &ci);
        pjsua_conf_port_id audio_port_id = ci.conf_slot;
        if( audio_port_id != 0 ) {
            NSLog(@"WC_SIPServer microphone disconnected from call");
            pjsua_conf_disconnect(0, audio_port_id);
        }
    }
}

void xaax_unmute_by_callid (int call_id) {
    pjsua_call_info ci;
    pjsua_call_get_info(call_id, &ci);
    pjsua_conf_port_id audio_port_id = ci.conf_slot;
    if( audio_port_id != 0 ) {
        NSLog(@"WC_SIPServer microphone reconnected to call");
        pjsua_conf_connect(0, audio_port_id);
    }
}

void xaax_unmute_by_remote (const char * remote_username) {
    pjsua_call_id callid;
    int i = get_call_id_by_remote(remote_username, &callid);
    if (i == PJ_SUCCESS) {
        pjsua_call_info ci;
        pjsua_call_get_info(callid, &ci);
        pjsua_conf_port_id audio_port_id = ci.conf_slot;
        if( audio_port_id != 0 ) {
            NSLog(@"WC_SIPServer microphone reconnected to call");
            pjsua_conf_connect(0, audio_port_id);
        }
    }
}

// doesn't work
void xaax_enable_loudspeaker (void) {
    pjmedia_aud_dev_route route = PJMEDIA_AUD_DEV_ROUTE_LOUDSPEAKER;
    pj_status_t status = pjsua_snd_set_setting(PJMEDIA_AUD_DEV_CAP_INPUT_ROUTE, &route, PJ_FALSE);
    if (status != PJ_SUCCESS){
        NSLog(@"Error enabling loudspeaker");
    }
    
}

// doesn't work
void xaax_disable_loudspeaker (void) {
    pjmedia_aud_dev_route route = PJMEDIA_AUD_DEV_ROUTE_DEFAULT;
    pj_status_t status = pjsua_snd_set_setting(PJMEDIA_AUD_DEV_CAP_INPUT_ROUTE, &route, PJ_FALSE);
    if (status != PJ_SUCCESS){
        NSLog(@"Error disabling loudspeaker");
    }
}

void xaax_call_init_tonegen(struct tdigit_tone *digit_tone, pjsua_call_id call_id)
{
    
    
    struct tdigit_tone *cd = digit_tone;
    
    pj_pool_t *pool;
    
    
    /* Create memory pool for our file player */
    pool = pjsua_pool_create("mycall",	/* pool name.	    */
                              4000,	    /* init size	    */
                              4000	    /* increment size   */
                              );
    cd->pool = pool;
    
    
    int SAMPLES_PER_FRAME = 64;
    pjmedia_port *tonegen;
    pjmedia_tonegen_create(cd->pool, 8000, 1, SAMPLES_PER_FRAME, 16, 0, &tonegen);
    cd->tonegen = tonegen;
    
    pjsua_conf_port_id toneslot;
    pjsua_conf_add_port(cd->pool, cd->tonegen, &toneslot);
    cd->toneslot = toneslot;
    
    pjsua_call_info ci;
    pjsua_call_get_info(call_id, &ci);
    pjsua_conf_connect(cd->toneslot, ci.conf_slot);
}

void xaax_call_play_digit_for_call(const char digit, pjsua_call_id call_id)
{
/*
    struct tdigit_tone *cd = sip_data->digit_tone;
    xaax_call_stop_digit();
    if (cd->tonegen == NULL) {
        xaax_call_init_tonegen(cd, call_id);
    }
    
    int ON_DURATION = 50;
    int OFF_DURATION = 0;
    
    pjmedia_tone_digit tone_digits[1];
    tone_digits[0].digit = digit;
    tone_digits[0].on_msec = ON_DURATION;
    tone_digits[0].off_msec = OFF_DURATION;
    tone_digits[0].volume = 0;
    
    
    pjmedia_tonegen_play_digits(cd->tonegen, 1, tone_digits, PJMEDIA_TONEGEN_LOOP);

    */
}

void xaax_call_play_digit_by_remote(const char digit, const char * remote_username) {
    /*
    pjsua_call_id callid;
    int i = get_call_id_by_remote(remote_username, &callid);
    if (i == PJ_SUCCESS) {
        xaax_call_play_digit_for_call(digit, callid);
    }
    */
}


void xaax_call_stop_digit() {
/*
    struct tdigit_tone *cd = sip_data->digit_tone;
    if (cd->tonegen != NULL) {
        pjmedia_tonegen_stop(cd->tonegen);
        xaax_call_deinit_tonegen(cd);
    }
 */
}





void xaax_call_deinit_tonegen(struct tdigit_tone *cd)
{
    pjsua_conf_remove_port(cd->toneslot);
    cd->toneslot = -1;
    pjmedia_port_destroy(cd->tonegen);
    cd->tonegen = NULL;
    pj_pool_release(cd->pool);
    cd->pool = NULL;
}

// MARK: SQLite

void xaax_get_last_called_number () {
    select_last_called_number();
    
}

void xaax_get_all_call_history (int *count) {
    select_all_call_history(count);
    
}

void xaax_delete_call_history (int call_history_id) {
    delete_call_history(call_history_id);
    
}

void xaax_delete_all_call_history () {
    pjsua_acc_id default_acc_id = pjsua_acc_get_default();
    if (default_acc_id != PJSUA_INVALID_ID) {
        pjsua_acc_info info;
        pjsua_acc_get_info(default_acc_id, &info);
        char * username;
        char * domain;
        xaax_uri_parse(info.acc_uri.ptr, &username, &domain);
        delete_all_call_history(username, domain);
    }
    
}

void xaax_codecs_get_count(unsigned *count) {
    pjsua_codec_info c[32];
    int aa = 0;
    pj_status_t status = pjsua_enum_codecs(c, &aa);
    if (status == PJ_SUCCESS) {
        // nothing
    }
}

void xaax_codecs_get_id(int codec_id, char** codec, unsigned *priority) {
    pjsua_codec_info c[32];
    unsigned count = PJ_ARRAY_SIZE(c);
    
    pjsua_enum_codecs(c, &count);
    if (codec_id < count) {
        (*codec) = c[codec_id].codec_id.ptr;
        (*priority) = c[codec_id].priority;
        return;
    }
    (*codec) = "INVALID/8000/1";
}

void xaax_codecs_change(int codec_id, bool enable) {
    pjsua_codec_info c[32];
    unsigned count = PJ_ARRAY_SIZE(c);
    
    pjsua_enum_codecs(c, &count);
    if (codec_id < count) {
        const pjsua_codec_info *codec = &c[codec_id];
        pjsua_codec_set_priority(codec,
                                 PJMEDIA_CODEC_PRIO_NORMAL);
        return;
    }
    
}

void xaax_save_contact(const char * contact_id,
                       const char * contact_name,
                  const char * inbound_number_1,
                  const char * inbound_number_2,
                  const char * inbound_number_3,
                  int inbound_ready_1,
                  int inbound_ready_2,
                  int inbound_ready_3,
                  const char * outbound_number_1,
                  const char * outbound_number_2,
                  const char * outbound_number_3,
                  int contact_ready) {
    save_contact(contact_id, contact_name, inbound_number_1, inbound_number_2, inbound_number_3, inbound_ready_1, inbound_ready_2, inbound_ready_3, outbound_number_1, outbound_number_2, outbound_number_3, contact_ready);
}

void xaax_delete_contact(const char * contact_id) {
    delete_contact(contact_id);
}

void xaax_insert_contact(const char * contact_id,
                         const char * contact_name,
                         const char * inbound_number_1,
                         const char * inbound_number_2,
                         const char * inbound_number_3,
                         int inbound_ready_1,
                         int inbound_ready_2,
                         int inbound_ready_3,
                         const char * outbound_number_1,
                         const char * outbound_number_2,
                         const char * outbound_number_3,
                         int contact_ready) {
    insert_contact(contact_id, contact_name, inbound_number_1, inbound_number_2, inbound_number_3, inbound_ready_1, inbound_ready_2, inbound_ready_3, outbound_number_1, outbound_number_2, outbound_number_3, contact_ready);
    
}

void xaax_update_contact(const char * contact_id,
                         const char * inbound_number_1,
                         const char * inbound_number_2,
                         const char * inbound_number_3,
                         int inbound_ready_1,
                         int inbound_ready_2,
                         int inbound_ready_3,
                         const char * outbound_number_1,
                         const char * outbound_number_2,
                         const char * outbound_number_3,
                         int contact_ready) {
    update_contact(contact_id, inbound_number_1, inbound_number_2, inbound_number_3, inbound_ready_1, inbound_ready_2, inbound_ready_3, outbound_number_1, outbound_number_2, outbound_number_3, contact_ready);
}
void xaax_select_contact_matched(const char * sip_number,
                         int *count, char **contact_id, char **contact_name) {
    select_contact_matched(sip_number, count, contact_id, contact_name);
}

void xaax_delete_all_contacts() {
    delete_all_contacts();
}




// MARK: CALLBACKS OUTSIDE


void xaax_cb_set_contact_matched_returned (void (*on_contact_matched_returned)(const char * contact_id)) {
    set_cb_contact_matched_returned(on_contact_matched_returned);
}

void xaax_cb_set_last_called_number_returned (void (*on_last_called_number_returned)(const char * last_called_number)) {
    set_cb_last_called_number_returned(on_last_called_number_returned);
}

void xaax_cb_set_all_call_history_returned (void (*on_all_call_history_return)(int call_history_id,
                                                                               int call_id,
                                                                               const char * caller_username,
                                                                               const char * callee_username,
                                                                               const char * domain,
                                                                               const char * remote_username,
                                                                               int duration,
                                                                               
                                                                               time_t start_date,
                                                                               int direction,
                                                                               int state,
                                                                               const char * callee_contact_number,
                                                                               const char * callee_contact_name,
                                                                               const char * callee_contact_id)) {
    set_cb_all_call_history_returned(on_all_call_history_return);
}

void xaax_cb_set_registration_update (void (*on_registration_update)(const char * username, const char * domain, xaax_status_t status)) {
    cb_registration_update = on_registration_update;
}

void xaax_cb_set_call_update (void (*on_call_update)(const char * remote_username, const char * remote_contact_name, const char * domain, long duration, xaax_status_t status)) {
    cb_call_update = on_call_update;
}


// MARK: CALLBACKS

static void on_all_accounts_return( int acc_id, const char * username, const char * password, const char * domain, const char * port ) {
    
    xaax_add_account(username, password, domain, "udp", port);
}

static void on_incoming_call( pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata ) {
    
    pjsua_call_info ci;
    PJ_UNUSED_ARG( acc_id );
    PJ_UNUSED_ARG( rdata );
    pjsua_call_get_info( call_id, &ci );
    
    PJ_LOG( 3,( THIS_FILE, "Incoming call from %.*s!!", (int) ci.remote_info.slen, ci.remote_info.ptr ) );
    
    char * local_username;
    char * domain;
    xaax_uri_parse(ci.local_info.ptr, &local_username, &domain);
    remove_char(domain, '>');
    
    char tmp[255];
    sprintf(tmp, "%s", extract_between(ci.remote_info.ptr, "sip:", "@"));
    char * remote_username = malloc(strlen(tmp) + 3);
    sprintf(remote_username, "%s", tmp);
    
    long duration = ci.total_duration.sec;

    
    
    int call_history_id = insert_call_history(call_id, remote_username, local_username, domain, remote_username, duration, time(0), XAAX_CALL_DIRECTION_INCOMING, XAAX_CALL_MISSED);
    struct tcall *tcall_save = malloc (sizeof (struct tcall));
    tcall_save->remote_username = remote_username;
    tcall_save->domain = domain;
    tcall_save->call_history_id = call_history_id;
    pjsua_call_set_user_data(call_id, tcall_save);
    
    int count = 0;
    char *contact_id;
    char *contact_name;
    select_contact_matched(remote_username, &count, &contact_id, &contact_name);
    
    update_history_call_contact_name(call_history_id, remote_username, contact_name, contact_id);
    
    
    (*cb_call_update)(remote_username, contact_name, domain, duration, XAAX_CALL_INCOMING_RECEIVED);
    
}

static void on_call_state( pjsua_call_id call_id, pjsip_event *e ) {
    pjsua_call_info ci;
    
    PJ_UNUSED_ARG( e );
    
    pjsua_call_get_info( call_id, &ci );
    PJ_LOG( 3,( THIS_FILE, "Call %d state=%.*s", call_id, (int) ci.state_text.slen, ci.state_text.ptr ) );
    
    char * local_username;
    char * domain;
    xaax_uri_parse(ci.local_info.ptr, &local_username, &domain);
    char * remote_username = extract_between(ci.remote_info.ptr, "sip:", "@");
    char * remote_contact_name = "";
    
    long duration = ci.connect_duration.sec;
    
    xaax_status_t ret_state;
    if (ci.state == PJSIP_INV_STATE_DISCONNECTED) {
        ret_state = XAAX_CALL_ENDED;
        
        struct tcall *call_data = pjsua_call_get_user_data(call_id);
        update_history_duration(call_data->call_history_id, duration);
        xaax_call_stop_digit();
        
    } else if (ci.state == PJSIP_INV_STATE_INCOMING) {
        ret_state = XAAX_CALL_INCOMING_RECEIVED;
        
    } else if (ci.state == PJSIP_INV_STATE_CALLING) {
        
        ret_state = XAAX_CALL_CALLING;
        
        int call_history_id = insert_call_history(call_id, local_username, remote_username, domain, remote_username, duration, time(0), XAAX_CALL_DIRECTION_OUTGOING, XAAX_CALL_MISSED);
        
        //int count = 0;
        //char *contact_id;
        //char *contact_name;
        //select_contact_matched(remote_username, &count, &contact_id, &contact_name);
        
        struct tcall *tcall_save = pjsua_call_get_user_data(call_id);
        if (tcall_save == NULL) {
            tcall_save = malloc(sizeof(struct tcall));
        }
        
        tcall_save->remote_username = remote_username;
        tcall_save->domain = domain;
        tcall_save->call_history_id = call_history_id;
        
        pjsua_call_set_user_data(call_id, tcall_save);
        
        update_history_call_contact_name(call_history_id, remote_username, tcall_save->remote_contact_name, tcall_save->remote_contact_id);

        
    } else if (ci.state == PJSIP_INV_STATE_CONNECTING) {
//        ret_state = XAAX_CALL_ENDED;

        return;
    } else if (ci.state == PJSIP_INV_STATE_CONFIRMED) {
        ret_state = XAAX_CALL_CONNECTED;
        struct tcall *call_data = pjsua_call_get_user_data(call_id);
        update_history_call_state(call_data->call_history_id, XAAX_CALL_CALLED);
    } else if (ci.state == PJSIP_INV_STATE_EARLY) {
        ret_state = XAAX_CALL_EARLY;
        return;
    } else if (ci.state == PJSIP_INV_STATE_NULL) {
//        ret_state = XAAX_CALL_ENDED;
        return;
    } else {
        return;
    }
    
    (*cb_call_update)(remote_username, remote_contact_name, domain, duration, ret_state);
}

static void on_call_media_state( pjsua_call_id call_id ) {
    pjsua_call_info ci;
    pjsua_call_get_info( call_id, &ci );
    
    if ( ci.media_status == PJSUA_CALL_MEDIA_ACTIVE ) {
        pjsua_conf_connect( ci.conf_slot, 0 );
        pjsua_conf_connect( 0, ci.conf_slot );
    }
}

static void on_reg_state( pjsua_acc_id acc_id ) {
    pjsua_acc_info info;
    pjsua_acc_get_info(acc_id, &info);
    struct tacc *acc = pjsua_acc_get_user_data(acc_id);
    
    xaax_status_t reg_status = XAAX_REGISTER_FAILED;
    if (info.status == PJSIP_SC_PROGRESS) {
        reg_status = XAAX_REGISTER_INPROGRESS;
    } else if (info.status == PJSIP_SC_OK) {
        reg_status = XAAX_REGISTER_SUCCESSFUL;
    }
    
    if (info.has_registration) {
        delete_account(acc_id);
        insert_account(acc_id, acc->username, acc->password, acc->domain, acc->port);
    }
    
    (*cb_registration_update)(acc->username, acc->domain, reg_status);
}

static void error_exit( const char *title, pj_status_t status ) {
    pjsua_perror( THIS_FILE, title, status );
    pjsua_destroy();
    exit( 1 );
}


// MARK: PRIVATE METHODS

int xaax_get_account_id (pjsua_acc_id *ret_acc_id, const char *username, const char *domain, const char *port) {
    for (int acc_id = 0; acc_id < pjsua_acc_get_count(); acc_id++) {
        if (pjsua_acc_is_valid(acc_id)) {
            ;
            
            struct tacc* acc = pjsua_acc_get_user_data(acc_id);
            if (strcmp(acc->domain, domain) == 0 &&
                    strcmp(acc->username, username) == 0 &&
                    strcmp(acc->port, port) == 0) {
                *ret_acc_id = acc_id;
                return PJ_TRUE;
            }
        }
    }
    return PJ_FALSE;
}

static void xaax_uri_parse ( const char *uri, char ** username, char ** domain ) {
    *username = extract_between(uri, ":", "@");
    
    char *ptr = strstr(uri, "@");
    if (ptr != NULL) {
        int len = strlen(ptr);
        char *ret_domain = malloc(len + 1);
        memcpy( ret_domain, &ptr[1], len-1 );
        ret_domain[len - 1] = '\0';
        *domain = ret_domain;
    } else {
        *domain = NULL;
    }
}

static char * extract_between(const char *str, const char *p1, const char *p2)
{
    const char *i1 = strstr(str, p1);
    if(i1 != NULL)
    {
        const size_t pl1 = strlen(p1);
        const char *i2 = strstr(i1 + pl1, p2);
        if(p2 != NULL)
        {
            /* Found both markers, extract text. */
            const size_t mlen = i2 - (i1 + pl1);
            char *ret = malloc(mlen + 1);
            if(ret != NULL)
            {
                memcpy(ret, i1 + pl1, mlen);
                ret[mlen] = '\0';
                return ret;
            }
        }
    }
    return NULL;
}

static int get_call_id_by_remote( const char * remote_username, pjsua_call_id *call_id ) {
    for (pjsua_call_id p_call_id = 0; p_call_id < pjsua_call_get_max_count(); p_call_id++) {
        if (pjsua_call_is_active(p_call_id)) {
            struct tcall * tcall_data = pjsua_call_get_user_data(p_call_id);
            if (tcall_data) {
                if (strcmp(tcall_data->remote_username, remote_username) == 0) {
                    *call_id = p_call_id;
                    return PJ_SUCCESS;
                }
            }
        }
    }
    return -1;
}

static void remove_char(char *str, char garbage) {
    
    char *src, *dst;
    for (src = dst = str; *src != '\0'; src++) {
        *dst = *src;
        if (*dst != garbage) dst++;
    }
    *dst = '\0';
}
