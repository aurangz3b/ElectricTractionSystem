try
    model = 'ETS_Model';
    load_system(model);
    
    if getSimulinkBlockHandle([model '/Results_Scope']) ~= -1
        delete_block([model '/Results_Scope']);
    end
    
    add_block('simulink/Sinks/Scope', [model '/Results_Scope'], 'Position', [1050, 100, 1100, 180]);
    set_param([model '/Results_Scope'], 'NumInputPorts', '3');
    
    % Connect signals
    add_line(model, 'V_DC/1', 'Results_Scope/1');
    add_line(model, 'I_N/1', 'Results_Scope/2');
    add_line(model, 'Motor_Physics/4', 'Results_Scope/3'); % omega_m
    
    save_system(model);
    disp('Scope added successfully.');
catch e
    disp(e.message);
end
exit;
