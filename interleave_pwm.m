try
    model = 'ETS_Model';
    load_system(model);
    sys = [model '/Control_System'];
    
    % Delete existing ones to avoid conflicts
    blocks_to_delete = {'/Demux_UP', '/Demux_DOWN', '/Mux_PWM'};
    for i=1:length(blocks_to_delete)
        path = [sys blocks_to_delete{i}];
        if getSimulinkBlockHandle(path) ~= -1
            lh = get_param(path, 'LineHandles');
            for j=1:length(lh.Inport)
                if lh.Inport(j) ~= -1, delete_line(lh.Inport(j)); end
            end
            for j=1:length(lh.Outport)
                if lh.Outport(j) ~= -1, delete_line(lh.Outport(j)); end
            end
            delete_block(path);
        end
    end
    
    pos = get_param([sys '/Logical_NOT'], 'Position');
    pos_x = pos(3) + 50;
    pos_y = pos(2);
    
    % Create new
    add_block('simulink/Signal Routing/Mux', [sys '/Mux_PWM'], 'Position', [pos_x+100 pos_y-50 pos_x+105 pos_y+100]);
    set_param([sys '/Mux_PWM'], 'Inputs', '6');
    
    add_block('simulink/Signal Routing/Demux', [sys '/Demux_UP'], 'Position', [pos_x pos_y-50 pos_x+5 pos_y]);
    set_param([sys '/Demux_UP'], 'Outputs', '3');
    
    add_block('simulink/Signal Routing/Demux', [sys '/Demux_DOWN'], 'Position', [pos_x pos_y+50 pos_x+5 pos_y+100]);
    set_param([sys '/Demux_DOWN'], 'Outputs', '3');
    
    % Wire sources to demuxes
    add_line(sys, 'PWM_Compare/1', 'Demux_UP/1', 'autorouting', 'on');
    add_line(sys, 'Logical_NOT/1', 'Demux_DOWN/1', 'autorouting', 'on');
    
    % Wire Demuxes to Mux_PWM interleaved
    add_line(sys, 'Demux_UP/1', 'Mux_PWM/1', 'autorouting', 'on');   % A_up
    add_line(sys, 'Demux_DOWN/1', 'Mux_PWM/2', 'autorouting', 'on'); % A_low
    add_line(sys, 'Demux_UP/2', 'Mux_PWM/3', 'autorouting', 'on');   % B_up
    add_line(sys, 'Demux_DOWN/2', 'Mux_PWM/4', 'autorouting', 'on'); % B_low
    add_line(sys, 'Demux_UP/3', 'Mux_PWM/5', 'autorouting', 'on');   % C_up
    add_line(sys, 'Demux_DOWN/3', 'Mux_PWM/6', 'autorouting', 'on'); % C_low
    
    % Wire to output
    add_line(sys, 'Mux_PWM/1', 'Out1/1', 'autorouting', 'on');
    
    Simulink.BlockDiagram.arrangeSystem(sys);
    save_system(model);
    disp('Successfully interleaved PWM signals for Universal Bridge!');
catch e
    disp(e.message);
end
exit;
