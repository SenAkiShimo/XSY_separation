# Single-Channel Speech Separation on Homogeneous AI Vocals (Power vs. Dark)


## Overview

In speech neuroengineering and auditory scene analysis (like the "Cocktail Party Effect"), separating overlapping voices from a single microphone channel is a classic challenge. 

This project creates a **stress-test scenario** by mixing two distinct timbres (**Power** and **Dark**) generated from the **SAME** virtual singer(Lynne Qing Diffsinger Voicebank, VA:SenAkiShimo) singing the identical song at the exact same pitch. This breaks the disjoint orthogonality assumption relied upon by traditional DSP algorithms.

## Key Features & Methodologies

- **Time-Frequency Masking (IRM)**: Implemented a manual STFT and Ideal Ratio Mask (IRM) framework.
- **Dictionary-Based NMF**: Implemented a semi-supervised Non-negative Matrix Factorization (NMF) with multiplicative update rules to learn the spectral dictionary of the target vocal.

## Results & Discussion

1. **The Masking Approach**: Produced noticeable musical noise ("electronic bubbling" artifacts) and severe cross-talk. Since both vocals share identical $F_0$ (fundamental frequency) and harmonics, their T-F bins overlap heavily.
2. **The NMF Approach**: Showed a slight improvement in isolation by forcing the algorithm to use the pre-trained "Power" dictionary, but acoustic leakage remained due to the extreme homogeneity of the source data.
3. **Conclusion**: This project successfully maps the operational limits of traditional DSP separation. It rigorously proves that for co-channel identical-pitch source separation, prior knowledge via Deep Learning (like RNNs or Transformers) is strictly necessary.

## Structure & Usage

```text
├── power.wav                     # Clean Power dry vocal
├── dark.wav                      # Clean Dark dry vocal
├── homo_vocal_separation.m         # IRM-based separation script
├── vocal_separation_nmf.m        # NMF-based separation script
└── README.md                     # Project documentation
```

### How to Run

1. Put your `power.wav` and `dark.wav` in the root directory.
2. Open either `.m` script in MATLAB or VS Code and click **Run**.
