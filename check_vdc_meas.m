try
    model = 'ETS_Model';
    load_system(model);
    ph = get_param([model '/V_DC_Meas'], 'PortHandles');
    l1 = get_param(ph.LConn(1), 'Line');
    l2 = get_param(ph.LConn(2), 'Line');
    
    if l1 ~= -1
        src1 = get_param(l1, 'SrcPortHandle');
        dst1 = get_param(l1, 'DstPortHandle');
        fprintf('V_DC_Meas LConn 1 connected.\n');
    end
    if l2 ~= -1
        fprintf('V_DC_Meas LConn 2 connected.\n');
    end
catch e
    disp(e.message);
end
exit;
