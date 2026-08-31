try
    model = 'ETS_Model';
    load_system(model);
    ph = get_param([model '/Results_Scope'], 'PortHandles');
    lines = get_param(ph.Inport, 'Line');
    if iscell(lines)
        for i=1:length(lines)
            l = lines{i};
            if l ~= -1
                src = get_param(l, 'SrcBlockHandle');
                fprintf('Results_Scope Inport %d comes from: %s\n', i, get_param(src, 'Name'));
            end
        end
    end
catch e
    disp(e.message);
end
exit;
