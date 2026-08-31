try
    load_system('ETS_Model');
    blocks = find_system('ETS_Model');
    disp(blocks);
    
    p = get_param('ETS_Model/PMSM', 'DialogParameters');
    if isempty(p)
        disp('No dialog params for PMSM');
    else
        fields = fieldnames(p);
        for i=1:length(fields)
            disp(fields{i});
        end
    end
catch e
    disp(e.message);
end
exit;
