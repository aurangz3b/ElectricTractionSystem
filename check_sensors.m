try
    model = 'ETS_Model';
    load_system(model);
    ph_vdc = get_param([model '/V_DC'], 'PortHandles');
    ph_in = get_param([model '/I_N'], 'PortHandles');
    
    l_vdc1 = get_param(ph_vdc.LConn(1), 'Line');
    l_vdc2 = get_param(ph_vdc.LConn(2), 'Line');
    l_in1 = get_param(ph_in.LConn(1), 'Line');
    l_in2 = get_param(ph_in.RConn(1), 'Line');
    
    fprintf('VDC1 line: %d\n', l_vdc1);
    fprintf('VDC2 line: %d\n', l_vdc2);
    fprintf('IN1 line: %d\n', l_in1);
    fprintf('IN2 line: %d\n', l_in2);
catch e
    disp(e.message);
end
exit;
