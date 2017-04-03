//
//  PJHelper.m
//  ipjsua
//
//  Created by Vinh Thien on 11/10/16.
//  Copyright © 2016 Teluu. All rights reserved.
//

#import "xaax_sqlite_helper.h"
#import "sqlite_helper.h"

#define THIS_FILE	"xaax_sqlite_helper.m"


/* CALL_HISTORY */
#define TABLE_NAME_CALL_HISTORY	"CALL_HISTORY"

#define TABLE_COLUMN_ID                 "ID"
#define TABLE_COLUMN_CALL_ID            "CALL_ID"
#define TABLE_COLUMN_CALLER_USERNAME	"CALLER_USERNAME"
#define TABLE_COLUMN_CALLEE_USERNAME	"CALLEE_USERNAME"
#define TABLE_COLUMN_DOMAIN             "DOMAIN"
#define TABLE_COLUMN_REMOTE_USERNAME    "REMOTE_USERNAME"
#define TABLE_COLUMN_DURATION           "DURATION"
#define TABLE_COLUMN_START_DATE         "START_DATE"
#define TABLE_COLUMN_DIRECTION          "DIRECTION"
#define TABLE_COLUMN_STATE              "STATE"
#define TABLE_COLUMN_CALLEE_CONTACT_NUMBER	"CALLEE_CONTACT_NUMBER"
#define TABLE_COLUMN_CALLEE_CONTACT_NAME	"CALLEE_CONTACT_NAME"
#define TABLE_COLUMN_CALLEE_CONTACT_ID	"CALLEE_CONTACT_ID"

/* ACCOUNTS */
#define TABLE_NAME_ACCOUNTS	"ACCOUNTS"

#define TABLE_COLUMN_ID                 "ID"
#define TABLE_COLUMN_ACC_ID             "ACC_ID"
#define TABLE_COLUMN_USERNAME           "USERNAME"
#define TABLE_COLUMN_PASSWORD           "PASSWORD"
#define TABLE_COLUMN_ACCOUNT_DOMAIN     "DOMAIN"
#define TABLE_COLUMN_ACCOUNT_PORT     "PORT"


/* CONTACTS */
#define TABLE_NAME_CONTACTS	"CONTACTS"

#define TABLE_COLUMN_ID                 "ID"
#define TABLE_COLUMN_CONTACT_ID             "CONTACT_ID"
#define TABLE_COLUMN_CONTACT_NAME           "CONTACT_NAME"
#define TABLE_COLUMN_INBOUND_NUMBER_1           "INBOUND_NUMBER_1"
#define TABLE_COLUMN_INBOUND_NUMBER_2           "INBOUND_NUMBER_2"
#define TABLE_COLUMN_INBOUND_NUMBER_3           "INBOUND_NUMBER_3"
#define TABLE_COLUMN_INBOUND_READY_1           "INBOUND_READY_1"
#define TABLE_COLUMN_INBOUND_READY_2           "INBOUND_READY_2"
#define TABLE_COLUMN_INBOUND_READY_3           "INBOUND_READY_3"

#define TABLE_COLUMN_OUTBOUND_NUMBER_1           "OUTBOUND_NUMBER_1"
#define TABLE_COLUMN_OUTBOUND_NUMBER_2           "OUTBOUND_NUMBER_2"
#define TABLE_COLUMN_OUTBOUND_NUMBER_3           "OUTBOUND_NUMBER_3"
#define TABLE_COLUMN_CONTACT_READY           "CONTACT_READY"


int cb_select_contact_matched(void *unused, int count, char **data, char **columns);
int cb_select_last_called_number(void *unused, int count, char **data, char **columns);
int cb_select_all_call_history(void *unused, int count, char **data, char **columns);
int cb_select_all_accounts(void *unused, int count, char **data, char **columns);
int cb_select_password_from_account(void *unused, int count, char **data, char **columns);

