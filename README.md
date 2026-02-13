# SRC - SNN - 01

End-to-end tooling and HDL sources to run a **Spiking Neural Network (SNN)** based on a **Spiking Recurrent Cell (SRC)** on FPGA, using **MNIST** spike-train inputs.

This repository is primarily a *working research repo*: it contains Julia notebooks (data + model preparation) and VHDL packages/entities (FPGA-oriented implementation + simulation).

> Folder naming note: the HDL folder is named `02 - PGA/` in this repo (likely meant to be `FPGA`). The README keeps the on-disk names as-is.

<p align="center">
  <img src="assets/overview.png" width="700">
</p>
---

## At a glance

- **Task:** MNIST classification using spike trains (rate encoding).
- **Input:** 28×28 pixels ⇒ **784 input spikes per timestep**.
- **Network (VHDL implementation):** **784 → 100 → 10** (hidden layer = 100 neurons, output = 10 classes).
- **Sequence format (from `model/config.json`):** prefix=20, seq=200, suffix=0 ⇒ total=220 timesteps.
- **Example FPGA memory (`.coe`):** 500 sequences × 220 timesteps = **110000 frames**.

> Note: `model/config.json` currently says `hidden_size=128`, but the exported arrays and the VHDL packages are built for **100** hidden neurons. The **arrays/VHDL are the source of truth** in this repo.

---

## Repository layout (top level)

| Path | What it is |
|---|---|
| `.gitattributes` | Git attribute settings (line-ending normalisation). |
| `README.md` | This file. |
| `01 - Julia/` | Julia notebooks and tooling (dataset generation, model simulation, code export). |
| `02 - PGA/` | VHDL sources and HDL simulation projects (FPGA implementation). |

---

## Julia side (dataset + modelling + export)

### Folders

| Path | What it is |
|---|---|
| `01 - Julia/01 - SRC-NFPGA 01/` | SRC neuron parameter sweeps and `Zhyp` calibration notebooks + exported plots. |
| `01 - Julia/02 - Mnist2NPY-GIF/` | MNIST → spike-train conversion and visualisation notebooks. |
| `01 - Julia/03 - SNN-SRC-Flo-PsV/` | Network simulation and floating vs FPGA-style comparison notebooks + model artefacts. |
| `01 - Julia/04 - Npy2COEXOR/` | Converters from NPY spike trains to FPGA `.coe` initialisation files. |
| `01 - Julia/05 - GenVhdlCode/` | VHDL package/code generation notebooks (weights/coefficients). |
| `01 - Julia/MNIST/` | Generated datasets (NPY/GIF/COE). |
| `01 - Julia/MyLib/` | Reusable Julia helper library. |

### Key files (what to open first)

| Path | What it is |
|---|---|
| `01 - Julia/Julia-StartJupyterLab.jl` | Launches JupyterLab from the current directory via IJulia. |
| `01 - Julia/MyLib/FpgaLib-02.jl` | Julia helper library for FPGA-oriented modelling (fixed-point scaling, spike/burst equations, utilities). |
| `01 - Julia/01 - SRC-NFPGA 01/01 - SrcBrut-Zlib-03E-FPGA01(Tbl-Zhyp).ipynb` | Main notebook exploring SRC bursting dynamics and the `Zhyp` table used on FPGA (full version). |
| `01 - Julia/01 - SRC-NFPGA 01/02 - SrcBrut-Zlib-03E-FPGA01(Tbl-Zhyp)-Light.ipynb` | Lightweight version of the `Zhyp` exploration notebook (faster to run / reduced outputs). |
| `01 - Julia/01 - SRC-NFPGA 01/03 - SrcBrut-Zlib-03E-FPGA01(Tbl-Zhyp)-PAPER.ipynb` | Paper-oriented notebook variant (plots/figures arranged for reporting). |
| `01 - Julia/01 - SRC-NFPGA 01/ZfloVSZvhdl.xlsx` | Spreadsheet comparing floating-point parameters vs VHDL/fixed-point values (calibration aid). |
| `01 - Julia/02 - Mnist2NPY-GIF/01 - MNISTWriteFile2NPY_GIF-01.ipynb` | Converts MNIST samples to spike-train `.npy` files and generates `.gif`/image visualisations. |
| `01 - Julia/02 - Mnist2NPY-GIF/ART-NET-SRC-NPY-FNET-All-01-VHDL.ipynb` | End-to-end network simulation (Li=100, Lo=10) using NPY inputs; validates and prepares FPGA/VHDL artefacts. |
| `01 - Julia/03 - SNN-SRC-Flo-PsV/01 - SNN-NETWORK-SRC-NPY-FloVsPsV.ipynb` | Compares the floating-point model against the FPGA-oriented / fixed-point-style model (sanity checks & plots). |
| `01 - Julia/03 - SNN-SRC-Flo-PsV/model/config.json` | Model configuration (JSON) used by notebooks and code generators. |
| `01 - Julia/03 - SNN-SRC-Flo-PsV/model/arrays.npz` | Packed arrays (weights, biases, initial states) exported for Julia loading. |
| `01 - Julia/04 - Npy2COEXOR/01 - MNISTWriteFileSptXOR(FULL-µmac-Ms).ipynb` | Converts spike-train NPY inputs into Xilinx/AMD `.coe` memories (XOR encoding variant; full µmachine timing). |
| `01 - Julia/04 - Npy2COEXOR/02 - MNISTWriteFileSptXOR(HUB75-70-µmac).ipynb` | Same idea as above but tailored to a HUB75/70-µmachine target format. |
| `01 - Julia/05 - GenVhdlCode/01 - Product_VHDL_WeightPKG-Coef.ipynb` | Generates VHDL packages for weight matrices and coefficients from the exported model arrays/config. |

