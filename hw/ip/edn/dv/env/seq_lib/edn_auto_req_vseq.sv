// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class edn_auto_req_vseq extends edn_base_vseq;
  `uvm_object_utils(edn_auto_req_vseq)

  `uvm_object_new

   //push_pull_host_seq#(edn_pkg::FIPS_ENDPOINT_BUS_WIDTH)
      // m_endpoint_pull_seq[(edn_env_pkg::MAX_NUM_ENDPOINTS)][4];

  bit [csrng_pkg::GENBITS_BUS_WIDTH - 1:0]      genbits;
  bit [entropy_src_pkg::FIPS_BUS_WIDTH - 1:0]   fips;
  bit [edn_pkg::ENDPOINT_BUS_WIDTH - 1:0]       edn_bus[edn_env_pkg::MAX_NUM_ENDPOINTS];

  task body();

    //`uvm_info(`gfn, "auto_req_mode set", UVM_LOW)
    // Send INS cmd
    //csr_wr(.ptr(ral.sw_cmd_req), .value(32'h1));


    // Send GEN cmd w/ GLEN 8 (request single genbits)
    //csr_wr(.ptr(ral.sw_cmd_req), .value(32'h8003));
    //`uvm_info(`gfn, "genbits requested", UVM_LOW)

    csr_wr(.ptr(ral.ctrl.edn_enable), .value(4'b1010));
    csr_wr(.ptr(ral.max_num_reqs_between_reseeds), .value(32'h0003));

      for (int i = 0; i < 2; i++) begin

    csr_wr(.ptr(ral.generate_cmd), .value(32'h000080c3));
    csr_wr(.ptr(ral.generate_cmd), .value(32'h00000301));
    csr_wr(.ptr(ral.generate_cmd), .value(32'h00000302));
    csr_wr(.ptr(ral.generate_cmd), .value(32'h00000303));
    csr_wr(.ptr(ral.generate_cmd), .value(32'h00000304));
    csr_wr(.ptr(ral.generate_cmd), .value(32'h00000305));
    csr_wr(.ptr(ral.generate_cmd), .value(32'h00000306));
    csr_wr(.ptr(ral.generate_cmd), .value(32'h00000307));
    csr_wr(.ptr(ral.generate_cmd), .value(32'h00000308));
    csr_wr(.ptr(ral.generate_cmd), .value(32'h00000309));
    csr_wr(.ptr(ral.generate_cmd), .value(32'h0000030a));
    csr_wr(.ptr(ral.generate_cmd), .value(32'h0000030b));
    csr_wr(.ptr(ral.generate_cmd), .value(32'h0000030c));
    `uvm_info(`gfn, "generate_cmd sent", UVM_LOW)
    
    csr_wr(.ptr(ral.reseed_cmd), .value(32'h000000c2));
    csr_wr(.ptr(ral.reseed_cmd), .value(32'h00000201));
    csr_wr(.ptr(ral.reseed_cmd), .value(32'h00000202));
    csr_wr(.ptr(ral.reseed_cmd), .value(32'h00000203));
    csr_wr(.ptr(ral.reseed_cmd), .value(32'h00000204));
    csr_wr(.ptr(ral.reseed_cmd), .value(32'h00000205));
    csr_wr(.ptr(ral.reseed_cmd), .value(32'h00000206));
    csr_wr(.ptr(ral.reseed_cmd), .value(32'h00000207));
    csr_wr(.ptr(ral.reseed_cmd), .value(32'h000000208));
    csr_wr(.ptr(ral.reseed_cmd), .value(32'h00000209));
    csr_wr(.ptr(ral.reseed_cmd), .value(32'h0000020a));
    csr_wr(.ptr(ral.reseed_cmd), .value(32'h0000020b));
    csr_wr(.ptr(ral.reseed_cmd), .value(32'h0000020c));
    `uvm_info(`gfn, "reseed_cmd sent", UVM_LOW)

    // Wait for cmd_rdy
    csr_spinwait(.ptr(ral.sw_cmd_sts.cmd_rdy), .exp_data(1'b1));
    csr_wr(.ptr(ral.sw_cmd_req), .value(32'h000000c1));
    csr_wr(.ptr(ral.sw_cmd_req), .value(32'h00000101));
    csr_wr(.ptr(ral.sw_cmd_req), .value(32'h00000102));
    csr_wr(.ptr(ral.sw_cmd_req), .value(32'h00000103));
    csr_wr(.ptr(ral.sw_cmd_req), .value(32'h00000104));
    csr_wr(.ptr(ral.sw_cmd_req), .value(32'h00000105));
    csr_wr(.ptr(ral.sw_cmd_req), .value(32'h00000106));
    csr_wr(.ptr(ral.sw_cmd_req), .value(32'h00000107));
    csr_wr(.ptr(ral.sw_cmd_req), .value(32'h00000108));
    csr_wr(.ptr(ral.sw_cmd_req), .value(32'h00000109));
    csr_wr(.ptr(ral.sw_cmd_req), .value(32'h0000010a));
    csr_wr(.ptr(ral.reseed_cmd), .value(32'h0000010b));
    csr_wr(.ptr(ral.reseed_cmd), .value(32'h0000010c));
    `uvm_info(`gfn, "INS is set", UVM_LOW)
    // Expect/Clear interrupt bit
    csr_spinwait(.ptr(ral.intr_state.edn_cmd_req_done), .exp_data(1'b1));
    check_interrupts(.interrupts((1 << CmdReqDone)), .check_set(1'b1));
    `uvm_info(`gfn, "interrupt cleared", UVM_LOW)
    csr_wr(.ptr(ral.ctrl.auto_req_mode), .value(4'b1010));
    `uvm_info(`gfn, "auto_req_mode set", UVM_LOW)
    cfg.clk_rst_vif.wait_clks(1200);
    csr_wr(.ptr(ral.ctrl.auto_req_mode), .value(4'b0101));
    csr_spinwait(.ptr(ral.sw_cmd_sts), .exp_data(2'b01));
    `uvm_info(`gfn, "sts is set", UVM_LOW)

    end

    cfg.clk_rst_vif.wait_clks(50);
    
    endtask

    
endclass