void (*cb_contact_matched_returned)(const char * contact_id);

void (*cb_last_called_number_returned)(const char * caller_username);

void (*cb_all_call_history_returned)(int call_history_id,
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
                                     const char * callee_contact_id);

void (*cb_all_accounts_returned)(int acc_id,
                                const char * username,
                                const char * password,
                                const char * domain,
                                 const char * port);



void create_table_call_history(void);
void create_table_accounts(void);
void create_table_contact_list(void);

void testselect_contact_matched();


void init_db(const char * db_name) {
    /* Open database */
    sqlite_open(db_name);
    
    /* Create tables */
    create_table_call_history();
    create_table_accounts();
    create_table_contact_list();
    
    testselect_contact_matched();
}

void close_db(void) {
    sqlite_close();
}

void select_all_call_history(int *count) {
    char tmp[1024];
    sprintf(tmp, " SELECT h.%s, h.%s, h.%s, h.%s, h.%s, h.%s, h.%s, h.%s, h.%s, h.%s, h.%s, h.%s, h.%s " \
            "FROM %s h " \
            "ORDER BY h.%s DESC ",
            TABLE_COLUMN_ID,
            TABLE_COLUMN_CALL_ID,
            TABLE_COLUMN_CALLER_USERNAME,
            TABLE_COLUMN_CALLEE_USERNAME,
            TABLE_COLUMN_DOMAIN,
            TABLE_COLUMN_REMOTE_USERNAME,
            TABLE_COLUMN_DURATION,
            TABLE_COLUMN_START_DATE,
            TABLE_COLUMN_DIRECTION,
            TABLE_COLUMN_STATE,
            TABLE_COLUMN_CALLEE_CONTACT_NUMBER,
            TABLE_COLUMN_CALLEE_CONTACT_NAME,
            TABLE_COLUMN_CALLEE_CONTACT_ID,
            TABLE_NAME_CALL_HISTORY,
            TABLE_COLUMN_ID);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    sqlite_exec(sql, count, cb_select_all_call_history);
}

void testselect_contact_matched() {
    char tmp[512];
    sprintf(tmp, " SELECT h.%s, h.%s, h.%s, h.%s, h.%s, h.%s " \
            "FROM %s h ",
            TABLE_COLUMN_ID,
            TABLE_COLUMN_CONTACT_ID,
            TABLE_COLUMN_CONTACT_NAME,
            TABLE_COLUMN_INBOUND_NUMBER_1,
            TABLE_COLUMN_INBOUND_NUMBER_2,
            TABLE_COLUMN_INBOUND_NUMBER_3,
            TABLE_NAME_CONTACTS);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    
    int count = 0;
    sqlite_exec(sql, &count, cb_select_contact_matched);
}

