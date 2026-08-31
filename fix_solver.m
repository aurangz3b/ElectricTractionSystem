try
    model = 'ETS_Model';
    load_system(model);
    
    % Set powergui to discrete
    set_param([model '/powergui'], 'SimulationMode', 'Discrete');
    set_param([model '/powergui'], 'SampleTime', '1e-5');
    
    % Set model solver to discrete
    set_param(model, 'SolverType', 'Fixed-step');
    set_param(model, 'Solver', 'FixedStepDiscrete');
    set_param(model, 'FixedStep', '1e-5');
    
    save_system(model);
    disp('powergui configured to Discrete!');
catch e
    disp(e.message);
end
exit;
