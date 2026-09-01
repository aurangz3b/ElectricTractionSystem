try
    model = 'ETS_Model';
    load_system(model);
    efoc = [model '/Control_System/EFOC_Controller'];
    inports = find_system(efoc, 'SearchDepth', 1, 'BlockType', 'Inport');
    
    % Get their port numbers
    for i=1:length(inports)
        port_num = get_param(inports{i}, 'Port');
        fprintf('EFOC_Controller Port %s is: %s\n', port_num, get_param(inports{i}, 'Name'));
    end
catch e
    disp(e.message);
end
exit;
