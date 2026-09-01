try
    model = 'ETS_Model';
    load_system(model);
    % Since PI_Speed is a masked subsystem, get all its dialog parameters
    pi = [model '/Control_System/EFOC_Controller/PI_Speed'];
    lim = get_param(pi, 'LimitOutput');
    upper = get_param(pi, 'UpperSaturationLimit');
    lower = get_param(pi, 'LowerSaturationLimit');
    
    fprintf('LimitOutput: %s\n', lim);
    fprintf('Upper: %s\n', upper);
    fprintf('Lower: %s\n', lower);
catch e
    disp(e.message);
end
exit;
