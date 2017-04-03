//
//  xaax_sip_helper.h
//  ipjsua
//
//  Created by Vinh Thien on 11/10/16.
//  Copyright © 2016 Tech Storm. All rights reserved.
//

#ifndef __PJ_SQLITE_HELPER_H__
#define __PJ_SQLITE_HELPER_H__

#include <sqlite3.h>

void sqlite_open(const char * db_name);
int sqlite_exec(const char * sql, void* first_cb_argument, int (*callback)(void *NotUsed, int argc, char **argv, char **azColName));
int sqlite_exec_no_callback(const char * sql, sqlite3_stmt **stmt);
int sqlite_last_insert_rowid();
void sqlite_close(void);

#endif	/* __PJ_SQLITE_HELPER_H__ */
