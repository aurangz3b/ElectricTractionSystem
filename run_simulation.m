try
    model = 'ETS_Model';
    load_system(model);
    
    % Load parameters into base workspace
    evalin('base', 'ets_params');
    
    % Configure solver
    set_param(model, 'SolverType', 'Fixed-step');
    set_param(model, 'Solver', 'FixedStepDiscrete');
    set_param(model, 'FixedStep', '1e-5');
    set_param(model, 'StopTime', '0.05'); % Run for 50ms to verify it works quickly
    
    disp('Starting Simulink simulation (running for 50ms)...');
    
    % Run simulation
    simOut = sim(model);
    
    disp('Simulation finished successfully!');
catch e
    disp('Simulation failed with error:');
    disp(e.message);
end
exit;
