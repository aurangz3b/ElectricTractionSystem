try
    model = 'ETS_Model';
    load_system(model);
    
    efoc = [model '/Control_System/EFOC_Subsystem'];
    if getSimulinkBlockHandle(efoc) ~= -1
        delete_block(efoc);
    end
    add_block('built-in/SubSystem', efoc, 'Position', [100, 100, 300, 300]);
    
    % Add Inports
    ports = {'w_m', 'w_ref', 'T_re', 'u_bus', 'u_bus_ref', 'i_N', 'i_abc', 'theta_e'};
    for i=1:length(ports)
        add_block('simulink/Sources/In1', [efoc '/' ports{i}]);
    end
    add_block('simulink/Sinks/Out1', [efoc '/Duty_abc']);
    
    % Speed Loop
    add_block('simulink/Math Operations/Subtract', [efoc '/Sum_Speed']);
    set_param([efoc '/Sum_Speed'], 'Inputs', '+-');
    add_block('built-in/SubSystem', [efoc '/PI_Speed']);
    create_pi(efoc, 'PI_Speed', 0.1, 2.0, 15, -15);
    
    add_block('simulink/Signal Routing/Manual Switch', [efoc '/Switch_Brake']);
    add_block('simulink/Math Operations/Gain', [efoc '/MTPA']);
    set_param([efoc '/MTPA'], 'Gain', '1/(1.5*4*0.1)');
    add_block('simulink/Sources/Constant', [efoc '/id_ref']);
    set_param([efoc '/id_ref'], 'Value', '0');
    
    % DC Bus Loop
    add_block('simulink/Math Operations/Subtract', [efoc '/Sum_Vbus']);
    set_param([efoc '/Sum_Vbus'], 'Inputs', '+-');
    add_block('built-in/SubSystem', [efoc '/PI_Vbus']);
    create_pi(efoc, 'PI_Vbus', 0.2, 5.0, 30, -30);
    
    % Neutral Current Loop
    add_block('simulink/Math Operations/Subtract', [efoc '/Sum_iN']);
    set_param([efoc '/Sum_iN'], 'Inputs', '+-');
    add_block('built-in/SubSystem', [efoc '/PI_iN']);
    create_pi(efoc, 'PI_iN', -0.016, -0.75, 0.9, 0.1);
    
    % Park Transform
    add_block('simulink/Signal Routing/Demux', [efoc '/Demux_abc']);
    set_param([efoc '/Demux_abc'], 'Outputs', '3');
    add_block('simulink/User-Defined Functions/Fcn', [efoc '/Park_d']);
    set_param([efoc '/Park_d'], 'Expr', '(2/3)*(u(1)*cos(u(4)) + u(2)*cos(u(4)-2*pi/3) + u(3)*cos(u(4)+2*pi/3))');
    add_block('simulink/User-Defined Functions/Fcn', [efoc '/Park_q']);
    set_param([efoc '/Park_q'], 'Expr', '-(2/3)*(u(1)*sin(u(4)) + u(2)*sin(u(4)-2*pi/3) + u(3)*sin(u(4)+2*pi/3))');
    add_block('simulink/Signal Routing/Mux', [efoc '/Mux_Park']);
    set_param([efoc '/Mux_Park'], 'Inputs', '4');
    
    % Current Loops
    add_block('simulink/Math Operations/Subtract', [efoc '/Sum_id']);
    add_block('simulink/Math Operations/Subtract', [efoc '/Sum_iq']);
    set_param([efoc '/Sum_id'], 'Inputs', '+-');
    set_param([efoc '/Sum_iq'], 'Inputs', '+-');
    
    add_block('built-in/SubSystem', [efoc '/PI_id']);
    create_pi(efoc, 'PI_id', 1.5, 810, 1000, -1000);
    add_block('built-in/SubSystem', [efoc '/PI_iq']);
    create_pi(efoc, 'PI_iq', 1.5, 810, 1000, -1000);
    
    % Decoupling
    add_block('simulink/Math Operations/Gain', [efoc '/Gain_we']);
    set_param([efoc '/Gain_we'], 'Gain', '4'); % p=4
    add_block('simulink/User-Defined Functions/Fcn', [efoc '/Decouple_d']);
    set_param([efoc '/Decouple_d'], 'Expr', 'u(1) * 1.5e-3 * u(2)'); % w_e * Lq * iq
    add_block('simulink/User-Defined Functions/Fcn', [efoc '/Decouple_q']);
    set_param([efoc '/Decouple_q'], 'Expr', 'u(1) * (1.5e-3 * u(2) + 0.1)'); % w_e * (Ld * id + psi_f)
    add_block('simulink/Signal Routing/Mux', [efoc '/Mux_we_iq']);
    add_block('simulink/Signal Routing/Mux', [efoc '/Mux_we_id']);
    
    add_block('simulink/Math Operations/Subtract', [efoc '/Sum_ud']);
    set_param([efoc '/Sum_ud'], 'Inputs', '+-');
    add_block('simulink/Math Operations/Add', [efoc '/Sum_uq']);
    
    % Inverse Park
    add_block('simulink/Signal Routing/Mux', [efoc '/Mux_InvPark']);
    set_param([efoc '/Mux_InvPark'], 'Inputs', '3');
    add_block('simulink/User-Defined Functions/Fcn', [efoc '/InvPark_a']);
    set_param([efoc '/InvPark_a'], 'Expr', 'u(1)*cos(u(3)) - u(2)*sin(u(3))');
    add_block('simulink/User-Defined Functions/Fcn', [efoc '/InvPark_b']);
    set_param([efoc '/InvPark_b'], 'Expr', 'u(1)*cos(u(3)-2*pi/3) - u(2)*sin(u(3)-2*pi/3)');
    add_block('simulink/User-Defined Functions/Fcn', [efoc '/InvPark_c']);
    set_param([efoc '/InvPark_c'], 'Expr', 'u(1)*cos(u(3)+2*pi/3) - u(2)*sin(u(3)+2*pi/3)');
    
    % Eq 15: Duty Cycle Calculation
    add_block('simulink/Signal Routing/Mux', [efoc '/Mux_DutyA']);
    add_block('simulink/Signal Routing/Mux', [efoc '/Mux_DutyB']);
    add_block('simulink/Signal Routing/Mux', [efoc '/Mux_DutyC']);
    add_block('simulink/User-Defined Functions/Fcn', [efoc '/Duty_A']);
    set_param([efoc '/Duty_A'], 'Expr', 'u(1) + u(2)/u(3)');
    add_block('simulink/User-Defined Functions/Fcn', [efoc '/Duty_B']);
    set_param([efoc '/Duty_B'], 'Expr', 'u(1) + u(2)/u(3)');
    add_block('simulink/User-Defined Functions/Fcn', [efoc '/Duty_C']);
    set_param([efoc '/Duty_C'], 'Expr', 'u(1) + u(2)/u(3)');
    
    add_block('simulink/Signal Routing/Mux', [efoc '/Mux_Duty_Out']);
    set_param([efoc '/Mux_Duty_Out'], 'Inputs', '3');
    add_block('simulink/Commonly Used Blocks/Saturation', [efoc '/Sat_Duty']);
    set_param([efoc '/Sat_Duty'], 'UpperLimit', '1', 'LowerLimit', '0');
    
    save_system(model);
    disp('Blocks created');
