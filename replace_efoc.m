try
    model = 'ETS_Model';
    load_system(model);
    ctrl = [model '/Control_System'];
    
    % Find lines connected to EFOC_Controller
    old_efoc = [ctrl '/EFOC_Controller'];
    new_efoc = [ctrl '/EFOC_Subsystem'];
    
    if getSimulinkBlockHandle(old_efoc) ~= -1
        ph_old = get_param(old_efoc, 'PortHandles');
        ph_new = get_param(new_efoc, 'PortHandles');
        
        % Transfer input lines
        lines = get_param(old_efoc, 'LineHandles');
        for i = 1:length(lines.Inport)
            line = lines.Inport(i);
            if line ~= -1
                src_port = get_param(line, 'SrcPortHandle');
                delete_line(line);
                add_line(ctrl, src_port, ph_new.Inport(i), 'autorouting', 'on');
            end
        end
        
        % Transfer output lines
        for i = 1:length(lines.Outport)
            line = lines.Outport(i);
            if line ~= -1
                dst_ports = get_param(line, 'DstPortHandle');
                delete_line(line);
                for j = 1:length(dst_ports)
                    add_line(ctrl, ph_new.Outport(i), dst_ports(j), 'autorouting', 'on');
                end
            end
        end
        
        % Delete old block
        delete_block(old_efoc);
        
        % Rename new block to EFOC_Controller
        set_param(new_efoc, 'Name', 'EFOC_Controller');
        
        save_system(model);
        disp('Successfully replaced MATLAB function with standard block diagram!');
    else
        disp('EFOC_Controller already replaced.');
    end
catch e
    disp(e.message);
end
exit;
