import numpy as np
import matplotlib.pyplot as plt

class ETS_Simulation:
    def __init__(self):
        # PMSM Parameters (Table I)
        self.R = 0.81       # ohm
        self.p = 4          # pole pairs
        self.Ld = 1.5e-3    # H
        self.Lq = 1.5e-3    # H
        self.L0 = 2.4e-3    # H
        self.psi_f = 0.1    # Wb
        
        # System Parameters
        self.L2 = 5e-3      # H
        self.C = 940e-6     # F
        self.u_bat = 180    # V
        
        # Current PI (dq)
        self.Kp_id = 1.5
        self.Ki_id = 810.0
        self.Kp_iq = 1.5
        self.Ki_iq = 810.0
        
        # Neutral Current PI
        self.Kp_iN = -0.016
        self.Ki_iN = -0.75
        
        # DC Bus Voltage PI
        self.Kp_vbus = 0.2
        self.Ki_vbus = 5.0
        
        # Speed PI
        self.Kp_spd = 0.1
        self.Ki_spd = 2.0
        
        # Mechanical
        self.J = 0.005 
        self.B = 0.001
        
        # States
        self.id = 0.0
        self.iq = 0.0
        self.iN = 0.0
        self.omega_m = 0.0
        self.theta_e = 0.0
        self.u_bus = 180.0  # Initialized to u_bat
        
        # PI Integrators
        self.int_id = 0.0
        self.int_iq = 0.0
        self.int_iN = 0.0
        self.int_vbus = 0.0
        self.int_spd = 0.0
        
    def step(self, dt, omega_ref, T_L):
        # 1. Speed Controller (PI)
        err_spd = omega_ref - self.omega_m
        self.int_spd += err_spd * dt
        T_e_ref = self.Kp_spd * err_spd + self.Ki_spd * self.int_spd
        # Limit torque
        T_e_ref = np.clip(T_e_ref, -15, 15)
        
        # 2. MTPA for SPMSM (id=0)
        id_ref = 0.0
        iq_ref = T_e_ref / (1.5 * self.p * self.psi_f)
        
        # 3. DC Bus Voltage Controller
        u_bus_ref = 360.0
        err_vbus = u_bus_ref - self.u_bus
        self.int_vbus += err_vbus * dt
        iN_ref = self.Kp_vbus * err_vbus + self.Ki_vbus * self.int_vbus
        iN_ref = np.clip(iN_ref, -30, 30)
        
        # 4. Neutral Current Controller -> D0
        err_iN = iN_ref - self.iN
        self.int_iN += err_iN * dt
        # D0 has a feedforward term roughly = u_bat / u_bus
        ff_D0 = self.u_bat / max(self.u_bus, 10.0)
        D0 = ff_D0 + self.Kp_iN * err_iN + self.Ki_iN * self.int_iN
        D0 = np.clip(D0, 0.1, 0.9)
        
        # Anti-windup
        if D0 == 0.1 or D0 == 0.9:
            self.int_iN -= err_iN * dt
            
        # 5. DQ Current Controllers -> ud*, uq*
        err_id = id_ref - self.id
        self.int_id += err_id * dt
        ud_star = self.Kp_id * err_id + self.Ki_id * self.int_id
        
        err_iq = iq_ref - self.iq
        self.int_iq += err_iq * dt
        uq_star = self.Kp_iq * err_iq + self.Ki_iq * self.int_iq
        
        # Add decoupling
        omega_e = self.omega_m * self.p
        ud_star -= omega_e * self.Lq * self.iq
        uq_star += omega_e * (self.psi_f + self.Ld * self.id)
        
        # Motor Dynamics
        did_dt = (ud_star - self.R * self.id + omega_e * self.Lq * self.iq) / self.Ld
        diq_dt = (uq_star - self.R * self.iq - omega_e * (self.psi_f + self.Ld * self.id)) / self.Lq
        
        # Torque
        Te = 1.5 * self.p * (self.psi_f * self.iq + (self.Ld - self.Lq) * self.id * self.iq)
        domega_m_dt = (Te - T_L - self.B * self.omega_m) / self.J
        
        # Zero Sequence Dynamics (DC/DC converter)
        L_eq = self.L0 / 3 + self.L2
        diN_dt = (self.u_bat - D0 * self.u_bus - (self.R / 3) * self.iN) / L_eq
        
        # DC Bus Dynamics
        du_bus_dt = (D0 * self.iN - 1.5 * (ud_star * self.id + uq_star * self.iq) / self.u_bus) / self.C
        
        # Update states
        self.id += did_dt * dt
        self.iq += diq_dt * dt
        self.iN += diN_dt * dt
        self.omega_m += domega_m_dt * dt
        self.theta_e += omega_e * dt
        self.u_bus += du_bus_dt * dt
        
        return self.omega_m, self.u_bus, self.iN, self.iq, Te, D0

def run_sim():
    sim = ETS_Simulation()
    dt = 1e-5
    t_end = 6.0
    steps = int(t_end / dt)
    
    t_log = np.zeros(steps)
    omega_log = np.zeros(steps)
    ubus_log = np.zeros(steps)
    iN_log = np.zeros(steps)
    Te_log = np.zeros(steps)
    iq_log = np.zeros(steps)
    
    omega_ref = 0.0
    T_L = 0.0
    
    for k in range(steps):
        t = k * dt
        
        # Boost stage (0 to 1.5s): let bus voltage rise, motor off
        if t < 1.5:
            omega_ref = 0.0
            T_L = 0.0
        # Driving stage (1.5s to 3.0s): speed up to 3000 rpm (314 rad/s)
        elif t < 3.0:
            omega_ref = 314.16
            T_L = 0.0
        # Load step (3.0s to 4.5s)
        elif t < 4.5:
            omega_ref = 314.16
            T_L = 4.0
        # Regenerative braking (4.5s to 6.0s): speed to 0
        else:
            omega_ref = 0.0
            T_L = 0.0
            
        omega_m, u_bus, iN, iq, Te, D0 = sim.step(dt, omega_ref, T_L)
        
        t_log[k] = t
        omega_log[k] = omega_m
        ubus_log[k] = u_bus
        iN_log[k] = iN
        Te_log[k] = Te
        iq_log[k] = iq

    plt.figure(figsize=(12, 10))
    
    plt.subplot(4,1,1)
    plt.plot(t_log, omega_log * 30 / np.pi)
    plt.ylabel('Speed (rpm)')
    plt.grid()
    plt.title('ETS Simulation: Boost -> Motoring -> Load -> Braking')
    
    plt.subplot(4,1,2)
    plt.plot(t_log, ubus_log)
    plt.axhline(360, color='r', linestyle='--')
    plt.ylabel('DC Bus (V)')
    plt.grid()
    
    plt.subplot(4,1,3)
    plt.plot(t_log, iN_log)
    plt.ylabel('Neutral Current iN (A)')
    plt.grid()
    
    plt.subplot(4,1,4)
    plt.plot(t_log, Te_log)
    plt.ylabel('Torque (Nm)')
    plt.xlabel('Time (s)')
    plt.grid()
    
    plt.tight_layout()
    plt.savefig('simulation_results.png')
    print("Simulation complete. Results saved to simulation_results.png")

if __name__ == '__main__':
    run_sim()
