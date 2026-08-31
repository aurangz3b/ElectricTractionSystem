try
    model = 'ETS_Model';
    load_system(model);
    vm = find_system(model, 'BlockType', 'Reference', 'MaskType', 'Voltage Measurement');
    for i=1:length(vm)
        fprintf('Voltage Meas: %s\n', get_param(vm{i}, 'Name'));
    end
catch e
    disp(e.message);
end
exit;
