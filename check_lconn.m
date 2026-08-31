try
    model = 'ETS_Model';
    load_system(model);
    ph = get_param([model '/PMSM_Motor'], 'PortHandles');
    
    for i=1:length(ph.LConn)
        line = get_param(ph.LConn(i), 'Line');
        if line ~= -1
            dst = get_param(line, 'DstBlockHandle');
            if dst ~= -1
                fprintf('LConn(%d) connected to: %s\n', i, get_param(dst, 'Name'));
            else
                fprintf('LConn(%d) connected to something without DstBlockHandle\n', i);
            end
        else
            fprintf('LConn(%d) is DISCONNECTED\n', i);
        end
    end
catch e
    disp(e.message);
end
exit;
