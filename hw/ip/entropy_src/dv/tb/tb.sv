// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
module tb;
  // dep packages
  import uvm_pkg::*;
  import dv_utils_pkg::*;
  import entropy_src_env_pkg::*;
  import entropy_src_test_pkg::*;

  // macro includes
  `include "uvm_macros.svh"
  `include "dv_macros.svh"

  wire clk, rst_n, devmode;
  wire intr_entropy_valid, intr_health_test_failed, intr_ebus_check_failed,
       intr_observe_fifo_ready, intr_fatal_err;
  wire [NUM_MAX_INTERRUPTS-1:0] interrupts;
  wire [7:0]                    otp_en_es_fw_read, otp_en_es_fw_over;

  // interfaces
  clk_rst_if clk_rst_if(.clk(clk), .rst_n(rst_n));
  pins_if#(NUM_MAX_INTERRUPTS) intr_if(interrupts);
  pins_if#(1) devmode_if(devmode);
  pins_if#(8) otp_en_es_fw_read_if(otp_en_es_fw_read);
  pins_if#(8) otp_en_es_fw_over_if(otp_en_es_fw_over);
  tl_if tl_if(.clk(clk), .rst_n(rst_n));
  push_pull_if#(.HostDataWidth(entropy_src_pkg::RNG_BUS_WIDTH))
      rng_if(.clk(clk), .rst_n(rst_n));
  push_pull_if#(.HostDataWidth(entropy_src_pkg::FIPS_CSRNG_BUS_WIDTH))
      csrng_if(.clk(clk), .rst_n(rst_n));

  `DV_ALERT_IF_CONNECT

  // dut
  entropy_src dut (
    .clk_i                        (clk        ),
    .rst_ni                       (rst_n      ),

    .tl_i                         (tl_if.h2d  ),
    .tl_o                         (tl_if.d2h  ),

    .otp_en_entropy_src_fw_read_i (otp_en_es_fw_read),
    .otp_en_entropy_src_fw_over_i (otp_en_es_fw_over),

    .entropy_src_hw_if_o          ({csrng_if.ack,
                                    csrng_if.d_data[entropy_src_pkg::CSRNG_BUS_WIDTH-1:0],
                                    csrng_if.d_data[entropy_src_pkg::CSRNG_BUS_WIDTH]}),
    .entropy_src_hw_if_i          (csrng_if.req),

    .cs_aes_halt_o                (),
    .cs_aes_halt_i                (1'b1),

    .entropy_src_xht_o            (),
    .entropy_src_xht_i            ('0),

    .entropy_src_rng_o            (rng_if.ready),
    .entropy_src_rng_i            ({rng_if.valid, rng_if.h_data}),

    .alert_rx_i                   (alert_rx),
    .alert_tx_o                   (alert_tx),

    .intr_es_entropy_valid_o      (intr_entropy_valid),
    .intr_es_health_test_failed_o (intr_health_test_failed),
  // TODO: add intrp
  //    .intr_es_ebus_check_failed_o  (intr_ebus_check_failed),
    .intr_es_observe_fifo_ready_o (intr_observe_fifo_ready),
    .intr_es_fatal_err_o          (intr_fatal_err)
  );

  // TODO: remove when intrp is added
  assign intr_ebus_check_failed = 1'b0;

  assign interrupts[EntropyValid]     = intr_entropy_valid;
  assign interrupts[HealthTestFailed] = intr_health_test_failed;
  assign interrupts[EBusChkFailed]    = intr_ebus_check_failed;
  assign interrupts[ObserveFifoReady] = intr_observe_fifo_ready;
  assign interrupts[FatalErr]         = intr_fatal_err;

  initial begin
    // Drive clk and rst_n from clk_if
    // Set interfaces in config_db
    clk_rst_if.set_active();
    uvm_config_db#(virtual clk_rst_if)::set(null, "*.env", "clk_rst_vif", clk_rst_if);
    uvm_config_db#(intr_vif)::set(null, "*.env", "intr_vif", intr_if);
    uvm_config_db#(devmode_vif)::set(null, "*.env", "devmode_vif", devmode_if);
    uvm_config_db#(virtual pins_if#(8))::set(null, "*.env", "otp_en_es_fw_read_vif",
                                         otp_en_es_fw_read_if);
    uvm_config_db#(virtual pins_if#(8))::set(null, "*.env", "otp_en_es_fw_over_vif",
                                         otp_en_es_fw_over_if);
    uvm_config_db#(virtual tl_if)::set(null, "*.env.m_tl_agent*", "vif", tl_if);
    uvm_config_db#(virtual push_pull_if#(.HostDataWidth(entropy_src_pkg::RNG_BUS_WIDTH)))::set
                                        (null, "*.env.m_rng_agent*", "vif", rng_if);
    uvm_config_db#(virtual push_pull_if#(.HostDataWidth(entropy_src_pkg::FIPS_CSRNG_BUS_WIDTH)))::
      set(null, "*.env.m_csrng_agent*", "vif", csrng_if);
    $timeformat(-12, 0, " ps", 12);
    run_test();
  end

endmodule
