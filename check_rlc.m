try
    model = 'ETS_Model';
    load_system(model);
    ports = get_param([model '/Battery'], 'Ports');
    % Usually for physical blocks, it's just 0 in 0 out. The connection ports are LConn and RConn.
    % Let's measure the voltage across the battery!
    
    % Wait, better yet, what if the EMF blocks are blocking current?
    % The Controlled Voltage Source blocks (EMF_A, EMF_B, EMF_C) are ideal voltage sources!
    % If their control signal (from Motor_Physics) is exactly ZERO, they act as SHORT CIRCUITS (0V).
    % This is correct!
    
    % Let's check RLC_A!
    c_val = get_param([model '/PMSM_Motor/RLC_A'], 'Capacitance');
    fprintf('RLC_A C = %s\n', c_val);
catch e
    disp(e.message);
end
exit;
