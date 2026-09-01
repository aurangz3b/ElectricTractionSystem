try
    model = 'ETS_Model';
    load_system(model);
    config = get_param([model '/PMSM_Motor/Motor_Physics'], 'Script');
    disp('--- Motor Physics Code ---');
    disp(config);
catch e
    disp(e.message);
end
exit;
