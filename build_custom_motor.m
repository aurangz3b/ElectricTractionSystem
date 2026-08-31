try
    model = 'ETS_Model';
    load_system(model);
    
    % Delete EVERYTHING except blocks we want to keep
    % Actually, delete ALL lines
    lines = find_system(model, 'FindAll', 'on', 'Type', 'line');
    delete_line(lines);
    
    % Delete PMSM
    pmsm_block = [model '/PMSM'];
    if getSimulinkBlockHandle(pmsm_block) ~= -1
        delete_block(pmsm_block);
    end
    
    % (Re)add everything safely
    % RLC branches
    if getSimulinkBlockHandle([model '/RLC_A']) == -1
        add_block('powerlib/Elements/Series RLC Branch', [model '/RLC_A'], 'Position', [600, 150, 650, 180]);
        add_block('powerlib/Elements/Series RLC Branch', [model '/RLC_B'], 'Position', [600, 200, 650, 230]);
        add_block('powerlib/Elements/Series RLC Branch', [model '/RLC_C'], 'Position', [600, 250, 650, 280]);
        set_param([model '/RLC_A'], 'Resistance', '0.81', 'Inductance', '1.5e-3', 'Capacitance', 'inf');
        set_param([model '/RLC_B'], 'Resistance', '0.81', 'Inductance', '1.5e-3', 'Capacitance', 'inf');
        set_param([model '/RLC_C'], 'Resistance', '0.81', 'Inductance', '1.5e-3', 'Capacitance', 'inf');
    end
    
    % EMF Sources
    if getSimulinkBlockHandle([model '/EMF_A']) == -1
        add_block('powerlib/Electrical Sources/Controlled Voltage Source', [model '/EMF_A'], 'Position', [700, 150, 730, 180]);
        add_block('powerlib/Electrical Sources/Controlled Voltage Source', [model '/EMF_B'], 'Position', [700, 200, 730, 230]);
        add_block('powerlib/Electrical Sources/Controlled Voltage Source', [model '/EMF_C'], 'Position', [700, 250, 730, 280]);
    end
    
    % Current Sensors
    if getSimulinkBlockHandle([model '/I_A']) == -1
        add_block('powerlib/Measurements/Current Measurement', [model '/I_A'], 'Position', [500, 150, 530, 180]);
        add_block('powerlib/Measurements/Current Measurement', [model '/I_B'], 'Position', [500, 200, 530, 230]);
        add_block('powerlib/Measurements/Current Measurement', [model '/I_C'], 'Position', [500, 250, 530, 280]);
    end
    
    % Motor Physics
    if getSimulinkBlockHandle([model '/Motor_Physics']) == -1
        add_block('simulink/User-Defined Functions/MATLAB Function', [model '/Motor_Physics'], 'Position', [800, 180, 950, 260]);
    end
    
    % GET HANDLES
    p_inv = get_param([model '/Inverter'], 'PortHandles');
    p_cap = get_param([model '/DC_Bus_Cap'], 'PortHandles');
    p_bat = get_param([model '/Battery'], 'PortHandles');
    p_ind = get_param([model '/Inductor_L2'], 'PortHandles');
    
    p_ia = get_param([model '/I_A'], 'PortHandles');
    p_ib = get_param([model '/I_B'], 'PortHandles');
    p_ic = get_param([model '/I_C'], 'PortHandles');
    
    p_ra = get_param([model '/RLC_A'], 'PortHandles');
    p_rb = get_param([model '/RLC_B'], 'PortHandles');
    p_rc = get_param([model '/RLC_C'], 'PortHandles');
    
    p_ea = get_param([model '/EMF_A'], 'PortHandles');
    p_eb = get_param([model '/EMF_B'], 'PortHandles');
    p_ec = get_param([model '/EMF_C'], 'PortHandles');
    
    % REWIRE DC BUS
    add_line(model, p_inv.RConn(1), p_cap.LConn(1));
    add_line(model, p_inv.RConn(2), p_cap.RConn(1));
    add_line(model, p_bat.RConn(1), p_inv.RConn(2));
    add_line(model, p_bat.LConn(1), p_ind.LConn(1));
    
    % REWIRE AC SIDE
    add_line(model, p_inv.LConn(1), p_ia.LConn(1));
    add_line(model, p_inv.LConn(2), p_ib.LConn(1));
    add_line(model, p_inv.LConn(3), p_ic.LConn(1));
    
    add_line(model, p_ia.RConn(1), p_ra.LConn(1));
    add_line(model, p_ib.RConn(1), p_rb.LConn(1));
    add_line(model, p_ic.RConn(1), p_rc.LConn(1));
    
    add_line(model, p_ra.RConn(1), p_ea.LConn(1));
    add_line(model, p_rb.RConn(1), p_eb.LConn(1));
    add_line(model, p_rc.RConn(1), p_ec.LConn(1));
    
    % WYE CONNECTION
    add_line(model, p_ea.RConn(1), p_eb.RConn(1));
    add_line(model, p_eb.RConn(1), p_ec.RConn(1));
    
    % NEUTRAL TO L2
    add_line(model, p_ec.RConn(1), p_ind.RConn(1));
    
    save_system(model);
    disp('Successfully built the custom Wye-connected motor!');
catch e
    disp('Error occurred:');
    disp(e.message);
end
exit;
