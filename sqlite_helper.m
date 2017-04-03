//
//  PJHelper.m
//  ipjsua
//
//  Created by Vinh Thien on 11/10/16.
//  Copyright © 2016 Teluu. All rights reserved.
//

#import "sqlite_helper.h"

#define THIS_FILE	"sqlite_helper.m"

static sqlite3 *db;

void sqlite_open(const char * db_name) {
    int rc = sqlite3_open(db_name, &db);
    if ( rc ) {
        fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(db));
        return;
    } else {
        fprintf(stdout, "Opened database successfully\n");
    }
}

int sqlite_exec(const char * sql, void* first_cb_argument, int (*callback)(void *NotUsed, int argc, char **argv, char **azColName)) {
    char *zErrMsg = 0;
    int rc = sqlite3_exec(db, sql, callback, first_cb_argument, &zErrMsg);
    if( rc != SQLITE_OK ){
        fprintf(stderr, "SQL error: %s\n", zErrMsg);
        sqlite3_free(zErrMsg);
        return SQLITE_ERROR;
    }
    
    return SQLITE_OK;
}

int sqlite_exec_no_callback(const char * sql, sqlite3_stmt **stmt)
{
    int rc = sqlite3_prepare_v2(db, sql, -1, stmt, NULL);
    return rc;
}

int sqlite_last_insert_rowid() {
    return (int)sqlite3_last_insert_rowid(db);
}

void sqlite_close(void) {
    sqlite3_close(db);
}