### Model test bundle (`DossierTest/`)

| Path | What it is |
|---|---|
| `01 - Julia/03 - SNN-SRC-Flo-PsV/model/DossierTest/config.txt` | Test artefact exported from training/processing (used to validate loading and shapes). |
| `01 - Julia/03 - SNN-SRC-Flo-PsV/model/DossierTest/l0_bias.npy` | Test artefact exported from training/processing (used to validate loading and shapes). |
| `01 - Julia/03 - SNN-SRC-Flo-PsV/model/DossierTest/l0_forward_weights.npy` | Test artefact exported from training/processing (used to validate loading and shapes). |
| `01 - Julia/03 - SNN-SRC-Flo-PsV/model/DossierTest/l0_initial_h.npy` | Test artefact exported from training/processing (used to validate loading and shapes). |
| `01 - Julia/03 - SNN-SRC-Flo-PsV/model/DossierTest/l0_initial_hs.npy` | Test artefact exported from training/processing (used to validate loading and shapes). |
| `01 - Julia/03 - SNN-SRC-Flo-PsV/model/DossierTest/l0_initial_i.npy` | Test artefact exported from training/processing (used to validate loading and shapes). |
| `01 - Julia/03 - SNN-SRC-Flo-PsV/model/DossierTest/l0_r.npy` | Test artefact exported from training/processing (used to validate loading and shapes). |
| `01 - Julia/03 - SNN-SRC-Flo-PsV/model/DossierTest/l0_rho.npy` | Test artefact exported from training/processing (used to validate loading and shapes). |
| `01 - Julia/03 - SNN-SRC-Flo-PsV/model/DossierTest/l0_rs.npy` | Test artefact exported from training/processing (used to validate loading and shapes). |
| `01 - Julia/03 - SNN-SRC-Flo-PsV/model/DossierTest/l0_zs_dep.npy` | Test artefact exported from training/processing (used to validate loading and shapes). |
| `01 - Julia/03 - SNN-SRC-Flo-PsV/model/DossierTest/l0_zs_hyp.npy` | Test artefact exported from training/processing (used to validate loading and shapes). |
| `01 - Julia/03 - SNN-SRC-Flo-PsV/model/DossierTest/model.zip` | Example packaged model artefacts (convenient bundle for testing). |
| `01 - Julia/03 - SNN-SRC-Flo-PsV/model/DossierTest/readout.npy` | Test artefact exported from training/processing (used to validate loading and shapes). |

### Generated datasets (`01 - Julia/MNIST/`)

The MNIST folder is *mostly generated data* (large):

- `NPY/spiking_number00001.npy`, `...00002.npy`, ...  
  One file per MNIST sample, containing the spike-train sequence.
- `GIF/`  
  Visual checks (GIFs / frames) to inspect spike encodings.
- `COEXOR/SpikingNumber(...).coe`  
  FPGA memory initialisation exports (multiple variants, often split into ranges such as `00001to02500`).

