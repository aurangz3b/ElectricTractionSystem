try
    model = 'ETS_Model';
    load_system(model);
    ctrl = [model '/Control_System/EFOC_Controller'];
    
    muxes = {'Mux_InvPark', 'Mux_Park', 'Mux_we_iq', 'Mux_we_id', 'Mux_DutyA', 'Mux_DutyB', 'Mux_DutyC', 'Mux_Duty_Out'};
    
    for i=1:length(muxes)
        mux_name = muxes{i};
        mux_path = [ctrl '/' mux_name];
        if getSimulinkBlockHandle(mux_path) ~= -1
            % Get inputs count
            n_inputs = get_param(mux_path, 'Inputs');
            
            % Get connected lines
            ph = get_param(mux_path, 'PortHandles');
            in_lines = get_param(ph.Inport, 'Line');
            out_line = get_param(ph.Outport, 'Line');
            
            % Save src ports
            src_ports = zeros(1, length(ph.Inport));
            for j=1:length(ph.Inport)
                if in_lines{j} ~= -1
                    src_ports(j) = get_param(in_lines{j}, 'SrcPortHandle');
                else
                    src_ports(j) = -1;
                end
            end
            
            % Save dst ports
            dst_ports = [];
            if out_line ~= -1
                dst_ports = get_param(out_line, 'DstPortHandle');
            end
            
            % Delete old mux
            pos = get_param(mux_path, 'Position');
            delete_block(mux_path);
            
            % Add Vector Concatenate
            add_block('simulink/Math Operations/Matrix Concatenate', mux_path, 'Position', pos);
            set_param(mux_path, 'NumInputs', n_inputs, 'Mode', 'Vector');
            
            % Reconnect
            for j=1:length(src_ports)
                if src_ports(j) ~= -1
                    add_line(ctrl, src_ports(j), get_param(mux_path, 'PortHandles').Inport(j), 'autorouting', 'on');
                end
            end
            
            for j=1:length(dst_ports)
                if dst_ports(j) ~= -1
                    add_line(ctrl, get_param(mux_path, 'PortHandles').Outport(1), dst_ports(j), 'autorouting', 'on');
                end
            end
        end
    end
    
    save_system(model);
    disp('Mux blocks replaced with Vector Concatenate.');
catch e
    disp(e.message);
end
exit;
