try
    model = 'ETS_Model';
    load_system(model);
    ph = get_param([model '/Control_System'], 'PortHandles');
    
    for i=1:length(ph.Inport)
        l = get_param(ph.Inport(i), 'Line');
        if l ~= -1
            src = get_param(l, 'SrcBlockHandle');
            fprintf('Control_System Inport %d connected to: %s\n', i, get_param(src, 'Name'));
        else
            fprintf('Control_System Inport %d is DISCONNECTED\n', i);
        end
    end
catch e
    disp(e.message);
end
exit;
