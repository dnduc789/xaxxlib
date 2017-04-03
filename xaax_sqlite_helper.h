//
//  xaax_sip_helper.h
//  ipjsua
//
//  Created by Vinh Thien on 11/10/16.
//  Copyright © 2016 Tech Storm. All rights reserved.
//

#ifndef __XAAX_SQLITE_HELPER_H__
#define __XAAX_SQLITE_HELPER_H__


void init_db(const char * db_name);

/* CALL HISTORY */
void select_last_called_number();
void select_all_call_history(int *count);
void select_contact_matched(const char * sip_number, int *count, char** contact_id, char ** contact_name);
void set_cb_contact_matched_returned (void (*on_contact_matched_returned)(const char * contact_id));
void set_cb_last_called_number_returned (void (*on_last_called_number_returned)(const char * last_called_number));
void set_cb_all_call_history_returned (void (*cb_all_call_history_returned)(int call_history_id,
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



int insert_call_history(int call_id,
                         const char * caller_username,
                         const char * callee_username,
                         const char * domain,
                         const char * remote_username,
                         long duration,
                         long start_date,
                         int direction,
                         int state);


void save_contact(const char * contact_id,
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

void delete_contact(const char * contact_id);

void delete_all_contacts();

int insert_contact(const char * contact_id,
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

void update_contact(const char * contact_id,
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

void update_history_call_contact_name(int call_history_id, const char * contact_number, const char * contact_name, const char * contact_id);

void update_history_call_state(int call_history_id, int state);

void update_history_duration(int call_history_id, long duration);

void delete_call_history(int call_history_id);

void delete_all_call_history(const char * default_username, const char * default_domain);


/* ACCOUNTS */

void insert_account(int acc_id,
                    const char * username,
                    const char * password,
                    const char * domain,
                    const char * port);
    
void delete_account(int acc_id);
void set_cb_all_accounts_returned (void (*on_all_accounts_return)(int acc_id,
                                                                  const char * username,
                                                                  const char * password,
                                                                  const char * domain, const char * port));
void select_all_accounts(int *count);
void select_password_from_account(const char * username, const char * domain, char **password);


void close_db(void);

#endif	/* __XAAX_SQLITE_HELPER_H__ */
