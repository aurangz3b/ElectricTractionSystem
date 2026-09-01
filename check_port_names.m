try
    model = 'ETS_Model';
    load_system(model);
    inports = find_system([model '/Control_System'], 'SearchDepth', 1, 'BlockType', 'Inport');
    for i=1:length(inports)
        fprintf('Port %d: %s\n', i, get_param(inports{i}, 'Name'));
    end
catch e
    disp(e.message);
end
exit;
