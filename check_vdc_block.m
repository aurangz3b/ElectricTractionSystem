try
    model = 'ETS_Model';
    load_system(model);
    % V_DC is the name of the block.
    b = [model '/V_DC'];
    type = get_param(b, 'BlockType');
    fprintf('Block V_DC type: %s\n', type);
catch e
    disp(e.message);
end
exit;
