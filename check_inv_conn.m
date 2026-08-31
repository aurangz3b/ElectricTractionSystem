try
    model = 'ETS_Model';
    load_system(model);
    ph = get_param([model '/Control_System'], 'PortHandles');
    lines = get_param(ph.Outport(1), 'Line');
    if lines ~= -1
        dst = get_param(lines, 'DstBlockHandle');
        fprintf('Control_System Out1 goes to: %s\n', get_param(dst, 'Name'));
    else
        disp('Control_System Out1 is NOT connected!');
    end
catch e
    disp(e.message);
end
exit;
