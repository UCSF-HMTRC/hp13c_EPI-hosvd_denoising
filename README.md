# hp13c_EPI-hosvd_denoising

This Github repository contains matlab codes for denoising hyperpolarized 13C MR images of the human brain using patch-based higher-order singular value decomposition and sample data from a healthy brain volunteer and simulations. The description of the method and results can be found in the paper published in Magnetic Resonance in Medicine (doi: 10.1002/mrm.28887.)

- In the 'data' folder, in vivo and simulated data files can be found (invivo_hp13c_EPI.mat / simulation_PyrLacDynamics.mat).
- The 'GL-HOSVD' folder contains matlab function codes for the patch-based denoising and kinetic rate fitting. 
- The 'Interactive_Denoising' folder contains the 'main_1.m' script which can be used to see the effects of using different densoing parameters on the resulting images interactively. More descriptions can be found in the 'README.md'.

- <demo_glhosvd_invivo_hp13cepi.m>
It demonstrates an example for denoising in vivo hyperpolarized 13C MR data of the human brain and analyzing kPL(apparent pyruvate-to-lactate conversion rate) from both raw and denoised images.

- <demo_simulation_glhosvd.m>
It demonstrates an example for denoising simulated noise-added metabolic images of the brain (pyruvate and lactate) and analyzing kPL from both noise-added and denoised images.
