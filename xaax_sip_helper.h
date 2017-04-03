//
//  xaax_sip_helper.h
//  ipjsua
//
//  Created by Vinh Thien on 11/10/16.
//  Copyright © 2016 Tech Storm. All rights reserved.
//

#ifndef __PJ_HELPER_H__
#define __PJ_HELPER_H__

#import "xaax_common.h"


void xaax_init(const char * db_name);

void xaax_deinit(void);

const char * get_current_incall_remote_username(void);

int get_default_account (const char **username, char **password, const char **domain, const char **transport, const char **displayName, const char **proxy, const char **port);

int xaax_refresh_accounts(void);

void xaax_add_account ( const char * username,
                        const char * password,
                        const char * domain,
                        const char * tranport,
                        const char * port);

void xaax_check_account_registration(const char * username,
                                     const char * domain);

void xaax_remove_all_account();

void xaax_send_dtmf(const char * remote_username, const char digit);

void xaax_call_play_digit_by_remote(const char digit, const char * remote_username);

void xaax_call_stop_digit();

int xaax_count_active_calls ( void );

int xaax_make_single_call( const char * username, const char * contact_id, const char * contact_name );

bool xaax_hangup_call_by_callid (int callid);

bool xaax_hangup_call_by_remote (const char * remote_username);

void xaax_accept_call_by_callid (int callid);

void xaax_accept_call_by_remote (const char * remote_username);

void xaax_pause_call_by_callid (int callid);

void xaax_pause_call_by_remote (const char * remote_username);

void xaax_resume_call_by_callid (int callid);

void xaax_resume_call_by_remote (const char * remote_username);

void xaax_mute_by_callid (int call_id);

void xaax_mute_by_remote (const char * remote_username);

void xaax_unmute_by_callid (int call_id);

void xaax_unmute_by_remote (const char * remote_username);

void xaax_enable_loudspeaker (void);

void xaax_disable_loudspeaker (void);

void xaax_get_last_called_number ();

void xaax_get_all_call_history ( int *count );

void xaax_delete_call_history (int call_history_id);

void xaax_delete_all_call_history ();

void xaax_codecs_get_count(unsigned *count);

void xaax_codecs_get_id(int codec_id, char** codec, unsigned *priority);

void xaax_codecs_change(int codec_id, bool enable);

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
                       int contact_ready);

void xaax_delete_contact(const char * contact_id);

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
                         int contact_ready);

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
                         int contact_ready);

void xaax_select_contact_matched(const char * sip_number,
                                 int *count, char **contact_id, char **contact_name);

void xaax_delete_all_contacts();


void xaax_cb_set_contact_matched_returned (void (*on_contact_matched_returned)(const char * contact_id));

void xaax_cb_set_last_called_number_returned (void (*on_last_called_number_returned)(const char * last_called_number));

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
                                                                               const char * callee_contact_id));


void xaax_cb_set_registration_update (void (*on_registration_update)(const char * username, const char * domain, xaax_status_t status));

void xaax_cb_set_call_update (void (*on_call_update)(const char * remote_username, const char * remote_contact_name, const char * domain, long duration, xaax_status_t status));

#endif	/* __XAAX_SIP_HELPER_H__ */
