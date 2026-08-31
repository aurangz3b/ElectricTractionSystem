try
    model = 'ETS_Model';
    load_system(model);
    efoc = [model '/Control_System/EFOC_Controller'];
    
    set_param([efoc '/i_abc'], 'PortDimensions', '3');
    
    save_system(model);
    disp('Forced i_abc dimension to 3.');
catch e
    disp(e.message);
end
exit;
