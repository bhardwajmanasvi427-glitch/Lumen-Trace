# LUMEN TRACE

A small MATLAB project for image statistics, global enhancement, and exploratory forensic visualization. The supplied image is retained in `state.original`; processing functions do not modify it.

## Run

1. Open MATLAB and set the Current Folder to this project directory.
2. Run `lumenTrace` in the Command Window.
3. Select a PNG, JPEG, TIFF, or BMP image. Use **Enhance**, **Analyze forensics**, and **Evidence Map**. Analyze forensics opens a separate window with each detector's response map. Export results saves a MAT file and, if available, a PNG overlay, and a text summary report.

MATLAB Online supports the GUI in browsers with `uifigure` support. The file chooser and image rendering require a graphical MATLAB session.

## Dependencies

The GUI uses MATLAB App Building components (`uifigure`, `uiaxes`, `uigridlayout`). Forensic routines use Image Processing Toolbox functions `imresize`, `imgaussfilt`, and `edge`; run `ver` to inspect installed toolboxes. Statistics, enhancement, and percentile calculations use base MATLAB. There are no external packages.

## Methods and limits

- Statistics: luminance mean, standard deviation, 1st-to-99th percentile contrast, Shannon entropy, and 256-bin histogram.
- Enhancement: negative, log, gamma (default 0.65, adjustable in GUI), percentile contrast stretch, and empirical-CDF histogram equalization. The GUI displays all five outputs for comparison. A transparent weighted score uses contrast gain (30%), entropy (25%), edge-energy detail proxy (25%), histogram similarity to the original (10%), and clipping avoidance (10%). These are proxies, not a universal perceptual-quality measure.
- Copy-move: overlapping 16×16 block similarity search. Repeated textures can look duplicated; large images can be slow.
- Noise inconsistency: local variance in a Gaussian high-pass residual. Texture, denoising, and sensor pipelines affect it.
- Compression: 8-pixel boundary discontinuity proxy, not codec parsing; it can respond to natural periodic patterns.
- Resampling: local 64-pixel tile gradient-periodicity proxy; weak and content-sensitive.
- Edge/boundary: edge concentration near image frame; natural borders/crops can trigger it.
- Evidence map averages available nonconstant localized maps (copy-move, noise, compression, resampling), thresholds pixels above the fused-map mean plus two standard deviations, and marks candidate pixels with a strong red overlay. The frame-edge concentration map remains visible in the individual-detector window but is excluded from localization because it describes border context, not an edited region. Red indicates a high combined heuristic response, not confirmed tampering, probability, proof, or source attribution; natural scene texture, compression, and resizing can trigger it. The detector outputs are exploratory and require human review.

## Tests

In MATLAB, run `results = runtests('tests'); table(results)`. Tests cover grayscale/color/noisy inputs, low contrast, transforms, and a synthetic duplicated patch. Tests also check enhancement metric bounds and evidence-map dimensions/contribution totals. The synthetic test prints precision, recall, F1, and IoU from actual output; it does not assume detection succeeds. More ground-truth cases should be added before making performance claims.

The file-format smoke test writes temporary PNG, JPEG, TIFF, and BMP samples and reads them back; JPEG is lossy by design. `demo_inputs/demo_copy_move_controlled.png` contains an exact pasted 200×200 pixel patch with a destination ground-truth mask supplied beside it. The test suite reports measured precision, recall, F1, and IoU for this case without assuming the heuristic detected the paste. The supplied mask covers the pasted destination only; a separate source-region mask would be needed to score both regions.




Use the Gamma numeric field in the GUI (0.05–5) to set the gamma correction before choosing **Enhance**.



The edge-energy metric is a simple gradient-magnitude proxy for visible detail; histogram similarity uses Jensen-Shannon similarity against the original distribution. Fusion contribution percentages are relative shares, not calibrated probabilities. The report lists input statistics, enhancement metrics, detector limitations, candidate area, and available detector contributions.

