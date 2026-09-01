try
    model = 'ETS_Model';
    load_system(model);
    % Let's read the polarity of DC Voltage Source
    % Wait, we can't easily read it, but we can measure it!
    % Let's run a 1-step simulation and print the V_DC voltage and I_N at t=0!
    
    % Wait, let's just check the voltage across the battery!
    add_block('powerlib/Measurements/Voltage Measurement', [model '/V_Bat_Meas']);
    ph_b = get_param([model '/Battery'], 'PortHandles');
    ph_vbm = get_param([model '/V_Bat_Meas'], 'PortHandles');
    
    add_line(model, ph_b.LConn(1), ph_vbm.LConn(1));
    add_line(model, ph_b.RConn(1), ph_vbm.LConn(2));
    
    add_block('simulink/Sinks/To Workspace', [model '/Bat_Volt_Out']);
    set_param([model '/Bat_Volt_Out'], 'VariableName', 'bat_v_sim', 'SaveFormat', 'Array');
    
    add_line(model, ph_vbm.Outport(1), get_param([model '/Bat_Volt_Out'], 'PortHandles').Inport(1));
    
    save_system(model);
    
    sim(model, 'StopTime', '0.001');
    
    v = evalin('base', 'bat_v_sim');
    fprintf('Battery Voltage (LConn relative to RConn): %f\n', v(1));
catch e
    disp(e.message);
end
exit;
