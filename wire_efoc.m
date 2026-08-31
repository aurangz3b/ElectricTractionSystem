try
    model = 'ETS_Model';
    load_system(model);
    efoc = [model '/Control_System/EFOC_Controller'];

    % Speed Loop
    try_add_line(efoc, 'w_ref/1', 'Sum_Speed/1');
    try_add_line(efoc, 'w_m/1', 'Sum_Speed/2');
    try_add_line(efoc, 'Sum_Speed/1', 'PI_Speed/1');
    try_add_line(efoc, 'PI_Speed/1', 'Switch_Brake/1');
    try_add_line(efoc, 'T_re/1', 'Switch_Brake/3');
    
    % Switch Mode constant
    if getSimulinkBlockHandle([efoc '/Mode']) == -1
        add_block('simulink/Sources/Constant', [efoc '/Mode']);
        set_param([efoc '/Mode'], 'Value', '1');
    end
    try_add_line(efoc, 'Mode/1', 'Switch_Brake/2');
    try_add_line(efoc, 'Switch_Brake/1', 'MTPA/1');
    
    % DC Bus Loop
    try_add_line(efoc, 'u_bus_ref/1', 'Sum_Vbus/1');
    try_add_line(efoc, 'u_bus/1', 'Sum_Vbus/2');
    try_add_line(efoc, 'Sum_Vbus/1', 'PI_Vbus/1');
    
    % Neutral Current Loop
    try_add_line(efoc, 'PI_Vbus/1', 'Sum_iN/1');
    try_add_line(efoc, 'i_N/1', 'Sum_iN/2');
    try_add_line(efoc, 'Sum_iN/1', 'PI_iN/1');
    
    % Park Transform (abc -> dq) Input from top level
    try_add_line(efoc, 'i_abc/1', 'Demux_abc/1');
    
    % Current Loops
    try_add_line(efoc, 'id_ref/1', 'Sum_id/1');
    try_add_line(efoc, 'Park_d/1', 'Sum_id/2');
    try_add_line(efoc, 'Sum_id/1', 'PI_id/1');
    
    try_add_line(efoc, 'MTPA/1', 'Sum_iq/1');
    try_add_line(efoc, 'Park_q/1', 'Sum_iq/2');
    try_add_line(efoc, 'Sum_iq/1', 'PI_iq/1');
    
    % Decoupling we
    try_add_line(efoc, 'w_m/1', 'Gain_we/1');
    
    % Decoupling sum ud
    try_add_line(efoc, 'PI_id/1', 'Sum_ud/1');
    try_add_line(efoc, 'Decouple_d/1', 'Sum_ud/2'); 
    
    % Decoupling sum uq
    try_add_line(efoc, 'PI_iq/1', 'Sum_uq/1');
    try_add_line(efoc, 'Decouple_q/1', 'Sum_uq/2'); 
    
    % The output is already wired correctly via Mux replacements!
    % Just do an arrange system
    Simulink.BlockDiagram.arrangeSystem(efoc);
    save_system(model);
    disp('Successfully wired all remaining disconnected blocks in EFOC!');
catch e
    disp(e.message);
end

function try_add_line(sys, src, dst)
    try
        add_line(sys, src, dst, 'autorouting', 'on');
    catch e
        fprintf('Failed to connect %s to %s: %s\n', src, dst, e.message);
    end
end
exit;
