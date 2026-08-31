try
    model = 'ETS_Model';
    load_system(model);
    
    % Clean up existing lines
    lines = find_system(model, 'FindAll', 'on', 'Type', 'line');
    delete_line(lines);
    
    % Reposition blocks for better layout
    set_param([model '/powergui'], 'Position', [30, 30, 100, 60]);
    set_param([model '/PMSM'], 'Position', [600, 200, 700, 300]);
    set_param([model '/Inverter'], 'Position', [350, 150, 450, 300]);
    set_param([model '/DC_Bus_Cap'], 'Position', [250, 150, 300, 300]);
    set_param([model '/Battery'], 'Position', [50, 350, 100, 400]);
    set_param([model '/Inductor_L2'], 'Position', [200, 360, 250, 390]);
    set_param([model '/EFOC_Controller'], 'Position', [100, 100, 200, 150]);
    
    % Get port handles
    p_pmsm = get_param([model '/PMSM'], 'PortHandles');
    p_inv = get_param([model '/Inverter'], 'PortHandles');
    p_cap = get_param([model '/DC_Bus_Cap'], 'PortHandles');
    p_bat = get_param([model '/Battery'], 'PortHandles');
    p_ind = get_param([model '/Inductor_L2'], 'PortHandles');
    
    % Connect Phase A, B, C between Inverter and PMSM
    add_line(model, p_inv.LConn(1), p_pmsm.LConn(1));
    add_line(model, p_inv.LConn(2), p_pmsm.LConn(2));
    add_line(model, p_inv.LConn(3), p_pmsm.LConn(3));
    
    % Connect DC Bus Capacitor across Inverter DC ports (RConn 1 and 2)
    add_line(model, p_inv.RConn(1), p_cap.LConn(1));
    add_line(model, p_inv.RConn(2), p_cap.RConn(1));
    
    % Connect Battery Negative to Inverter DC Negative
    add_line(model, p_bat.RConn(1), p_inv.RConn(2));
    
    % Connect Battery Positive to Inductor L2
    add_line(model, p_bat.LConn(1), p_ind.LConn(1));
    
    % Save
    save_system(model);
    disp('Successfully connected the standard wires.');
catch e
    disp(e.message);
end
exit;
