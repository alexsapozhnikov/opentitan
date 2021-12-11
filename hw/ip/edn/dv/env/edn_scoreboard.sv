// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class edn_scoreboard extends cip_base_scoreboard #(
    .CFG_T(edn_env_cfg),
    .RAL_T(edn_reg_block),
    .COV_T(edn_env_cov)
  );
  `uvm_component_utils(edn_scoreboard)

  // local variables

  bit                                           fips;
  push_pull_item#(.HostDataWidth(33),.DeviceDataWidth(33)) endpoint_item;
  push_pull_item#(.HostDataWidth(129),.DeviceDataWidth(129)) genbits_item;
  bit [edn_pkg::ENDPOINT_BUS_WIDTH-1:0]            ep_item, gb_item;

  // TLM agent fifos
  uvm_tlm_analysis_fifo#(push_pull_item#(.HostDataWidth(edn_pkg::FIPS_ENDPOINT_BUS_WIDTH)))
      endpoint_fifo[MAX_NUM_ENDPOINTS];

  // local queues to hold incoming packets pending comparison
  push_pull_item#(.HostDataWidth(edn_pkg::FIPS_ENDPOINT_BUS_WIDTH))
      endpoint_q[$][MAX_NUM_ENDPOINTS];

  // TLM agent fifos
  uvm_tlm_analysis_fifo#(push_pull_item#(.HostDataWidth(csrng_pkg::FIPS_GENBITS_BUS_WIDTH)))
      genbits_fifo;


  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    for (int i = 0; i < MAX_NUM_ENDPOINTS; i++) begin
      endpoint_fifo[i] = new($sformatf("endpoint_fifo[%0d]", i), this);
    end
    genbits_fifo = new("genbits_fifo", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    fork
    compare_genbits();
    join_none
  endtask


  virtual task compare_genbits();

  forever begin

  for (int i = 0; i < edn_env_pkg::MAX_NUM_ENDPOINTS; i++) begin
         genbits_fifo.get(genbits_item);
    for (int j =0; j < 4; j++) begin
         endpoint_fifo[i].get(endpoint_item);
         gb_item =  genbits_item.h_data;
         ep_item =  endpoint_item.d_data;
         `DV_CHECK_EQ_FATAL(ep_item, gb_item);
         `uvm_info(`gfn, $sformatf("gb_item = 0x%0x ep_item = 0x%0x", gb_item, ep_item), UVM_DEBUG)
         genbits_item.h_data = genbits_item.h_data >> 32;
      end
    end
  end

  endtask
        
  virtual task process_tl_access(tl_seq_item item, tl_channels_e channel, string ral_name);
    uvm_reg csr;
    bit     do_read_check   = 1'b1;
    bit     write           = item.is_write();
    uvm_reg_addr_t csr_addr = cfg.ral_models[ral_name].get_word_aligned_addr(item.a_addr);

    bit addr_phase_read   = (!write && channel == AddrChannel);
    bit addr_phase_write  = (write && channel == AddrChannel);
    bit data_phase_read   = (!write && channel == DataChannel);
    bit data_phase_write  = (write && channel == DataChannel);

    // if access was to a valid csr, get the csr handle
    if (csr_addr inside {cfg.ral_models[ral_name].csr_addrs}) begin
      csr = cfg.ral_models[ral_name].default_map.get_reg_by_offset(csr_addr);
      `DV_CHECK_NE_FATAL(csr, null)
    end
    else begin
      `uvm_fatal(`gfn, $sformatf("Access unexpected addr 0x%0h", csr_addr))
    end

    // if incoming access is a write to a valid csr, then make updates right away
    if (addr_phase_write) begin
      void'(csr.predict(.value(item.a_data), .kind(UVM_PREDICT_WRITE), .be(item.a_mask)));
    end

    // process the csr req
    // for write, update local variable and fifo at address phase
    // for read, update predication at address phase and compare at data phase
    case (csr.get_name())
      // add individual case item for each csr
      "intr_state": begin
        // FIXME
        do_read_check = 1'b0;
      end
      "intr_enable": begin
        // FIXME
      end
      "intr_test": begin
        // FIXME
      end
      "ctrl": begin
      end
      "sw_cmd_req": begin
      end
      "sw_cmd_sts": begin
      end
      default: begin
        `uvm_fatal(`gfn, $sformatf("invalid csr: %0s", csr.get_full_name()))
      end
    endcase

    // On reads, if do_read_check, is set, then check mirrored_value against item.d_data
    if (data_phase_read) begin
      if (do_read_check) begin
        `DV_CHECK_EQ(csr.get_mirrored_value(), item.d_data,
                     $sformatf("reg name: %0s", csr.get_full_name()))
      end
      void'(csr.predict(.value(item.d_data), .kind(UVM_PREDICT_READ)));
    end
  endtask

  virtual function void reset(string kind = "HARD");
    super.reset(kind);
    // reset local fifos queues and variables
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    // post test checks - ensure that all local fifos and queues are empty
  endfunction
  

endclass