void select_contact_matched(const char * sip_number, int *count, char** contact_id, char ** contact_name) {
    char tmp[512];
    sprintf(tmp, " SELECT h.%s, h.%s " \
            "FROM %s h " \
            "WHERE h.%s='%s' OR h.%s='%s' OR h.%s='%s' ",
            TABLE_COLUMN_CONTACT_ID,
            TABLE_COLUMN_CONTACT_NAME,
            TABLE_NAME_CONTACTS,
            TABLE_COLUMN_INBOUND_NUMBER_1,
            sip_number,
            TABLE_COLUMN_INBOUND_NUMBER_2,
            sip_number,
            TABLE_COLUMN_INBOUND_NUMBER_3,
            sip_number);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    
    sqlite3_stmt *stmt = NULL;
    int rc = sqlite_exec_no_callback(sql, &stmt);
    
    char * tmp_contact_id;
    char * tmp_contact_name;
    int row_count = 0;
    if (rc == SQLITE_OK) {
    
        rc = sqlite3_step(stmt);
        while (rc != SQLITE_DONE && rc != SQLITE_OK)
        {
            row_count++;
            
            const unsigned char * val_contact_id = sqlite3_column_text(stmt, 0);
            tmp_contact_id = malloc(sizeof(val_contact_id) + 3);
            sprintf(tmp_contact_id, "%s", val_contact_id);
            
            
            const unsigned char * val_contact_name = sqlite3_column_text(stmt, 1);
            tmp_contact_name = malloc(sizeof(val_contact_name) + 3);
            sprintf(tmp_contact_name, "%s", val_contact_name);
            
//            int colCount = sqlite3_column_count(stmt);
//            for (int colIndex = 0; colIndex < colCount; colIndex++)
//            {
//                int type = sqlite3_column_type(stmt, colIndex);
//                const char * columnName = sqlite3_column_name(stmt, colIndex);
//                if (type == SQLITE_INTEGER)
//                {
//                    int valInt = sqlite3_column_int(stmt, colIndex);
//                    printf("columnName = %s, Integer val = %d", columnName, valInt);
//                }
//                else if (type == SQLITE_FLOAT)
//                {
//                    double valDouble = sqlite3_column_double(stmt, colIndex);
//                    printf("columnName = %s,Double val = %f", columnName, valDouble);
//                }
//                else if (type == SQLITE_TEXT)
//                {
//                    const unsigned char * valChar = sqlite3_column_text(stmt, colIndex);
//                    printf("columnName = %s,Text val = %s", columnName, valChar);
//                    free(valChar);
//                }
//                else if (type == SQLITE_BLOB)
//                {
//                    printf("columnName = %s,BLOB", columnName);
//                }
//                else if (type == SQLITE_NULL)
//                {
//                    printf("columnName = %s,NULL", columnName);
//                }
//            }
//            printf("Line %d, rowCount = %d", rowCount, colCount);
            
            rc = sqlite3_step(stmt);
        }
        
        rc = sqlite3_finalize(stmt);
    }
    
    *contact_id = "";
    *contact_name = "";
    *count = row_count;
    if (row_count > 0) {
        *contact_id = tmp_contact_id;
        *contact_name = tmp_contact_name;
    }
}

void select_last_called_number() {
    char tmp[512];
    sprintf(tmp, " SELECT h.%s " \
            "FROM %s h " \
            "ORDER BY h.%s DESC " \
            "LIMIT 1 ",
            TABLE_COLUMN_REMOTE_USERNAME,
            TABLE_NAME_CALL_HISTORY,
            TABLE_COLUMN_ID);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    sqlite_exec(sql, NULL, cb_select_last_called_number);
}


void set_cb_contact_matched_returned (void (*on_contact_matched_returned)(const char * contact_id)) {
    cb_contact_matched_returned = on_contact_matched_returned;
}

void set_cb_last_called_number_returned (void (*on_last_called_number_returned)(const char * last_called_number)) {
    cb_last_called_number_returned = on_last_called_number_returned;
}

void set_cb_all_call_history_returned (void (*on_all_call_history_return)(int call_history_id,
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
    cb_all_call_history_returned = on_all_call_history_return;
}

int insert_call_history(int call_id,
                         const char * caller_username,
                         const char * callee_username,
                         const char * domain,
                         const char * remote_username,
                         long duration,
                         time_t start_date,
                         int direction,
                         int state) {
    char tmp[512];
    sprintf(tmp, "INSERT INTO %s (%s,%s,%s,%s,%s,%s,%s,%s,%s) "  \
            "VALUES (%d, '%s', '%s', '%s', '%s', %ld, %ld, %d, %d )",
            TABLE_NAME_CALL_HISTORY,
            TABLE_COLUMN_CALL_ID,
            TABLE_COLUMN_CALLER_USERNAME,
            TABLE_COLUMN_CALLEE_USERNAME,
            TABLE_COLUMN_DOMAIN,
            TABLE_COLUMN_REMOTE_USERNAME,
            TABLE_COLUMN_DURATION,
            TABLE_COLUMN_START_DATE,
            TABLE_COLUMN_DIRECTION,
            TABLE_COLUMN_STATE,
            call_id,
            caller_username,
            callee_username,
            domain,
            remote_username,
            duration,
            start_date,
            direction,
            state);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);

    int i = sqlite_exec(sql, NULL, NULL);
    if (i == 0) { // success
        int call_history_id = sqlite_last_insert_rowid();
        return call_history_id;
    }
    return -1;
}

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
                  int contact_ready) {
    
    delete_contact(contact_id);
    insert_contact(contact_id, contact_name, inbound_number_1, inbound_number_2, inbound_number_3, inbound_ready_1, inbound_ready_2, inbound_ready_3, outbound_number_1, outbound_number_2, outbound_number_3, contact_ready);
}

