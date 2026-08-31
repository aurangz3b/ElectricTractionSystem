try
    model = 'ETS_Model';
    load_system(model);
    pmsm = [model '/PMSM_Motor'];
    p_ea = get_param([pmsm '/EMF_A'], 'PortHandles');
    p_eb = get_param([pmsm '/EMF_B'], 'PortHandles');
    p_ec = get_param([pmsm '/EMF_C'], 'PortHandles');
    p_ind = get_param([model '/Inductor_L2'], 'PortHandles');
    
    l_ea = get_param(p_ea.RConn(1), 'Line');
    l_eb = get_param(p_eb.RConn(1), 'Line');
    l_ec = get_param(p_ec.RConn(1), 'Line');
    l_ind = get_param(p_ind.RConn(1), 'Line');
    
    fprintf('EMF_A RConn line handle: %d\n', l_ea);
    fprintf('EMF_B RConn line handle: %d\n', l_eb);
    fprintf('EMF_C RConn line handle: %d\n', l_ec);
    fprintf('Inductor RConn line handle: %d\n', l_ind);
    
    % Check if line handles match
    if l_ea ~= -1 && l_ea == l_eb
        disp('A and B are connected');
    end
    if l_eb ~= -1 && l_eb == l_ec
        disp('B and C are connected');
    end
catch e
    disp(e.message);
end
exit;
