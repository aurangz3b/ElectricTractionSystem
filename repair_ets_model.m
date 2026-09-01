% Repair the electrical plant parameters in ETS_Model.
% Run this once from the project folder after ets_params.m has been loaded.

model = 'ETS_Model';
load_system(model);
ets_params;

% The battery must use the project parameter, not the library default (100 V).
set_param([model '/Battery'], 'Amplitude', 'Ubat');

% L2 is a smoothing inductor.  Leaving the branch as RLC places a 1 uF
% capacitor in series with the battery and completely blocks DC current.
set_param([model '/Inductor_L2'], ...
    'BranchType', 'L', ...
    'Resistance', '0.05', ...
    'Inductance', 'L2', ...
    'SetiL0', 'on', ...
    'InitialCurrent', '0');

% The DC-link element is a capacitor, not the default 1 ohm/1 mH/1 uF
% series RLC branch.  Precharge it to the battery voltage to avoid a 0 V
% divide-by-zero at controller start-up.
set_param([model '/DC_Bus_Cap'], ...
    'BranchType', 'C', ...
    'Capacitance', 'C', ...
    'Setx0', 'on', ...
    'InitialVoltage', 'Ubat');

% The PWM scheme supplies complementary gate pulses, so it requires a
% controllable IGBT bridge rather than the current thyristor bridge.
set_param([model '/Inverter'], ...
    'Device', 'IGBT / Diodes', ...
    'Ron', '1e-3', ...
    'SnubberResistance', '1e5', ...
    'SnubberCapacitance', 'inf');

% Keep the discrete electrical and Simulink solvers consistent.
set_param([model '/powergui'], 'SimulationMode', 'Discrete', 'SampleTime', '1e-5');
set_param(model, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
    'FixedStep', '1e-5');

% Restore the native EFOC interface order.  Its ports are:
% [u_bus, omega_m, omega_ref, T_re, u_bus_ref, i_N, i_abc, theta_e].
% Earlier rebuilds connected these by visual position rather than port role,
% so the controller received speed as u_bus and phase-B current as theta_e.
control = [model '/Control_System'];
efocPorts = get_param([control '/EFOC_Controller'], 'PortHandles');
for k = 1:numel(efocPorts.Inport)
    existingLine = get_param(efocPorts.Inport(k), 'Line');
    if existingLine ~= -1
        delete_line(existingLine);
    end
end

add_line(control, 'u_bus/1',      'EFOC_Controller/1', 'autorouting', 'on');
add_line(control, 'omega_m/1',    'EFOC_Controller/2', 'autorouting', 'on');
add_line(control, 'omega_ref/1',  'EFOC_Controller/3', 'autorouting', 'on');
add_line(control, 'T_re_Const/1', 'EFOC_Controller/4', 'autorouting', 'on');
add_line(control, 'u_bus_ref/1',  'EFOC_Controller/5', 'autorouting', 'on');
add_line(control, 'i_N/1',        'EFOC_Controller/6', 'autorouting', 'on');
add_line(control, 'Mux_I/1',      'EFOC_Controller/7', 'autorouting', 'on');
add_line(control, 'theta_e/1',    'EFOC_Controller/8', 'autorouting', 'on');

% I_N is physically oriented from the battery towards the neutral point,
% and consequently reports battery discharge as a negative current.  The
% native EFOC PI gains are defined for positive discharge current.  Invert
% only its feedback input; retain the unmodified sensor signal on the scope.
currentGain = [model '/I_N_For_EFOC'];
if getSimulinkBlockHandle(currentGain) == -1
    add_block('simulink/Math Operations/Gain', currentGain, ...
        'Gain', '-1', 'Position', [-25, 445, 15, 475]);
else
    set_param(currentGain, 'Gain', '-1');
end
try, delete_line(model, 'I_N/1', 'Control_System/8'); catch, end
try, delete_line(model, 'I_N_For_EFOC/1', 'Control_System/8'); catch, end
gainPorts = get_param(currentGain, 'PortHandles');
if get_param(gainPorts.Inport, 'Line') == -1
    add_line(model, 'I_N/1', 'I_N_For_EFOC/1', 'autorouting', 'on');
end
add_line(model, 'I_N_For_EFOC/1', 'Control_System/8', 'autorouting', 'on');

save_system(model);
disp('ETS repaired: plant parameters, EFOC signal order, and I_N feedback sign restored.');
