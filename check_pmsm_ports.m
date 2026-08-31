try
    model = 'ETS_Model';
    load_system(model);
    ph = get_param([model '/PMSM_Motor'], 'PortHandles');
    disp('PMSM_Motor PortHandles:');
    disp(ph);
catch e
    disp(e.message);
end
exit;
