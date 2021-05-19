/// Copyright by Syntacore LLC © 2016-2020. See LICENSE for details
/// @file       <scr1_top_tb_axi.sv>
/// @brief      SCR1 top testbench AXI
///

`include "scr1_arch_description.svh"
`ifdef SCR1_IPIC_EN
`include "scr1_ipic.svh"
`endif // SCR1_IPIC_EN

module scr1_top_tb_axi (
    input logic clk,
    input logic rst_n
`ifdef SCR1_DBG_EN
    ,
`ifdef SCR1_EXPOSE_DM_ONLY
    // DM Interface
    input   logic                                   dmi_req,                // DMI request
    input   logic                                   dmi_wr,                 // DMI write
//TODO find better workaround than hardcoding the values to make Vivado compile
//    input   logic [SCR1_DBG_DMI_ADDR_WIDTH-1:0]     dmi_addr,               // DMI address
    input   logic [7-1:0]     dmi_addr,               // DMI address
//TODO find better workaround than hardcoding the values to make Vivado compile
//    input   logic [SCR1_DBG_DMI_DATA_WIDTH-1:0]     dmi_wdata,              // DMI write data
    input   logic [32-1:0]     dmi_wdata,              // DMI write data
    output  logic                                   dmi_resp,               // DMI response
//TODO find better workaround than hardcoding the values to make Vivado compile
//    output  logic [SCR1_DBG_DMI_DATA_WIDTH-1:0]     dmi_rdata,              // DMI read data
    output  logic [32-1:0]     dmi_rdata,              // DMI read data
`else
    // -- JTAG I/F
    input   logic                                   tck,
    input   logic                                   tms,
    input   logic                                   tdi,
    output  logic                                   tdo,
    output  logic                                   tdo_en,
`endif
`endif // SCR1_DBG_EN
);

//------------------------------------------------------------------------------
// Local parameters
//------------------------------------------------------------------------------
localparam                          SCR1_MEM_SIZE       = 1024*1024;

//------------------------------------------------------------------------------
// Local signal declaration
//------------------------------------------------------------------------------

// Leftovers from JTAG as it is used else where too
`ifdef SCR1_DBG_EN
logic                                   trst_n;
assign trst_n = 1'b1;
`endif

logic                                   rtc_clk;
assign rtc_clk = clk;

logic   [31:0]                          fuse_mhartid;
integer                                 imem_req_ack_stall;
integer                                 dmem_req_ack_stall;
`ifdef SCR1_IPIC_EN
logic [SCR1_IRQ_LINES_NUM-1:0]          irq_lines;
`else // SCR1_IPIC_EN
logic                                   ext_irq;
`endif // SCR1_IPIC_EN
logic                                   soft_irq;

// Instruction Memory
logic [3:0]                             io_axi_imem_awid;
logic [31:0]                            io_axi_imem_awaddr;
logic [7:0]                             io_axi_imem_awlen;
logic [2:0]                             io_axi_imem_awsize;
logic [1:0]                             io_axi_imem_awburst;
logic                                   io_axi_imem_awlock;
logic [3:0]                             io_axi_imem_awcache;
logic [2:0]                             io_axi_imem_awprot;
logic [3:0]                             io_axi_imem_awregion;
logic [3:0]                             io_axi_imem_awuser;
logic [3:0]                             io_axi_imem_awqos;
logic                                   io_axi_imem_awvalid;
logic                                   io_axi_imem_awready;
logic [31:0]                            io_axi_imem_wdata;
logic [3:0]                             io_axi_imem_wstrb;
logic                                   io_axi_imem_wlast;
logic [3:0]                             io_axi_imem_wuser;
logic                                   io_axi_imem_wvalid;
logic                                   io_axi_imem_wready;
logic [3:0]                             io_axi_imem_bid;
logic [1:0]                             io_axi_imem_bresp;
logic                                   io_axi_imem_bvalid;
logic [3:0]                             io_axi_imem_buser;
logic                                   io_axi_imem_bready;
logic [3:0]                             io_axi_imem_arid;
logic [31:0]                            io_axi_imem_araddr;
logic [7:0]                             io_axi_imem_arlen;
logic [2:0]                             io_axi_imem_arsize;
logic [1:0]                             io_axi_imem_arburst;
logic                                   io_axi_imem_arlock;
logic [3:0]                             io_axi_imem_arcache;
logic [2:0]                             io_axi_imem_arprot;
logic [3:0]                             io_axi_imem_arregion;
logic [3:0]                             io_axi_imem_aruser;
logic [3:0]                             io_axi_imem_arqos;
logic                                   io_axi_imem_arvalid;
logic                                   io_axi_imem_arready;
logic [3:0]                             io_axi_imem_rid;
logic [31:0]                            io_axi_imem_rdata;
logic [1:0]                             io_axi_imem_rresp;
logic                                   io_axi_imem_rlast;
logic [3:0]                             io_axi_imem_ruser;
logic                                   io_axi_imem_rvalid;
logic                                   io_axi_imem_rready;

// Data Memory
logic [3:0]                             io_axi_dmem_awid;
logic [31:0]                            io_axi_dmem_awaddr;
logic [7:0]                             io_axi_dmem_awlen;
logic [2:0]                             io_axi_dmem_awsize;
logic [1:0]                             io_axi_dmem_awburst;
logic                                   io_axi_dmem_awlock;
logic [3:0]                             io_axi_dmem_awcache;
logic [2:0]                             io_axi_dmem_awprot;
logic [3:0]                             io_axi_dmem_awregion;
logic [3:0]                             io_axi_dmem_awuser;
logic [3:0]                             io_axi_dmem_awqos;
logic                                   io_axi_dmem_awvalid;
logic                                   io_axi_dmem_awready;
logic [31:0]                            io_axi_dmem_wdata;
logic [3:0]                             io_axi_dmem_wstrb;
logic                                   io_axi_dmem_wlast;
logic [3:0]                             io_axi_dmem_wuser;
logic                                   io_axi_dmem_wvalid;
logic                                   io_axi_dmem_wready;
logic [3:0]                             io_axi_dmem_bid;
logic [1:0]                             io_axi_dmem_bresp;
logic                                   io_axi_dmem_bvalid;
logic [3:0]                             io_axi_dmem_buser;
logic                                   io_axi_dmem_bready;
logic [3:0]                             io_axi_dmem_arid;
logic [31:0]                            io_axi_dmem_araddr;
logic [7:0]                             io_axi_dmem_arlen;
logic [2:0]                             io_axi_dmem_arsize;
logic [1:0]                             io_axi_dmem_arburst;
logic                                   io_axi_dmem_arlock;
logic [3:0]                             io_axi_dmem_arcache;
logic [2:0]                             io_axi_dmem_arprot;
logic [3:0]                             io_axi_dmem_arregion;
logic [3:0]                             io_axi_dmem_aruser;
logic [3:0]                             io_axi_dmem_arqos;
logic                                   io_axi_dmem_arvalid;
logic                                   io_axi_dmem_arready;
logic [3:0]                             io_axi_dmem_rid;
logic [31:0]                            io_axi_dmem_rdata;
logic [1:0]                             io_axi_dmem_rresp;
logic                                   io_axi_dmem_rlast;
logic [3:0]                             io_axi_dmem_ruser;
logic                                   io_axi_dmem_rvalid;
logic                                   io_axi_dmem_rready;

//------------------------------------------------------------------------------
// Core instance
//------------------------------------------------------------------------------
scr1_top_axi i_top (
    // Reset
    .pwrup_rst_n            (rst_n                  ),
    .rst_n                  (rst_n                  ),
    .cpu_rst_n              (rst_n                  ),
`ifdef SCR1_DBG_EN
    .sys_rst_n_o            (                       ),
    .sys_rdc_qlfy_o         (                       ),
`endif // SCR1_DBG_EN

    // Clock
    .clk                    (clk                    ),
    .rtc_clk                (rtc_clk                ),

    // Fuses
    .fuse_mhartid           (fuse_mhartid           ),
`ifdef SCR1_DBG_EN
    .fuse_idcode            (`SCR1_TAP_IDCODE       ),
`endif // SCR1_DBG_EN

    // IRQ
`ifdef SCR1_IPIC_EN
    .irq_lines              (irq_lines              ),
`else // SCR1_IPIC_EN
    .ext_irq                (ext_irq                ),
`endif // SCR1_IPIC_EN
    .soft_irq               (soft_irq               ),

    // DFT
    .test_mode              (1'b0                   ),
    .test_rst_n             (1'b1                   ),

`ifdef SCR1_DBG_EN
    ,
`ifdef SCR1_EXPOSE_DM_ONLY
    // DM Interface
    .dmi_req(dmi_req),
    .dmi_wr(dmi_wr),
    .dmi_addr(dmi_addr),
    .dmi_wdata(dmi_wdata),
    .dmi_resp(dmi_resp),
    .dmi_rdata(dmi_rdata),

    // Leftovers from JTAG as it is used else where too
    .trst_n(trst_n),
`else
    // -- JTAG I/F
    .trst_n(trst_n),
    .tck(tck),
    .tms(tms),
    .tdi(tdi),
    .tdo(tdo),
    .tdo_en(tdo_en),
`endif
`endif // SCR1_DBG_EN

    // Instruction memory interface
    .io_axi_imem_awid       (io_axi_imem_awid       ),
    .io_axi_imem_awaddr     (io_axi_imem_awaddr     ),
    .io_axi_imem_awlen      (io_axi_imem_awlen      ),
    .io_axi_imem_awsize     (io_axi_imem_awsize     ),
    .io_axi_imem_awburst    (),
    .io_axi_imem_awlock     (),
    .io_axi_imem_awcache    (),
    .io_axi_imem_awprot     (),
    .io_axi_imem_awregion   (),
    .io_axi_imem_awuser     (),
    .io_axi_imem_awqos      (),
    .io_axi_imem_awvalid    (io_axi_imem_awvalid    ),
    .io_axi_imem_awready    (io_axi_imem_awready    ),
    .io_axi_imem_wdata      (io_axi_imem_wdata      ),
    .io_axi_imem_wstrb      (io_axi_imem_wstrb      ),
    .io_axi_imem_wlast      (io_axi_imem_wlast      ),
    .io_axi_imem_wuser      (),
    .io_axi_imem_wvalid     (io_axi_imem_wvalid     ),
    .io_axi_imem_wready     (io_axi_imem_wready     ),
    .io_axi_imem_bid        (io_axi_imem_bid        ),
    .io_axi_imem_bresp      (io_axi_imem_bresp      ),
    .io_axi_imem_bvalid     (io_axi_imem_bvalid     ),
    .io_axi_imem_buser      (4'd0                   ),
    .io_axi_imem_bready     (io_axi_imem_bready     ),
    .io_axi_imem_arid       (io_axi_imem_arid       ),
    .io_axi_imem_araddr     (io_axi_imem_araddr     ),
    .io_axi_imem_arlen      (io_axi_imem_arlen      ),
    .io_axi_imem_arsize     (io_axi_imem_arsize     ),
    .io_axi_imem_arburst    (io_axi_imem_arburst    ),
    .io_axi_imem_arlock     (),
    .io_axi_imem_arcache    (),
    .io_axi_imem_arprot     (),
    .io_axi_imem_arregion   (),
    .io_axi_imem_aruser     (),
    .io_axi_imem_arqos      (),
    .io_axi_imem_arvalid    (io_axi_imem_arvalid    ),
    .io_axi_imem_arready    (io_axi_imem_arready    ),
    .io_axi_imem_rid        (io_axi_imem_rid        ),
    .io_axi_imem_rdata      (io_axi_imem_rdata      ),
    .io_axi_imem_rresp      (io_axi_imem_rresp      ),
    .io_axi_imem_rlast      (io_axi_imem_rlast      ),
    .io_axi_imem_ruser      (4'd0                   ),
    .io_axi_imem_rvalid     (io_axi_imem_rvalid     ),
    .io_axi_imem_rready     (io_axi_imem_rready     ),

    // Data memory interface
    .io_axi_dmem_awid       (io_axi_dmem_awid       ),
    .io_axi_dmem_awaddr     (io_axi_dmem_awaddr     ),
    .io_axi_dmem_awlen      (io_axi_dmem_awlen      ),
    .io_axi_dmem_awsize     (io_axi_dmem_awsize     ),
    .io_axi_dmem_awburst    (),
    .io_axi_dmem_awlock     (),
    .io_axi_dmem_awcache    (),
    .io_axi_dmem_awprot     (),
    .io_axi_dmem_awregion   (),
    .io_axi_dmem_awuser     (),
    .io_axi_dmem_awqos      (),
    .io_axi_dmem_awvalid    (io_axi_dmem_awvalid    ),
    .io_axi_dmem_awready    (io_axi_dmem_awready    ),
    .io_axi_dmem_wdata      (io_axi_dmem_wdata      ),
    .io_axi_dmem_wstrb      (io_axi_dmem_wstrb      ),
    .io_axi_dmem_wlast      (io_axi_dmem_wlast      ),
    .io_axi_dmem_wuser      (),
    .io_axi_dmem_wvalid     (io_axi_dmem_wvalid     ),
    .io_axi_dmem_wready     (io_axi_dmem_wready     ),
    .io_axi_dmem_bid        (io_axi_dmem_bid        ),
    .io_axi_dmem_bresp      (io_axi_dmem_bresp      ),
    .io_axi_dmem_bvalid     (io_axi_dmem_bvalid     ),
    .io_axi_dmem_buser      (4'd0                   ),
    .io_axi_dmem_bready     (io_axi_dmem_bready     ),
    .io_axi_dmem_arid       (io_axi_dmem_arid       ),
    .io_axi_dmem_araddr     (io_axi_dmem_araddr     ),
    .io_axi_dmem_arlen      (io_axi_dmem_arlen      ),
    .io_axi_dmem_arsize     (io_axi_dmem_arsize     ),
    .io_axi_dmem_arburst    (io_axi_dmem_arburst    ),
    .io_axi_dmem_arlock     (),
    .io_axi_dmem_arcache    (),
    .io_axi_dmem_arprot     (),
    .io_axi_dmem_arregion   (),
    .io_axi_dmem_aruser     (),
    .io_axi_dmem_arqos      (),
    .io_axi_dmem_arvalid    (io_axi_dmem_arvalid    ),
    .io_axi_dmem_arready    (io_axi_dmem_arready    ),
    .io_axi_dmem_rid        (io_axi_dmem_rid        ),
    .io_axi_dmem_rdata      (io_axi_dmem_rdata      ),
    .io_axi_dmem_rresp      (io_axi_dmem_rresp      ),
    .io_axi_dmem_rlast      (io_axi_dmem_rlast      ),
    .io_axi_dmem_ruser      (4'd0                   ),
    .io_axi_dmem_rvalid     (io_axi_dmem_rvalid     ),
    .io_axi_dmem_rready     (io_axi_dmem_rready     )
);


//-------------------------------------------------------------------------------
// Memory instance
//-------------------------------------------------------------------------------
scr1_memory_tb_axi #(
    .SIZE    (SCR1_MEM_SIZE),
    .N_IF    (2            ),
    .W_ADR   (32           ),
    .W_DATA  (32           )
) i_memory_tb (
    // Common
    .rst_n          (rst_n),
    .clk            (clk),
`ifdef SCR1_IPIC_EN
    .irq_lines      (irq_lines),
`else // SCR1_IPIC_EN
    .ext_irq        (ext_irq),
`endif // SCR1_IPIC_EN
    .soft_irq       (soft_irq),

    // Write address channel
    .awid           ( {io_axi_imem_awid,   io_axi_dmem_awid}      ),
    .awaddr         ( {io_axi_imem_awaddr, io_axi_dmem_awaddr}    ),
    .awsize         ( {io_axi_imem_awsize, io_axi_dmem_awsize}    ),
    .awlen          ( {io_axi_imem_awlen,  io_axi_dmem_awlen}     ),
    .awvalid        ( {io_axi_imem_awvalid,io_axi_dmem_awvalid}   ),
    .awready        ( {io_axi_imem_awready,io_axi_dmem_awready}   ),

    // Write data channel
    .wdata          ( {io_axi_imem_wdata,  io_axi_dmem_wdata}     ),
    .wstrb          ( {io_axi_imem_wstrb,  io_axi_dmem_wstrb}     ),
    .wvalid         ( {io_axi_imem_wvalid, io_axi_dmem_wvalid}    ),
    .wlast          ( {io_axi_imem_wlast,  io_axi_dmem_wlast}     ),
    .wready         ( {io_axi_imem_wready, io_axi_dmem_wready}    ),

    // Write response channel
    .bready         ( {io_axi_imem_bready, io_axi_dmem_bready}    ),
    .bvalid         ( {io_axi_imem_bvalid, io_axi_dmem_bvalid}    ),
    .bid            ( {io_axi_imem_bid,    io_axi_dmem_bid}       ),
    .bresp          ( {io_axi_imem_bresp,  io_axi_dmem_bresp}     ),

    // Read address channel
    .arid           ( {io_axi_imem_arid,   io_axi_dmem_arid}      ),
    .araddr         ( {io_axi_imem_araddr, io_axi_dmem_araddr}    ),
    .arburst        ( {io_axi_imem_arburst,io_axi_dmem_arburst}   ),
    .arsize         ( {io_axi_imem_arsize, io_axi_dmem_arsize}    ),
    .arlen          ( {io_axi_imem_arlen,  io_axi_dmem_arlen}     ),
    .arvalid        ( {io_axi_imem_arvalid,io_axi_dmem_arvalid}   ),
    .arready        ( {io_axi_imem_arready,io_axi_dmem_arready}   ),

    // Read data channel
    .rvalid         ( {io_axi_imem_rvalid, io_axi_dmem_rvalid}    ),
    .rready         ( {io_axi_imem_rready, io_axi_dmem_rready}    ),
    .rid            ( {io_axi_imem_rid,    io_axi_dmem_rid}       ),
    .rdata          ( {io_axi_imem_rdata,  io_axi_dmem_rdata}     ),
    .rlast          ( {io_axi_imem_rlast,  io_axi_dmem_rlast}     ),
    .rresp          ( {io_axi_imem_rresp,  io_axi_dmem_rresp}     )
);

endmodule : scr1_top_tb_axi
