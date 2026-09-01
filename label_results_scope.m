% Label the three Results_Scope signals with their physical quantities.
model = 'ETS_Model';
load_system(model);

vdcPorts = get_param([model '/V_DC'], 'PortHandles');
inPorts  = get_param([model '/I_N'], 'PortHandles');
motorPorts = get_param([model '/PMSM_Motor'], 'PortHandles');

set_param(get_param(vdcPorts.Outport, 'Line'), 'Name', 'V_{DC} (V)');
set_param(get_param(inPorts.Outport, 'Line'), 'Name', 'i_N (A)');
set_param(get_param(motorPorts.Outport(4), 'Line'), 'Name', '\omega_m (rad/s)');

save_system(model);
disp('Results_Scope signals labelled: V_DC (V), i_N (A), omega_m (rad/s).');
