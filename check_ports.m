try
    load_system('ETS_Model');
    ph = get_param('ETS_Model/PMSM', 'PortHandles');
    disp('PMSM Ports:');
    disp(ph);
    
    ph = get_param('ETS_Model/Inverter', 'PortHandles');
    disp('Inverter Ports:');
    disp(ph);
    
catch e
    disp(e.message);
end
exit;
