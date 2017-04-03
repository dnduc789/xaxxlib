//
//  xaax_common_h
//  XAAX
//
//  Created by Vinh Thien on 10/5/16.
//  Copyright © 2016 Tech Storm. All rights reserved.
//

#include <pj/list.h>

#ifndef xaax_common_h
#define xaax_common_h

#define XA_TRUE 1
#define XA_FALSE 0

typedef enum xaax_status {
    XAAX_REGISTER_SUCCESSFUL = 0,
    XAAX_REGISTER_FAILED = 1,
    XAAX_REGISTER_INPROGRESS = 2,
    
    XAAX_CALL_INCOMING_RECEIVED = 10,
    XAAX_CALL_CALLING = 11,
    XAAX_CALL_ENDED = 12,
    XAAX_CALL_FAILED = 13,
    XAAX_CALL_PAUSED = 14,
    XAAX_CALL_RESUMING = 15,
    XAAX_CALL_CONNECTED = 16,
    XAAX_CALL_EARLY = 17,
    
    
    XAAX_CALL_MISSED = 18,
    XAAX_CALL_CALLED = 19
    
} xaax_status_t;


typedef enum xaax_call_direction
{
    XAAX_CALL_DIRECTION_INCOMING = 0,
    XAAX_CALL_DIRECTION_OUTGOING = 1
} xaax_call_direction_t;


struct call_history_node
{
    // This must be the first member declared in the struct!
    PJ_DECL_LIST_MEMBER(struct call_history_node);
    char * caller_username;
    char * callee_username;
    char * domain;
    int duration;
    time_t start_date;
    int direction;
    int state;
};

#endif /* xaax_common_h */
