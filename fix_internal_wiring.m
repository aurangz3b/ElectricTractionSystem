try
    model = 'ETS_Model';
    load_system(model);
    ctrl = [model '/Control_System/EFOC_Controller'];
    
    % Let's reconnect Mux_InvPark
    % 1. Clean existing disconnected lines if any
    lines = find_system(ctrl, 'FindAll', 'on', 'Type', 'line');
    for i=1:length(lines)
        src = get_param(lines(i), 'SrcPortHandle');
        dst = get_param(lines(i), 'DstPortHandle');
        if src == -1 || isempty(dst) || any(dst == -1)
            delete_line(lines(i));
        end
    end
    
    % Reconnect
    try add_line(ctrl, 'Sum_ud/1', 'Mux_InvPark/1', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Sum_uq/1', 'Mux_InvPark/2', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'theta_e/1', 'Mux_InvPark/3', 'autorouting', 'on'); catch; end
    
    try add_line(ctrl, 'Mux_InvPark/1', 'InvPark_a/1', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Mux_InvPark/1', 'InvPark_b/1', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Mux_InvPark/1', 'InvPark_c/1', 'autorouting', 'on'); catch; end
    
    % ALSO Mux_Park might be disconnected?
    try add_line(ctrl, 'Demux_abc/1', 'Mux_Park/1', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Demux_abc/2', 'Mux_Park/2', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Demux_abc/3', 'Mux_Park/3', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'theta_e/1', 'Mux_Park/4', 'autorouting', 'on'); catch; end
    
    try add_line(ctrl, 'Mux_Park/1', 'Park_d/1', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Mux_Park/1', 'Park_q/1', 'autorouting', 'on'); catch; end
    
    save_system(model);
    disp('Internal Muxes rewired.');
catch e
    disp(e.message);
end
exit;
