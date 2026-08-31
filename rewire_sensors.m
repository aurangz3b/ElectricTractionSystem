try
    model = 'ETS_Model';
    load_system(model);
    ph_vdc = get_param([model '/V_DC'], 'PortHandles');
    
    % Let's delete existing lines and manually rewire V_DC and I_N to be absolutely 100% sure!
    % Delete V_DC lines
    if get_param(ph_vdc.LConn(1), 'Line') ~= -1, delete_line(get_param(ph_vdc.LConn(1), 'Line')); end
    if get_param(ph_vdc.LConn(2), 'Line') ~= -1, delete_line(get_param(ph_vdc.LConn(2), 'Line')); end
    
    % Connect V_DC across DC_Cap
    p_cap = get_param([model '/DC_Bus_Cap'], 'PortHandles');
    add_line(model, p_cap.LConn(1), ph_vdc.LConn(1));
    add_line(model, p_cap.RConn(1), ph_vdc.LConn(2));
    
    % Let's do I_N! It should measure neutral current.
    % Neutral current flows from Battery -> L2 -> Neutral.
    % We should place I_N in series with L2!
    % So Battery -> I_N -> L2.
    ph_bat = get_param([model '/Battery'], 'PortHandles');
    ph_ind = get_param([model '/Inductor_L2'], 'PortHandles');
    ph_in = get_param([model '/I_N'], 'PortHandles');
    
    % Break existing Battery -> L2 line if any
    bat_line = get_param(ph_bat.LConn(1), 'Line');
    if bat_line ~= -1, delete_line(bat_line); end
    
    l2_line = get_param(ph_ind.LConn(1), 'Line');
    if l2_line ~= -1, delete_line(l2_line); end
    
    % Also clear I_N lines
    if get_param(ph_in.LConn(1), 'Line') ~= -1, delete_line(get_param(ph_in.LConn(1), 'Line')); end
    if get_param(ph_in.RConn(1), 'Line') ~= -1, delete_line(get_param(ph_in.RConn(1), 'Line')); end
    
    % Wire: Battery POS -> I_N(+) -> I_N(-) -> Inductor_L2
    add_line(model, ph_bat.LConn(1), ph_in.LConn(1));
    add_line(model, ph_in.RConn(1), ph_ind.LConn(1));
    
    save_system(model);
    disp('Successfully rewired V_DC and I_N sensors directly into the power circuit!');
catch e
    disp(e.message);
end
exit;