void delete_contact(const char * contact_id) {
    char tmp[256];
    sprintf(tmp, "DELETE FROM %s "  \
            "WHERE %s='%s'",
            TABLE_NAME_CONTACTS,
            TABLE_COLUMN_CONTACT_ID,
            contact_id);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    
    sqlite_exec(sql, NULL, NULL);
}

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
                    int contact_ready) {
    char tmp[1024];
    sprintf(tmp, "INSERT INTO %s (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s) "  \
            "VALUES ('%s', '%s', '%s', '%s', '%s', %d, %d, %d, '%s', '%s', '%s', %d )",
            TABLE_NAME_CONTACTS,
            TABLE_COLUMN_CONTACT_ID,
            TABLE_COLUMN_CONTACT_NAME,
            TABLE_COLUMN_INBOUND_NUMBER_1,
            TABLE_COLUMN_INBOUND_NUMBER_2,
            TABLE_COLUMN_INBOUND_NUMBER_3,
            TABLE_COLUMN_INBOUND_READY_1,
            TABLE_COLUMN_INBOUND_READY_2,
            TABLE_COLUMN_INBOUND_READY_3,
            TABLE_COLUMN_OUTBOUND_NUMBER_1,
            TABLE_COLUMN_OUTBOUND_NUMBER_2,
            TABLE_COLUMN_OUTBOUND_NUMBER_3,
            TABLE_COLUMN_CONTACT_READY,
            contact_id,
            contact_name,
            inbound_number_1,
            inbound_number_2,
            inbound_number_3,
            inbound_ready_1,
            inbound_ready_2,
            inbound_ready_3,
            outbound_number_1,
            outbound_number_2,
            outbound_number_3,
            contact_ready);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    
    int i = sqlite_exec(sql, NULL, NULL);
    if (i == 0) { // success
        int contact_auto_id = sqlite_last_insert_rowid();
        return contact_auto_id;
    }
    return -1;
}

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
                    int contact_ready) {
    char tmp[1024];
    sprintf(tmp, "UPDATE %s "  \
            "SET %s='%s', %s='%s', %s='%s', "  \
            "   %s='%d', %s='%d', %s='%d' "  \
            "   %s='%s', %s='%s', %s='%s' "  \
            "   %s='%d' "  \
            "WHERE %s=%s",
            TABLE_NAME_CONTACTS,
            
            TABLE_COLUMN_INBOUND_NUMBER_1,
            inbound_number_1,
            TABLE_COLUMN_INBOUND_NUMBER_2,
            inbound_number_2,
            TABLE_COLUMN_INBOUND_NUMBER_3,
            inbound_number_3,
            
            TABLE_COLUMN_INBOUND_READY_1,
            inbound_ready_1,
            TABLE_COLUMN_INBOUND_READY_2,
            inbound_ready_2,
            TABLE_COLUMN_INBOUND_READY_3,
            inbound_ready_3,
            
            TABLE_COLUMN_OUTBOUND_NUMBER_1,
            outbound_number_1,
            TABLE_COLUMN_OUTBOUND_NUMBER_2,
            outbound_number_2,
            TABLE_COLUMN_OUTBOUND_NUMBER_3,
            outbound_number_3,
            
            TABLE_COLUMN_CONTACT_READY,
            contact_ready,
            
            TABLE_COLUMN_CONTACT_ID,
            contact_id);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    sqlite_exec(sql, NULL, NULL);
    
}


