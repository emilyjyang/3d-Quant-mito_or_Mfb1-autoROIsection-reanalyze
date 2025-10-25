# AOC-Mito_Mfb1_distribution.ijm
## Overview
This FIJI macro quantifies the **subcellular distribution of mitochondria or Mfb1** (a mitochondrial-associated protein asymmetrically localized to the mother distal tip in *Saccharomyces cerevisiae*).  

Using **Cellpose-generated cell masks** and **MIP images**, this macro measures the fluorescence intensity distribution across eight defined regions of the mother–bud pair, as well as the **bud/mother intensity ratio**. It supports both **mitochondrial** and **Mfb1** signal quantification.

---

## Prerequisites

### Required Software
- [FIJI (ImageJ)](https://fiji.sc/)
- [Bio-Formats plugin](https://www.openmicroscopy.org/bio-formats/)
- [3D ImageJ Suite](https://imagej.net/plugins/3d-imagej-suite)
- [Cellpose](https://www.cellpose.org/) (for cell segmentation)

### Recommended
- Deconvolved widefield images for better signal clarity  
- Background removal before MIP generation  

### Supported File Types
`.czi`, `.nd2`, `.ome.tiff`  
(Additional file formats can be added by editing the macro header; any format supported by Bio-Formats is compatible.)

---

## Step 1 – Generate Input Images and Masks

Before running this macro, prepare your images and masks as follows:

1. Use **`AOC-maxproj_in_mask_folder-select_ch-v2.ijm`** to generate **MIP (Maximum Intensity Projection)** images for the desired channels.  
2. Process the MIPs in **Cellpose** to detect and segment cells.  
3. Save the **mask images** in the `x-Mask` subfolder of your input directory (as `.png` files).  


---

## Step 2 – Running the Macro

1. Launch FIJI and open **`AOC-Mito_Mfb1_distribution.ijm`**.  
2. When prompted, specify:
   - **Input folder:** containing raw images and the `x-Mask` folder.  
   - **Output folder:** where results will be saved.  
   - **Fluorescent channel:** choose either *mitochondria* or *Mfb1*. (Actin channel is not required.)  
3. Define the **crop size** based on your cell dimensions. If your cells are larger than normal, increase the crop size to ensure the entire cell is captured.

---

## Step 3 – Thresholding and Signal Preparation

1. The macro will prompt you to set **threshold values** for the mitochondrial and/or Mfb1 channels.  
2. Adjust the threshold to include all relevant fluorescent signals without adding background noise.  
3. The chosen values will be saved as `.txt` files for reference.  
   - **Important:** Use the same threshold across all analyses in one dataset for consistency.  

If needed, you can use the **Reanalyze** function to:
- Rerun quantification with adjusted thresholds.  
- Automatically reuse saved ROIs (cell numbers and 8 defined regions).  

---

## Step 4 – Defining Cell Geometry

1. **Select cells** to analyze in the displayed image.  
2. Add a **point ROI** near the bud neck (this defines cropping reference).  
3. For each selected cell:
   - Macro will crop the corresponding raw image, MIP, and mask.  
   - Draw a **line ROI** along the **mother–bud axis** (from the mother distal tip to the bud neck).  
   - Draw another line ROI to define the **bud** region (from the bud neck to the bud tip).  
4. Use the **wand tool** on the Cellpose mask to select the **mother cell ROI** and **bud ROI**.  
   - Alternatively, use the **freehand selection tool** if the segmentation is inaccurate.  

The macro automatically divides the mother ROI (3 regions) and Bud ROI (2 regions) and saves all ROIs and positional data for downstream quantification.

---

## Step 5 – Quantification and Output

The macro performs fluorescence quantification across **eight defined regions**:
1. Mother cell  
2. Bud cell  
3. Total  
4. Mother tip  
5. Mother center  
6. Mother neck  
7. Bud neck  
8. Bud tip  

Batch mode is recommended to hide image windows during quantification and improve speed.

### Output Files and Folders

| Folder | Description |
|---------|-------------|
| `0-M_Bratio` | Bud-to-mother fluorescence intensity ratio |
| `2-SumIntDen-mito` | Mitochondrial fluorescence intensity across 8 regions |
| `3-SumIntDen-mfb1` | Mfb1 fluorescence intensity across 8 regions |

Additional saved data:
- Threshold values (`.txt`)  
- Cell number ROI  
- 8-region ROI for each cell  

---

## Step 6 – Reanalysis Option

If you need to adjust thresholds or rerun the analysis:
1. Activate **Reanalyze** mode.  
2. The macro will automatically reload:
   - Cell number ROIs  
   - 8-region ROIs  
3. It will then reprocess intensity quantification using updated threshold settings.

<!--
---

## Example Workflow

### 1. Example Input Image  
Raw mitochondrial or Mfb1 channel image.  
![Example Input Image](images/example_mito_input.png)

---

### 2. Example Cellpose Mask  
Cellpose-generated cell segmentation mask (`x-Mask`).  
![Example Cellpose Mask](images/example_mito_mask.png)

---

### 3. Example ROI Definition  
Mother–bud axis (white line), 8 regions (colored ROIs), and cell boundaries.  
![Example ROI Definition](images/example_mito_roi.png)

---

### 4. Example Output Summary  
Representative quantification results showing regional fluorescence intensity.  
![Example Output Summary](images/example_mito_output.png)
-->
---

## Notes
- Use consistent thresholding for all images within a dataset.  
- Reanalyze mode allows threshold adjustments without reselecting ROIs.  
- The crop size and file handling are identical to those used in `Quant-Coherency-dominant_direction.ijm`.  
- The macro uses the **3D ROI Manager** for intensity quantification.  

---

## Citation
If you use this macro in your research, please cite:  
> [Emily J Yang], *AOC-Mito_Mfb1_distribution-v1.ijm: FIJI Macro for Quantifying Mitochondrial and Mfb1 Distribution in Budding Yeast*, [Year].

---

## License
Released under the [MIT License](LICENSE).

---

## Contact
For feedback or questions, please contact:  
**[Emily J Yang]**  
Email: [emily.jiening.yang@gmail.com]