---

## FPGA / VHDL side

### Folders

| Path | What it is |
|---|---|
| `02 - PGA/01-Sim_FIX_MBrc_First_optimisation/` | Active-HDL simulation project for an early fixed-point MBrc/SRC experiment. |
| `02 - PGA/02-ExTmBinder-06Ending/` | Main VHDL binder + generated weight packages + example COE memory. |
| `02 - PGA/21-ExTmBinder-06EndingScreen/` | Same content as `02-ExTmBinder-06Ending/` (kept as a variant folder). |

### Main binder + generated packages (`02-ExTmBinder-06Ending/`)

| Path | What it is |
|---|---|
| `02 - PGA/02-ExTmBinder-06Ending/ExBinder06.vhd` | Top-level binder that instantiates packages/entities to build the full network. |
| `02 - PGA/02-ExTmBinder-06Ending/NEtWorkLevel00_pkg.vhd` | Network level 0 wrapper / glue (typically input handling and orchestration). |
| `02 - PGA/02-ExTmBinder-06Ending/NEtWorkLevel01_pkg.vhd` | Network level 1 wrapper: 784→100 layer (hidden SRC neurons). |
| `02 - PGA/02-ExTmBinder-06Ending/NEtWorkLevel02_pkg.vhd` | Network level 2 wrapper: 100→10 readout layer. |
| `02 - PGA/02-ExTmBinder-06Ending/NEtWorkLevel03_pkg.vhd` | Network level 3 wrapper: final aggregation / control. |
| `02 - PGA/02-ExTmBinder-06Ending/Neuron_BramInLine_pkg.vhd` | BRAM-in-line helper package (memory interface / streaming). |
| `02 - PGA/02-ExTmBinder-06Ending/Neuron_Cmp_pkg.vhd` | Comparator / decision logic used by neurons / readout. |
| `02 - PGA/02-ExTmBinder-06Ending/Neuron_LIfB_pkg.vhd` | LIF / spike generator package (alternative neuron model). |
| `02 - PGA/02-ExTmBinder-06Ending/Neuron_Src2F_pkg.vhd` | SRC neuron package (spike/burst generator) used for the hidden layer. |
| `02 - PGA/02-ExTmBinder-06Ending/SpikingNumber(Size220)_00001to00500.coe` | Example COE memory with spike trains (500 sequences, length 220) for FPGA/HDL simulation. |
| `02 - PGA/02-ExTmBinder-06Ending/WeightMatrix00_pkg.vhd` | Global dataset/shape constants (e.g., 28×28 pixels, sequence length bookkeeping). |
| `02 - PGA/02-ExTmBinder-06Ending/WeightMatrix01_pkg.vhd` | Weight matrix package for the 784→100 layer (default scaling). |
| `02 - PGA/02-ExTmBinder-06Ending/WeightMatrix01_pkg(+-002).vhd` | 784→100 weight package variant (different quantisation/scaling). |
| `02 - PGA/02-ExTmBinder-06Ending/WeightMatrix01_pkg(+-004).vhd` | Same as above (+/-004 variant). |
| `02 - PGA/02-ExTmBinder-06Ending/WeightMatrix01_pkg(+-008).vhd` | Same as above (+/-008 variant). |
| `02 - PGA/02-ExTmBinder-06Ending/WeightMatrix01_pkg(+-016).vhd` | Same as above (+/-016 variant). |
| `02 - PGA/02-ExTmBinder-06Ending/WeightMatrix01_pkg(+-032).vhd` | Same as above (+/-032 variant). |
| `02 - PGA/02-ExTmBinder-06Ending/WeightMatrix01_pkg(+-064).vhd` | Same as above (+/-064 variant). |
| `02 - PGA/02-ExTmBinder-06Ending/WeightMatrix01_pkg(+-128).vhd` | Same as above (+/-128 variant). |
| `02 - PGA/02-ExTmBinder-06Ending/WeightMatrix01_pkg(+-256).vhd` | Same as above (+/-256 variant). |
| `02 - PGA/02-ExTmBinder-06Ending/WeightMatrix01_pkg(+-512).vhd` | Same as above (+/-512 variant). |
| `02 - PGA/02-ExTmBinder-06Ending/WeightMatrix02_pkg.vhd` | Readout weight matrix (100→10) and associated bounds/constants. |
| `02 - PGA/02-ExTmBinder-06Ending/WeightMatrix03_pkg.vhd` | Final small matrix/type definitions (1×10) used by the last stage. |

