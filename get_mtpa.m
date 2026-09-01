try
    model = 'ETS_Model';
    load_system(model);
    config = get_param([model '/Control_System/EFOC_Controller/MTPA'], 'Script');
    disp('--- MTPA Code ---');
    disp(config);
catch e
    disp(e.message);
end
exit;
