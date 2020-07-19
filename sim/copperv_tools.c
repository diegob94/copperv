#include <vpi_user.h>
#include <veriuser.h>

#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <ctype.h>

#define BUF_SIZE 32767
#define STR_SIZE 1023

typedef struct Diss_data { 
    char msg_prefix[STR_SIZE];
    char* buf[BUF_SIZE];
    PLI_UINT32 min_addr;
    PLI_UINT32 max_addr;
} Diss_data_s, *Diss_data_p;

static void sim_log(const char *fmt, ...) {
    Diss_data_p diss_data = (Diss_data_p)tf_getworkarea();
    va_list args;
    char buf[STR_SIZE];
    va_start(args, fmt);
    vsprintf(buf,fmt, args);
    vpi_printf("%s: %s\n", diss_data->msg_prefix, buf);
    va_end(args);
}

static void sim_error(const char* msg) {
    sim_log("Error: %s",msg);
    vpi_control(vpiFinish, 1);
}

static void read_file(char* file_name, char** buf, PLI_UINT32* min_addr, PLI_UINT32* max_addr){
    FILE* fp;
    char* line = NULL;
    PLI_UINT32 addr;
    size_t n;
    ssize_t r;
    char * pch;
    size_t i;
    fp = fopen(file_name, "r");
    while((r = getline(&line,&n,fp)) != -1) {
        //printf("%d >%s<\n", r, line);
        i = strcspn(line,":");
        if((ssize_t)i != r){
            addr = strtol(line,&pch,16);
            if(pch == line + i) {
                //printf("%d -> %s\n",addr,line);
                if(addr < *min_addr)
                    *min_addr = addr;
                if(addr > *max_addr)
                    *max_addr = addr;
                buf[addr>>2] = (char*)malloc(r);
                line[r-1] = '\0';
                strcpy(buf[addr>>2],line);
            }
        }
    }
//    printf("0 -> %s\n", buf[0]);
    free(line);
    fclose(fp);
}

static PLI_INT32 get_diss_compiletf(PLI_BYTE8* user_data) {
    (void)user_data;
    Diss_data_p diss_data = (Diss_data_p) malloc(sizeof(Diss_data_s));
    tf_setworkarea((PLI_BYTE8*) diss_data);
    strcpy(diss_data->msg_prefix,"GET_DISS_VPI");
    char* file_name = NULL;
    file_name = mc_scan_plusargs("DISS_FILE=");
    if(file_name == NULL) {
        sim_log("No dissassembly file given, monitor is disabled: vvp sim.vvp +DISS_FILE=test.D");
        return 0;
    }
    sim_log("Reading %s", file_name);
    read_file(file_name, diss_data->buf, &diss_data->min_addr, &diss_data->max_addr);
    sim_log("Reading done: min_addr 0x%X max_addr 0x%X", diss_data->min_addr, diss_data->max_addr);
    return 0;
}

//static void print_iterator(vpiHandle arg_iterator) {
//    PLI_INT32 tfarg_type;
//    vpiHandle arg_handle;
//    while(1){
//        arg_handle = vpi_scan(arg_iterator);
//        if(arg_handle == NULL){
//            break;
//        }
//        tfarg_type = vpi_get(vpiType, arg_handle);
//        if(tfarg_type == vpiNet) {
//            vpi_printf("get_diss: arg is net\n");
//        } else if(tfarg_type == vpiReg) {
//            vpi_printf("get_diss: arg is reg\n");
//        }
//    }
//}

static PLI_UINT32 getArgs(vpiHandle systf_handle) {
    PLI_INT32 tfarg_type;
    PLI_UINT32 pc;
    vpiHandle arg_iterator, arg_handle;
    s_vpi_value value_s;
    value_s.format = vpiIntVal;
    arg_iterator = vpi_iterate(vpiArgument, systf_handle);
    arg_handle = vpi_scan(arg_iterator);
    if(arg_handle == NULL){
        sim_error("$get_diss(PC) arg missing");
    }
    tfarg_type = vpi_get(vpiType, arg_handle);
    if(tfarg_type != vpiReg) {
        sim_error("$get_diss(PC) arg should be reg type");
    }
    vpi_get_value(arg_handle, &value_s);
    pc = value_s.value.integer;
    //sim_log("pc value %0d",pc);
    return pc;
}

static PLI_INT32 get_diss_calltf(PLI_BYTE8* user_data) {
    (void)user_data;
    PLI_UINT32 pc = 0;
    s_vpi_value value_s;
    vpiHandle systf_handle;
    Diss_data_p diss_data = (Diss_data_p)tf_getworkarea();
    systf_handle = vpi_handle(vpiSysTfCall, NULL);
    pc = getArgs(systf_handle);
    value_s.format = vpiStringVal;
    if(pc >= diss_data->min_addr && pc <= diss_data->max_addr){
        value_s.value.str = diss_data->buf[pc>>2];
    } else {
        value_s.value.str = "ADDRESS OUT OF RANGE";
    }
    vpi_put_value(systf_handle, &value_s, NULL, vpiNoDelay);
    return 0;
}

void get_diss_register(void) {
      s_vpi_systf_data tf_data;
      tf_data.type      = vpiSysFunc;
      tf_data.tfname    = "$get_diss";
      tf_data.calltf    = get_diss_calltf;
      tf_data.compiletf = get_diss_compiletf;
      tf_data.sizetf    = 0;
      tf_data.user_data = NULL;
      vpi_register_systf(&tf_data);
}

void (*vlog_startup_routines[])(void) = {
    get_diss_register,
    0
};
