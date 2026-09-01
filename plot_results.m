try
    model = 'ETS_Model';
    load_system(model);
    
    % Ensure parameters are loaded
    ets_params;
    
    % Run simulation
    out = sim(model, 'StopTime', '4.0');
    
    % Extract logs
    logs = out.logsout;
    
    % Grab data from logs safely by looking at names or block paths
    ia_ts = logs.getElement('PMSM_out_1').Values;
    ib_ts = logs.getElement('PMSM_out_2').Values;
    ic_ts = logs.getElement('PMSM_out_3').Values;
    
    % Find omega_m and theta_e
    for i = 1:logs.numElements
        elem = logs.getElement(i);
        if contains(elem.Name, 'omega')
            wm_ts = elem.Values;
        elseif contains(elem.Name, 'PMSM_out_5')
            th_ts = elem.Values;
        end
    end
    
    % V_DC and I_N
    vdc_ts = logs.getElement('V_DC_log').Values;
    in_ts = logs.getElement('I_N_log').Values;
    
    t = ia_ts.Time;
    
    % Derived signals
    th = th_ts.Data;
    ia = ia_ts.Data;
    ib = ib_ts.Data;
    ic = ic_ts.Data;
    
    id = (2/3) * (ia .* cos(th) + ib .* cos(th - 2*pi/3) + ic .* cos(th + 2*pi/3));
    iq = (2/3) * (-ia .* sin(th) - ib .* sin(th - 2*pi/3) - ic .* sin(th + 2*pi/3));
    
    Te = 1.5 * 4 * (0.1 .* iq);
    
    % Zero sequence current i0 = iN / 3
    iN = in_ts.Data;
    i0 = iN / 3;
    
    Vdc = vdc_ts.Data;
    wm = wm_ts.Data;
    
    % Plotting
    f = figure('Position', [100 100 800 1000]);
    
    % (a) Machine speed and torque
    subplot(4, 1, 1);
    yyaxis left;
    plot(t, wm, 'b-', 'LineWidth', 1.5);
    ylabel('\omega_m (rad/s)');
    ylim([0, 400]);
    yyaxis right;
    plot(t, Te, 'r-', 'LineWidth', 1.5);
    ylabel('T_e (Nm)');
    title('(a) Machine speed and torque');
    grid on;
    
    % (b) DC-bus voltage, neutral current and zero-sequence current
    subplot(4, 1, 2);
    yyaxis left;
    plot(t, Vdc, 'b-', 'LineWidth', 1.5);
    ylabel('V_{DC} (V)');
    yyaxis right;
    plot(t, iN, 'r-', 'LineWidth', 1.5); hold on;
    plot(t, i0, 'g--', 'LineWidth', 1.5);
    ylabel('Current (A)');
    legend('V_{DC}', 'i_N', 'i_0');
    title('(b) DC-bus voltage, neutral current and zero-sequence current');
    grid on;
    
    % (c) d, q-axis currents
    subplot(4, 1, 3);
    plot(t, id, 'b-', 'LineWidth', 1.5); hold on;
    plot(t, iq, 'r-', 'LineWidth', 1.5);
    ylabel('Current (A)');
    legend('i_d', 'i_q');
    title('(c) d, q-axis currents');
    grid on;
    
    % (d) Phase currents (zoomed in to see sinusoidal shape, say last 0.1s)
    subplot(4, 1, 4);
    plot(t, ia, 'b', t, ib, 'r', t, ic, 'g', 'LineWidth', 1);
    ylabel('Phase Currents (A)');
    legend('i_a', 'i_b', 'i_c');
    title('(d) Phase currents');
    xlim([3.9, 4.0]); % Zoom in to steady state
    grid on;
    
    saveas(f, 'paper_results.png');
    disp('Results plotted successfully!');
catch e
    disp(e.message);
end
exit;
