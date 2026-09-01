try
    model = 'ETS_Model';
    load_system(model);
    % Let's see what PWM_Compare does
    cb = [model '/Control_System/PWM_Compare'];
    op = get_param(cb, 'Operator');
    fprintf('PWM_Compare Operator: %s\n', op);
    
    % Check the triangle wave
    tri = [model '/Control_System/Carrier_Triangle'];
    if getSimulinkBlockHandle(tri) ~= -1
        t_freq = get_param(tri, 'Frequency');
        t_min = get_param(tri, 'Minimum');
        t_max = get_param(tri, 'Maximum');
        fprintf('Triangle Freq: %s, Min: %s, Max: %s\n', t_freq, t_min, t_max);
    else
        fprintf('No Carrier_Triangle block found.\n');
    end
catch e
    disp(e.message);
end
exit;
