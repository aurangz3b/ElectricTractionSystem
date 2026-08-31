# Electric Traction System (ETS) Simulation

This repository contains a complete MATLAB/Simulink simulation of an **Electric Traction System** featuring a Bidirectional Power Flow configuration. The system is designed to simulate the drive train of an Electric Vehicle (EV), featuring a Permanent Magnet Synchronous Motor (PMSM), a Battery, a Universal Bridge Inverter, and an advanced control scheme.

## System Architecture

The simulation is built around the architecture proposed in modern electric traction research. The key components include:

1. **Energy Storage & Inverter**
   - **Traction Battery**: Modeled at 180V.
   - **DC Bus Capacitor**: Maintains the DC link voltage.
   - **Universal Bridge Inverter**: A 3-phase, 6-switch IGBT/Diode inverter that controls power flow to the motor.

2. **Custom Wye-Connected PMSM**
   - The PMSM is uniquely modeled to expose the **Neutral Point**.
   - The Battery is connected between the Motor Neutral Point and the negative rail of the DC bus through a smoothing inductor ($L_2 = 5$ mH).
   - This topology allows the Inverter and Motor windings to act as a **Boost Converter**, elevating the battery voltage to the required DC Bus voltage ($V_{DC} = 360$ V) without requiring a separate, dedicated DC/DC converter.

3. **EFOC Controller (Extended Field Oriented Control)**
   - Controls both the Motor Speed and the DC Bus Voltage simultaneously.
   - **Speed Loop**: Regulates the mechanical speed ($\omega_m$) to a reference ($\omega_{ref}$) by generating a $q$-axis current reference.
   - **Voltage Loop**: Regulates the DC bus voltage ($V_{DC}$) by manipulating the zero-sequence (neutral) current ($i_N$).
   - **Decoupling & Park Transforms**: Standard field-oriented transformations ($\theta_e$, Clark, Park) are used to decouple torque and flux generation.
   - The controller outputs 3-phase Duty Cycles which are compared against a high-frequency triangular carrier wave to generate the PWM signals for the inverter.

## File Structure

- `ETS_Model.slx`: The primary Simulink model. It contains the top-level test harness, the `PMSM_Motor` subsystem, and the `Control_System` subsystem.
- `ets_params.m`: A MATLAB script containing all physical parameters (resistances, inductances, inertias) and PI controller gains ($K_p, K_i$). **This must be run before opening the simulation.**
- `run_simulation.m`: A headless script to batch-run the simulation.
- Various MATLAB `.m` scripts used during development to programmatically assemble the Simulink blocks.

## How to Run

1. Open MATLAB.
2. Navigate to the project directory.
3. Run `ets_params.m` in the command window. This loads variables like `Ld`, `Lq`, `Ubat`, and the `PI` gains into your Base Workspace.
4. Open `ETS_Model.slx`.
5. Run the simulation using the `Run` button.
6. Open the `Results_Scope` block to view the live waveforms for:
   - DC Bus Voltage ($V_{DC}$)
   - Neutral Current ($i_N$)
   - Motor Speed ($\omega_m$)

## Note on PWM Interleaving

The model requires the PWM signals fed into the Powerlib Universal Bridge to be precisely interleaved `[A_up, A_low, B_up, B_low, C_up, C_low]`. This prevents shoot-through and allows the neutral-point boost topology to function correctly.
