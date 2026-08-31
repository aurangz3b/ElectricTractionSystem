try
    model = 'ETS_Model';
    if bdIsLoaded(model)
        close_system(model, 0);
    end
    new_system(model);
    open_system(model);
    
    % Add Powergui
    add_block('powerlib/powergui', [model '/powergui'], 'Position', [30, 30, 100, 60]);
    
    % Add PMSM
    add_block('powerlib/Machines/Permanent Magnet Synchronous Machine', [model '/PMSM'], 'Position', [500, 200, 600, 300]);
    
    % Add Universal Bridge
    add_block('powerlib/Power Electronics/Universal Bridge', [model '/Inverter'], 'Position', [300, 200, 400, 300]);
    
    % Add Battery
    add_block('powerlib/Electrical Sources/DC Voltage Source', [model '/Battery'], 'Position', [100, 400, 120, 450]);
    
    % Add Inductor L2
    add_block('powerlib/Elements/Series RLC Branch', [model '/Inductor_L2'], 'Position', [300, 400, 350, 430]);
    
    % Add Capacitor
    add_block('powerlib/Elements/Series RLC Branch', [model '/DC_Bus_Cap'], 'Position', [200, 200, 220, 280]);
    
    % Add MATLAB Function
    add_block('simulink/User-Defined Functions/MATLAB Function', [model '/EFOC_Controller'], 'Position', [100, 100, 200, 150]);
    
    save_system(model, 'ETS_Model.slx');
    disp('Successfully generated ETS_Model.slx');
catch e
    disp('Error occurred:');
    disp(e.message);
end
exit;
