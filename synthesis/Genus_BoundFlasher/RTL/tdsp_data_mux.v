module tdsp_data_mux (
    mem_data,
    ds_data,
    t_data,
    t_read,
    ds_read
);



// fetch defines
`include "tdsp.h"

// types...

input   [`MSB:0]    mem_data;       // Scartch Memory Input Data
input   [`MSB:0]    ds_data;        // Data Sample Memory Input Data
input               t_read,         // Scratch memory Read Enable
                    ds_read;        // Data Sample memory Write Enable
output  [`MSB:0]    t_data    ;     // TDSP Data Input bus

reg     [`MSB:0]    t_data;


always @ (t_read or ds_read or mem_data or ds_data)
	if (ds_read)
		t_data <= ds_data ;
	else
		t_data <= mem_data;

endmodule // tdsp_data_mux
