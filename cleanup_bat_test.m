try
    model = 'ETS_Model';
    load_system(model);
    % Clean up my test blocks
    if getSimulinkBlockHandle([model '/V_Bat_Meas']) ~= -1
        delete_block([model '/V_Bat_Meas']);
    end
    if getSimulinkBlockHandle([model '/Bat_Volt_Out']) ~= -1
        delete_block([model '/Bat_Volt_Out']);
    end
    % Delete dangling lines
    lines = find_system(model, 'FindAll', 'on', 'Type', 'line', 'Connected', 'off');
    for i=1:length(lines)
        delete_line(lines(i));
    end
    save_system(model);
    disp('Cleaned up test blocks.');
catch e
    disp(e.message);
end
exit;