### Active-HDL simulation project (`01-Sim_FIX_MBrc_First_optimisation/`)

| Path | What it is |
|---|---|
| `02 - PGA/01-Sim_FIX_MBrc_First_optimisation/` | Active-HDL simulation project for the fixed-point bursting cell (Aldec project tree). |
| `02 - PGA/01-Sim_FIX_MBrc_First_optimisation/aldec/Brc_First/Brc_First/src/brc_first.vhd` | Top-level VHDL for the bursting-cell testbench/project. |
| `02 - PGA/01-Sim_FIX_MBrc_First_optimisation/aldec/Brc_First/Brc_First/src/brc_lib_pkg.vhd` | Shared package for the bursting-cell simulation. |
| `02 - PGA/01-Sim_FIX_MBrc_First_optimisation/aldec/Brc_First/Brc_First/src/*.asdb, *.awc` | Waveform database files produced by the simulator (generated). |

---

## Requirements

### Julia
- Julia + Jupyter (IJulia)
- Packages commonly used in the notebooks: `IJulia`, `NPZ`, `JSON3`, `MLDatasets` (MNIST) and standard Julia libs.

### HDL / FPGA
- Any VHDL simulator should work; the repo includes an **Aldec Active-HDL** project under `02 - PGA/01-Sim_FIX_MBrc_First_optimisation/`.
- For FPGA builds, use your usual AMD/Xilinx flow (e.g., Vivado). `.coe` files are provided/generated for BRAM initialisation.

---

## Typical workflow

1. **Generate MNIST spike trains (Julia)**  
   Open:  
   - `01 - Julia/02 - Mnist2NPY-GIF/01 - MNISTWriteFile2NPY_GIF-01.ipynb`

2. **Run / validate the SNN in Julia**  
   Open:  
   - `01 - Julia/03 - SNN-SRC-Flo-PsV/01 - SNN-NETWORK-SRC-NPY-FloVsPsV.ipynb`  
   Uses model artefacts in `01 - Julia/03 - SNN-SRC-Flo-PsV/model/`.

3. **Export FPGA-friendly inputs (COE)**  
   Open:  
   - `01 - Julia/04 - Npy2COEXOR/01 - MNISTWriteFileSptXOR(FULL-µmac-Ms).ipynb`  
   - `01 - Julia/04 - Npy2COEXOR/02 - MNISTWriteFileSptXOR(HUB75-70-µmac).ipynb`

4. **Generate VHDL weight packages (Julia)**  
   Open:  
   - `01 - Julia/05 - GenVhdlCode/01 - Product_VHDL_WeightPKG-Coef.ipynb`  
   Output files match the VHDL packages in `02 - PGA/02-ExTmBinder-06Ending/` (e.g., `WeightMatrix01_pkg*.vhd`).

5. **Simulate / integrate in HDL**  
   Use the binder:  
   - `02 - PGA/02-ExTmBinder-06Ending/ExBinder06.vhd`  
   and the network level wrappers:  
   - `NEtWorkLevel00_pkg.vhd` … `NEtWorkLevel03_pkg.vhd`

---

## Practical notes

### Weight quantisation / scaling variants
`WeightMatrix01_pkg(+-XXX).vhd` are multiple generated variants of the **784→100** weight package.  
They correspond to different quantisation/scaling choices (useful for accuracy vs hardware cost trade-offs).

### Large files & repo hygiene
This repo contains **multi-GB generated data** (MNIST spike trains, COE files) and Jupyter checkpoints.

If you plan to publish this as a clean GitHub repository, consider:
- Adding a `.gitignore` for:
  - `**/.ipynb_checkpoints/`
  - `**/*.asdb`, `**/*.awc` (simulator wave databases)
  - large generated datasets under `01 - Julia/MNIST/`
- Using **Git LFS** for large `.coe`, `.npy`, `.npz`, `.pdf` if they must remain tracked.

### Windows shortcuts
Files ending in `.lnk` are Windows shortcuts and are **optional**.

---

## License
No license file is included yet. Add a `LICENSE` if you want others to reuse the code.

## Contact
Maintainer: Pascal Harmeling (ULiège) — update this section with your preferred contact link.
