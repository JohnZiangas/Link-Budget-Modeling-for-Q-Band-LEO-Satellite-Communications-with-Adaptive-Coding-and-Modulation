# Link Budget Modeling for Q-Band LEO Satellite Communications with Adaptive Coding and Modulation

This project was developed during the 2025 academic year for the course *Information Theory (ECE_TEL851)* at the **Department of Electrical and Computer Engineering, University of the Peloponnese**.  

It builds on earlier work completed in *Pattern Recognition (ECE_TEL830)*, available in the [EPL Forecasting Repository](https://github.com/JohnZiangas/Simulation-for-Q-V-Band-Excess-Path-Loss-Forecasting-in-LEO-Satellite-Links-Using-Deep-Learning), where excess path loss (EPL) forecasting using deep learning (LSTM) was first introduced. This repository extends that foundation with a comprehensive **adaptive link budget analysis** for Q/V-band LEO satellite communications.


The MATLAB framework integrates two main components:
- **Link budget modeling**, incorporating realistic atmospheric effects and noise contributions.  
- **Adaptive coding and modulation (ACM)**, enabling dynamic throughput optimization under time-varying channel conditions.  

 For more detailed information on the implementation, please refer to the accompanying paper that explains the methodology and workflow.

---

## Features

- **Satellite Pass Simulation**  
  SGP4-propagated trajectories for multiple LEO satellites and a fixed ground station.

- **Atmospheric Modeling**  
  Incorporates standardized propagation ITU-R models to account for signal attenuation under varying atmospheric conditions.

- **Noise Temperature Calculation**  
  Includes contributions from internal receiver noise, atmospheric brightness temperature, and antenna spillover for both uplink and downlink.

- **Link Budget Evaluation**  
  Generates **C/No time series** that reflect realistic propagation and noise conditions.

- **Adaptive Coding & Modulation (ACM)**  
  Implements a Shannon-capacity-based MODCOD selection algorithm with hysteresis control, ensuring stable operation without excessive mode switching.  

---

##  Setup Instructions

1. **Edit paths**  
   - Open `mainScript.m`.  
   - On **line 83**, set the folder path where the raw meteorological data are stored.  
   - The path must end with:  
     ```
     .../1-Data
     ```
     
  2. **Enable plotting (optional)**  
   - Some scripts include plotting sections that are commented out.  
   - Uncomment to visualize intermediate results.

---

## Citation

This code is open for use and modification in other projects. If it contributes to your work, I would greatly appreciate a citation, either to the associated paper (link to be added) or directly to this GitHub repository. :)