void update_history_call_contact_name(int call_history_id, const char * contact_number, const char * contact_name, const char * contact_id) {
    char tmp[256];
    sprintf(tmp, "UPDATE %s "  \
            "SET %s='%s', %s='%s', %s='%s' "  \
            "WHERE %s=%d",
            TABLE_NAME_CALL_HISTORY,
            TABLE_COLUMN_CALLEE_CONTACT_NUMBER,
            contact_number,
            TABLE_COLUMN_CALLEE_CONTACT_NAME,
            contact_name,
            TABLE_COLUMN_CALLEE_CONTACT_ID,
            contact_id,
            TABLE_COLUMN_ID,
            call_history_id);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    
    sqlite_exec(sql, NULL, NULL);
    
}

void update_history_call_state(int call_history_id, int state) {
    char tmp[256];
    sprintf(tmp, "UPDATE %s "  \
            "SET %s=%d "  \
            "WHERE %s=%d",
            TABLE_NAME_CALL_HISTORY,
            TABLE_COLUMN_STATE,
            state,
            TABLE_COLUMN_ID,
            call_history_id);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    
    sqlite_exec(sql, NULL, NULL);
    
}

void update_history_duration(int call_history_id, long duration) {
    char tmp[256];
    sprintf(tmp, "UPDATE %s "  \
            "SET %s=%ld "  \
            "WHERE %s=%d",
            TABLE_NAME_CALL_HISTORY,
            TABLE_COLUMN_DURATION,
            duration,
            TABLE_COLUMN_ID,
            call_history_id);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    
    sqlite_exec(sql, NULL, NULL);
    
}

void delete_call_history(int call_history_id) {
    char tmp[256];
    sprintf(tmp, "DELETE FROM %s "  \
            "WHERE %s=%d ",
            TABLE_NAME_CALL_HISTORY,
            TABLE_COLUMN_ID,
            call_history_id);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    
    sqlite_exec(sql, NULL, NULL);
}

void delete_all_call_history(const char * default_username, const char * default_domain) {
    char tmp[256];
    sprintf(tmp, "DELETE FROM %s " \
                "WHERE (%s='%s' OR %s='%s') " \
                "AND %s='%s' ",
            TABLE_NAME_CALL_HISTORY,
            TABLE_COLUMN_CALLER_USERNAME,
            default_username,
            TABLE_COLUMN_CALLEE_USERNAME,
            default_username,
            TABLE_COLUMN_DOMAIN,
            default_domain);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    
    sqlite_exec(sql, NULL, NULL);
}



void insert_account(int acc_id,
                    const char * username,
                    const char * password,
                    const char * domain,
                    const char * port) {
    char tmp[256];
    sprintf(tmp, "INSERT INTO %s (%s,%s,%s,%s,%s) "  \
            "VALUES (%d, '%s', '%s', '%s', '%s' )",
            TABLE_NAME_ACCOUNTS,
            TABLE_COLUMN_ACC_ID,
            TABLE_COLUMN_USERNAME,
            TABLE_COLUMN_PASSWORD,
            TABLE_COLUMN_ACCOUNT_DOMAIN,
            TABLE_COLUMN_ACCOUNT_PORT,
            acc_id,
            username,
            password,
            domain,
            port);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    
    sqlite_exec(sql, NULL, NULL);
}

void delete_account(int acc_id) {
    char tmp[256];
    sprintf(tmp, "DELETE FROM %s "  \
            "WHERE %s=%d",
            TABLE_NAME_ACCOUNTS,
            TABLE_COLUMN_ACC_ID,
            acc_id);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    
    sqlite_exec(sql, NULL, NULL);
}
void delete_all_contacts() {
    char tmp[256];
    sprintf(tmp, "DELETE FROM %s ",
            TABLE_NAME_CONTACTS);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    
    sqlite_exec(sql, NULL, NULL);
//    testselect_contact_matched();
}

