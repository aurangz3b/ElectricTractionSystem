try
    model = 'ETS_Model';
    load_system(model);
    ph = get_param([model '/V_DC'], 'PortHandles');
    disp(ph);
    
    % Let's also find all Voltage Measurements!
    vms = find_system(model, 'MaskType', 'Voltage Measurement');
    for i=1:length(vms)
        fprintf('Found VM: %s\n', vms{i});
    end
catch e
    disp(e.message);
end
exit;
