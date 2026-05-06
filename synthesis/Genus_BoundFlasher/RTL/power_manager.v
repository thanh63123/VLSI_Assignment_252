`ifdef PCM_MODEL
`else
`define PCM_POWER_UP     5'h0
`define PCM_CLK          5'h1
`define PCM_ISOLATE      5'h2
`define PCM_RETAIN_STATE 5'h3
`define PCM_POWER_DOWN   5'h4
`define PCM_FSM_MSB      2
`define PCM_COUNTER_MSB  1
`define PCM_MAX_COUNT    2'b11
`define PCM_INVERT_ISOLATE
`define PCM_INVERT_STATE_RESTORE

// Generic Power Manager
module power_manager (
  clk, 
  reset,  
  power_down, 
  isolation_enable, 
  state_retention_enable,
  state_retention_restore, 
  power_switch_enable,
  clk_enable
  );

  input clk; 
  input reset; 
  input power_down;
  output isolation_enable;
  output state_retention_enable;
  output state_retention_restore;
  output power_switch_enable;
  output clk_enable;
  
  reg isolation_enable_reg, state_retention_enable_reg, state_retention_restore_reg, power_switch_enable_reg, clk_enable_reg;
  reg next_isolation_enable, next_state_retention_enable, next_state_retention_restore, next_power_switch_enable, next_clk_enable;
  reg clear_counter;
  reg [`PCM_COUNTER_MSB:0] counter;
  reg [`PCM_FSM_MSB:0] power_state;
  reg [`PCM_FSM_MSB:0] next_power_state;
  
// Invert outputs
`ifdef PCM_INVERT_ISOLATE  
  assign isolation_enable = ~isolation_enable_reg;
`else
  assign isolation_enable = isolation_enable_reg;
`endif
`ifdef PCM_INVERT_STATE_RETENTION  
  assign state_retention_enable = ~state_retention_enable_reg;
`else
  assign state_retention_enable = state_retention_enable_reg;
`endif
`ifdef PCM_INVERT_STATE_RESTORE 
  assign state_retention_restore = ~state_retention_restore_reg;
`else
  assign state_retention_restore = state_retention_restore_reg;
`endif
`ifdef PCM_INVERT_POWER_SWITCH
  assign power_switch_enable = ~power_switch_enable_reg;
`else
  assign power_switch_enable = power_switch_enable_reg;
`endif
`ifdef PCM_INVERT_CLK_ENABLE
  assign clk_enable = ~clk_enable_reg;
`else
  assign clk_enable = clk_enable_reg;
`endif

  // Next Power State and Output Logic 
  always @(counter or power_down or power_state or 
           isolation_enable_reg or state_retention_enable_reg or power_switch_enable_reg)
    begin
      clear_counter <= 1'b0;
      next_power_state <= power_state;
      next_isolation_enable <= isolation_enable_reg;
      next_state_retention_enable <= 1'b0;
      next_state_retention_restore <= 1'b0;
      next_power_switch_enable <= power_switch_enable_reg;
      next_clk_enable <= clk_enable_reg;
      if (counter == `PCM_MAX_COUNT)
        begin
          case (power_state)
            `PCM_POWER_UP:
              begin
                if (power_down == 1'b1)
                  begin
                    clear_counter <= 1'b1;
                    next_power_state <= `PCM_CLK;
                    next_clk_enable <= 1'b0;
                  end
               end
            `PCM_CLK:
              begin 
                clear_counter <= 1'b1;
                if (power_down == 1'b1)
                  begin
                    next_power_state <= `PCM_ISOLATE;
                    next_isolation_enable <= 1'b1;
                  end
                else
                  begin
                    next_power_state <= `PCM_POWER_UP;
                    next_clk_enable <= 1'b1;
                  end
              end
            `PCM_ISOLATE:
              begin
                clear_counter <= 1'b1;
                if (power_down == 1'b1)
                  begin
                    next_power_state <= `PCM_RETAIN_STATE;
                    next_state_retention_enable <= 1'b1; 
                  end
                else
                  begin
                    next_power_state <= `PCM_CLK;
                    next_isolation_enable <= 1'b0;
                  end
              end
            `PCM_RETAIN_STATE:
              begin
                clear_counter <= 1'b1;
                if (power_down == 1'b1)
                  begin
                    next_power_state <= `PCM_POWER_DOWN;
                    next_power_switch_enable <= 1'b1;
                  end
                else
                  begin
                    next_power_state <= `PCM_ISOLATE;
                    next_state_retention_restore <= 1'b1;
                  end
              end
            `PCM_POWER_DOWN:
              begin
                if (power_down == 1'b0)
                  begin
                    clear_counter <= 1'b1;
                    next_power_state <= `PCM_RETAIN_STATE;
                    next_power_switch_enable <= 1'b0;
                  end
              end
          endcase
        end
    end

  // Set Current Power State and Outputs
  always @(posedge clk or posedge reset)
    begin
      if (reset)
        begin
          power_state <= `PCM_POWER_UP;
          isolation_enable_reg <= 1'b0;
          state_retention_enable_reg <= 1'b0;
          state_retention_restore_reg <= 1'b0;
          power_switch_enable_reg <= 1'b0;
          clk_enable_reg <= 1'b1;
        end
      else
        begin
          power_state <= next_power_state;
          isolation_enable_reg <= next_isolation_enable;
          state_retention_enable_reg <= next_state_retention_enable;
          state_retention_restore_reg <= next_state_retention_restore;
          power_switch_enable_reg <= next_power_switch_enable;
          clk_enable_reg <= next_clk_enable;
        end
    end
  // Counter for spacing signals
  always @(posedge clk or posedge reset)
    begin
      if (reset)
        counter <= 4'b0;
      else if (clear_counter == 1'b1)
        counter <= 4'b0;
      else if (counter == `PCM_MAX_COUNT)
        counter <= counter;
      else
        counter <= counter + 1;
    end

endmodule
`endif
