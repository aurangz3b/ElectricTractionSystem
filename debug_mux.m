try
    model = 'ETS_Model';
    load_system(model);
    ctrl = [model '/Control_System/EFOC_Controller'];
    
    % Check lines connected to Mux_InvPark
    ph = get_param([ctrl '/Mux_InvPark'], 'PortHandles');
    in_lines = get_param(ph.Inport, 'Line');
    out_lines = get_param(ph.Outport, 'Line');
    
    for i=1:length(in_lines)
        if in_lines{i} == -1
            fprintf('Mux_InvPark Inport %d is DISCONNECTED!\n', i);
        else
            fprintf('Mux_InvPark Inport %d is connected.\n', i);
        end
    end
    
    if out_lines == -1
        fprintf('Mux_InvPark Outport is DISCONNECTED!\n');
    end
    
    ph_inv_a = get_param([ctrl '/InvPark_a'], 'PortHandles');
    if get_param(ph_inv_a.Inport(1), 'Line') == -1
        fprintf('InvPark_a Inport is DISCONNECTED!\n');
    else
        fprintf('InvPark_a is connected.\n');
    end
    
catch e
    disp(e.message);
end
exit;
