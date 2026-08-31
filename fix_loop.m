try
    model = 'ETS_Model';
    load_system(model);
    
    % Find the lines connecting Motor_Physics outputs 1,2,3 to EMF_A, EMF_B, EMF_C
    lines = find_system(model, 'FindAll', 'on', 'Type', 'line');
    
    for i=1:length(lines)
        src_port = get_param(lines(i), 'SrcPortHandle');
        if src_port ~= -1
            src_block = get_param(src_port, 'Parent');
            port_num = get_param(src_port, 'PortNumber');
            if strcmp(src_block, [model '/Motor_Physics']) && (port_num == 1 || port_num == 2 || port_num == 3)
                delete_line(lines(i));
            end
        end
    end
    
    % Add Unit Delay blocks
    if getSimulinkBlockHandle([model '/Delay_A']) == -1
        add_block('simulink/Discrete/Unit Delay', [model '/Delay_A'], 'Position', [980, 175, 1010, 195]);
    end
    if getSimulinkBlockHandle([model '/Delay_B']) == -1
        add_block('simulink/Discrete/Unit Delay', [model '/Delay_B'], 'Position', [980, 205, 1010, 225]);
    end
    if getSimulinkBlockHandle([model '/Delay_C']) == -1
        add_block('simulink/Discrete/Unit Delay', [model '/Delay_C'], 'Position', [980, 235, 1010, 255]);
    end
    
    % Set Sample time
    set_param([model '/Delay_A'], 'SampleTime', '1e-5');
    set_param([model '/Delay_B'], 'SampleTime', '1e-5');
    set_param([model '/Delay_C'], 'SampleTime', '1e-5');
    
    % Connect Motor_Physics to Delays
    add_line(model, 'Motor_Physics/1', 'Delay_A/1');
    add_line(model, 'Motor_Physics/2', 'Delay_B/1');
    add_line(model, 'Motor_Physics/3', 'Delay_C/1');
    
    % Connect Delays to EMFs
    add_line(model, 'Delay_A/1', 'EMF_A/1');
    add_line(model, 'Delay_B/1', 'EMF_B/1');
    add_line(model, 'Delay_C/1', 'EMF_C/1');
    
    save_system(model);
    disp('Successfully inserted Unit Delay blocks to break the algebraic loop!');
catch e
    disp(e.message);
end
exit;