void select_all_accounts(int *count) {
    char tmp[256];
    sprintf(tmp, "SELECT h.%s, h.%s, h.%s, h.%s, h.%s " \
            "FROM %s h",
            //TABLE_COLUMN_ID,
            TABLE_COLUMN_ACC_ID,
            TABLE_COLUMN_USERNAME,
            TABLE_COLUMN_PASSWORD,
            TABLE_COLUMN_ACCOUNT_DOMAIN,
            TABLE_COLUMN_ACCOUNT_PORT,
            TABLE_NAME_ACCOUNTS);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    
    sqlite_exec(sql, count, cb_select_all_accounts);
}

void select_password_from_account(const char * username, const char * domain, char **password) {
    char tmp[256];
    sprintf(tmp, "SELECT h.%s " \
            "FROM %s h " \
            "WHERE h.%s='%s' AND h.%s='%s'",
            TABLE_COLUMN_PASSWORD,
            TABLE_NAME_ACCOUNTS,
            TABLE_COLUMN_USERNAME,
            username,
            TABLE_COLUMN_ACCOUNT_DOMAIN,
            domain);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    
    sqlite_exec(sql, password, cb_select_password_from_account);
}

void set_cb_all_accounts_returned (void (*on_all_accounts_return)(int acc_id,
                                                                          const char * username,
                                                                          const char * password,
                                                                          const char * domain,
                                                                          const char * port)) {
    cb_all_accounts_returned = on_all_accounts_return;
}


/* Private functions */

void create_table_call_history(void) {
    char tmp[500];
    sprintf(tmp, "CREATE TABLE %s(%s INTEGER PRIMARY KEY AUTOINCREMENT, " \
            "%s INTEGER, %s TEXT, %s TEXT, %s TEXT, %s TEXT,  " \
            "%s INTEGER, %s INTEGER, %s INTEGER,  " \
            "%s INTEGER, %s TEXT, %s TEXT, %s TEXT )",
            TABLE_NAME_CALL_HISTORY,
            TABLE_COLUMN_ID,
            TABLE_COLUMN_CALL_ID,
            TABLE_COLUMN_CALLER_USERNAME,
            TABLE_COLUMN_CALLEE_USERNAME,
            TABLE_COLUMN_DOMAIN,
            TABLE_COLUMN_REMOTE_USERNAME,
            TABLE_COLUMN_DURATION,
            TABLE_COLUMN_START_DATE,
            TABLE_COLUMN_DIRECTION,
            TABLE_COLUMN_STATE,
            TABLE_COLUMN_CALLEE_CONTACT_NUMBER,
            TABLE_COLUMN_CALLEE_CONTACT_NAME,
            TABLE_COLUMN_CALLEE_CONTACT_ID);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    
    sqlite_exec(sql, NULL, NULL);
}

void create_table_accounts(void) {
    char tmp[256];
    sprintf(tmp, "CREATE TABLE %s(%s INTEGER PRIMARY KEY AUTOINCREMENT, " \
            "%s INTEGER, %s TEXT, %s TEXT, %s TEXT, %s TEXT  )",
            TABLE_NAME_ACCOUNTS,
            TABLE_COLUMN_ID,
            TABLE_COLUMN_ACC_ID,
            TABLE_COLUMN_USERNAME,
            TABLE_COLUMN_PASSWORD,
            TABLE_COLUMN_ACCOUNT_DOMAIN,
            TABLE_COLUMN_ACCOUNT_PORT);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    
    sqlite_exec(sql, NULL, NULL);
}

