try
    model = 'ETS_Model';
    load_system(model);
    
    % Use find_system to find the blocks safely
    
    % 1. Find Motor Physics and get its parent
    mp = find_system(model, 'Name', 'Motor_Physics');
    if ~isempty(mp)
        parent = get_param(mp{1}, 'Parent');
        if ~strcmp(parent, model)
            set_param(parent, 'Name', 'PMSM_Motor');
            disp('Renamed motor subsystem to PMSM_Motor.');
        end
    end
    
    % 2. Find EFOC Controller and get its parent
    ec = find_system(model, 'Name', 'EFOC_Controller');
    if ~isempty(ec)
        parent = get_param(ec{1}, 'Parent');
        if ~strcmp(parent, model)
            set_param(parent, 'Name', 'Control_System');
            disp('Renamed controller subsystem to Control_System.');
        end
    end
    
    % Cleanup unused blocks? The createSubsystem puts a Subsystem block.
    
    % We might need to manually call createSubsystem if it failed midway.
    % If Motor_Physics is still at top level:
    mp = find_system(model, 'SearchDepth', 1, 'Name', 'Motor_Physics');
    if ~isempty(mp)
        motor_blocks = {'RLC_A','RLC_B','RLC_C','EMF_A','EMF_B','EMF_C','I_A','I_B','I_C','Motor_Physics','Delay_A','Delay_B','Delay_C'};
        h = [];
        for i=1:length(motor_blocks)
            bh = getSimulinkBlockHandle([model '/' motor_blocks{i}]);
            if bh ~= -1, h(end+1) = bh; end
        end
        Simulink.BlockDiagram.createSubsystem(h);
        mp_new = find_system(model, 'Name', 'Motor_Physics');
        set_param(get_param(mp_new{1}, 'Parent'), 'Name', 'PMSM_Motor');
    end
    
    ec = find_system(model, 'SearchDepth', 1, 'Name', 'EFOC_Controller');
    if ~isempty(ec)
        ctrl_blocks = {'EFOC_Controller','PWM_Compare','Carrier','Data_Type_Conv','Logical_NOT','Data_Type_Conv_NOT','Demux_UP','Demux_DOWN','Mux_PWM','Mux_I'};
        h = [];
        for i=1:length(ctrl_blocks)
            bh = getSimulinkBlockHandle([model '/' ctrl_blocks{i}]);
            if bh ~= -1, h(end+1) = bh; end
        end
        Simulink.BlockDiagram.createSubsystem(h);
        ec_new = find_system(model, 'Name', 'EFOC_Controller');
        set_param(get_param(ec_new{1}, 'Parent'), 'Name', 'Control_System');
    end
    
    save_system(model);
    disp('Subsystems organized.');
catch e
    disp(e.message);
end
exit;