catch e
    disp(e.message);
end

function create_pi(efoc, name, Kp, Ki, sat_upper, sat_lower)
    subsys = [efoc '/' name];
    add_block('simulink/Sources/In1', [subsys '/In']);
    add_block('simulink/Sinks/Out1', [subsys '/Out']);
    add_block('simulink/Math Operations/Gain', [subsys '/Kp']);
    set_param([subsys '/Kp'], 'Gain', num2str(Kp));
    add_block('simulink/Math Operations/Gain', [subsys '/Ki']);
    set_param([subsys '/Ki'], 'Gain', num2str(Ki));
    add_block('simulink/Discrete/Discrete-Time Integrator', [subsys '/Int']);
    set_param([subsys '/Int'], 'SampleTime', '1e-4');
    add_block('simulink/Math Operations/Add', [subsys '/Sum']);
    set_param([subsys '/Sum'], 'Inputs', '++');
    add_block('simulink/Commonly Used Blocks/Saturation', [subsys '/Sat']);
    set_param([subsys '/Sat'], 'UpperLimit', num2str(sat_upper), 'LowerLimit', num2str(sat_lower));
    
    add_line(subsys, 'In/1', 'Kp/1', 'autorouting', 'on');
    add_line(subsys, 'In/1', 'Ki/1', 'autorouting', 'on');
    add_line(subsys, 'Ki/1', 'Int/1', 'autorouting', 'on');
    add_line(subsys, 'Kp/1', 'Sum/1', 'autorouting', 'on');
    add_line(subsys, 'Int/1', 'Sum/2', 'autorouting', 'on');
    add_line(subsys, 'Sum/1', 'Sat/1', 'autorouting', 'on');
    add_line(subsys, 'Sat/1', 'Out/1', 'autorouting', 'on');
end

exit;