void create_table_contact_list(void) {
    char tmp[1024];
    sprintf(tmp, "CREATE TABLE %s(%s INTEGER PRIMARY KEY AUTOINCREMENT, " \
            "%s TEXT, %s TEXT, %s TEXT, %s TEXT, %s TEXT, %s TEXT, %s TEXT, %s TEXT, %s TEXT, %s TEXT, %s TEXT, %s TEXT  )",
            TABLE_NAME_CONTACTS,
            TABLE_COLUMN_ID,
            TABLE_COLUMN_CONTACT_ID,
            TABLE_COLUMN_CONTACT_NAME,
            TABLE_COLUMN_INBOUND_NUMBER_1,
            TABLE_COLUMN_INBOUND_NUMBER_2,
            TABLE_COLUMN_INBOUND_NUMBER_3,
            TABLE_COLUMN_INBOUND_READY_1,
            TABLE_COLUMN_INBOUND_READY_2,
            TABLE_COLUMN_INBOUND_READY_3,
            TABLE_COLUMN_OUTBOUND_NUMBER_1,
            TABLE_COLUMN_OUTBOUND_NUMBER_2,
            TABLE_COLUMN_OUTBOUND_NUMBER_3,
            TABLE_COLUMN_CONTACT_READY);
    char *sql = malloc(sizeof(tmp) + 3);
    sprintf(sql, "%s", tmp);
    
    sqlite_exec(sql, NULL, NULL);
}


int cb_select_last_called_number(void *unused, int count, char **data, char **columns)
{

    char * last_called_number = data[0];
    
    (*cb_last_called_number_returned)(last_called_number);
    
    return 0;
}

int cb_select_contact_matched(void *unused, int count, char **data, char **columns)
{
    int contact_auto_id = atoi(data[0]);
    char * contact_id = data[1];
    char * contact_name = data[2];
    char * inbound_1 = data[3];
    char * inbound_2 = data[4];
    char * inbound_3 = data[5];
    
    printf("Row: %d %s %s %s %s %s\n", contact_auto_id, contact_id, contact_name, inbound_1, inbound_2, inbound_3);
    
    int * count_row = unused;
    *count_row = *count_row + 1;
    
//    (*cb_contact_matched_returned)(contact_id);
    
    return 0;
}

int cb_select_all_call_history(void *unused, int count, char **data, char **columns)
{
    int call_history_id = atoi(data[0]);
    int call_id = atoi(data[1]);
    char * caller_username = data[2];
    char * callee_username = data[3];
    char * domain = data[4];
    char * remote_username = data[5];
    int duration = atoi(data[6]);
    time_t start_date = atoi(data[7]);
    int direction = atoi(data[8]);
    int state = atoi(data[9]);
    char * callee_contact_number = data[10];
    char * callee_contact_name = data[11];
    char * callee_contact_id = data[12];
    
    printf("Row: %d %s %s %s\n", call_history_id, caller_username, callee_username, domain);
    
    (*cb_all_call_history_returned)(call_history_id, call_id, caller_username, callee_username, domain, remote_username, duration, start_date, direction, state, callee_contact_number, callee_contact_name, callee_contact_id);
    
    return 0;
}

int cb_select_all_accounts(void *unused, int count, char **data, char **columns)
{
    
    printf("There are %d column(s)\n", count);
    
    int acc_id = atoi(data[0]);
    char * username = data[1];
    char * password = data[2];
    char * domain = data[3];
    char * port = data[4];
    
    int * count_row = unused;
    *count_row = *count_row + 1;
    
    (*cb_all_accounts_returned)(acc_id, username, password, domain, port);
    
    return 0;
}

int cb_select_password_from_account(void *unused, int count, char **data, char **columns)
{
    
    printf("There are %d column(s)\n", count);
    
    char * password = data[0];
    
    char *ret = malloc(sizeof(password) + 3);
    sprintf(ret, "%s", password);
    
    char ** ret_data = unused;
    *ret_data = ret;
    
    return 0;
}
