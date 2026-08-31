try
    model = 'ETS_Model';
    load_system(model);
    pmsm = [model '/PMSM_Motor'];
    
    p_ea = get_param([pmsm '/EMF_A'], 'PortHandles');
    p_eb = get_param([pmsm '/EMF_B'], 'PortHandles');
    p_ec = get_param([pmsm '/EMF_C'], 'PortHandles');
    
    % Let's connect them together properly using a Junction or just carefully drawn lines
    % First, clear any existing lines on RConn of EMF_A and EMF_B
    l_ea = get_param(p_ea.RConn(1), 'Line');
    if l_ea ~= -1, delete_line(l_ea); end
    
    l_eb = get_param(p_eb.RConn(1), 'Line');
    if l_eb ~= -1, delete_line(l_eb); end
    
    % EMF_C RConn is connected to the Subsystem's Connection Port. We leave that alone!
    % We just need to connect EMF_A and EMF_B to EMF_C's RConn.
    
    % In Simscape, you can connect multiple things to a single port if you do it via a line branch.
    % Alternatively, add them to the SAME port.
    add_line(pmsm, p_ea.RConn(1), p_ec.RConn(1));
    add_line(pmsm, p_eb.RConn(1), p_ec.RConn(1));
    
    save_system(model);
    disp('Successfully re-welded the Wye connection inside PMSM_Motor!');
catch e
    disp(e.message);
end
exit;
