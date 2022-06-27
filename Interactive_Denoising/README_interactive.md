# hp13c_EPI-hosvd_denoising

Description for "Interactive Denoising" GUI

<Data>
  - Type in “metabolite #” (as in the order of phased_data matrix; typically 1: pyruvate, 2: lactate, and 3: bicarbonate)
  - Choose a slice to display (Display slice #)
  - Scale factor: the window level is scaled by a factor determined by “Scale factor.” This scaling factor is applied to post-denoising images as well.
  - Click “Display Data” to display raw data.
  - Click “Calculate noise level” to define signal region. When a new figure shows the AUC image of the selected pre-denoised data, drage the mouse to define a region of interest encompassing HP signals. The remaining part will be considered for estimating a noise level. Hit "enter" or "space bar" to calculate the noise level from the noise-defined region. The calculated standard deviation of the noise (noise level) will be shown below <Noise estimation>.

<Denoising parameters>
  - Click “Denoise Data” to denoise the data using the denoising parameters displayed. The noise level calculated from the denoised images will be shown below <Noise estimation>.
  - If you change the parameters, the denoised images will be updated interactively.

<Noise estimation>
  - The noise level (the standard deviation of the intensities from noisy voxels) of the raw data is calculated based on the user-defined noise region. Additionally, voxels from the first and last columns (x=1 and x= the last column) of the user-defined noise mask are excluded in the noise calculation.
  - The noise level of the denoised data is calculated, and also updated if the denoising parameters are changed.
  - The noise reduction is calculated by dividing the noise level of pre-DN data by that of post-DN data.

<Signal traces>
  - The AUC image of the denoised images is shown.
  - Use a data tip (cursor) to find x and y coordinates of the voxel that is of interest to see signal dynamics.
  - Type in the x and y coordinates in the fields.
  - Click “Display traces” to show the signal traces of the selected voxel and a neighboring voxel.
  -  The legend next to the signal dynamics plot show the x and y coordinates of the voxels. 

<Data file>
  - The phased data should be stored in this order: [y x z met timeframe]
