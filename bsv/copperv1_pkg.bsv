package copperv1_pkg;

  import DefaultValue :: *;
  
  typedef enum { Error, Ok } Bus_write_response deriving (Bits);
  typedef UInt#(32) Data_t;
  typedef UInt#(32) Addr_t;

  typedef struct { 
    Data_t data;
  } Bus_r_resp deriving (Bits);
  
  typedef struct { 
    Addr_t addr;
  } Bus_r_req deriving (Bits);
  
  instance DefaultValue #( Bus_r_req );
    defaultValue = Bus_r_req { addr : 0 };
  endinstance
  
  typedef struct { 
    Bus_write_response resp;
  } Bus_w_resp deriving (Bits);

  typedef struct { 
    Addr_t addr;
    Data_t data;
  } Bus_w_req deriving (Bits);

endpackage: copperv1_pkg
