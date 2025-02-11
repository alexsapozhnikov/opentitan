// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

interface key_sideload_if #(parameter type KEY_T = keymgr_pkg::hw_key_req_t,
                            parameter int  KeyWidth = keymgr_pkg::KeyWidth
);
  // This struct contains three fields:
  // - valid
  // - key_share0
  // - key_share1
  KEY_T sideload_key;

  string msg_id = "key_sideload_if";

  // share0 and share1 are only driven when `valid` is 1.
  task automatic drive_sideload_key(logic key_valid,
                                    logic [KeyWidth-1:0] share0 = '0,
                                    logic [KeyWidth-1:0] share1 = '0);
    KEY_T key;

    `DV_CHECK_STD_RANDOMIZE_WITH_FATAL(key, key.valid == key_valid;, , msg_id)
    key[0] = (key_valid) ? share0 : 'hx;
    key[1] = (key_valid) ? share1 : 'hx;

    sideload_key = key;
  endtask

  task automatic wait_valid(logic is_valid);
    wait (sideload_key.valid === is_valid);
  endtask

endinterface
