LUMEN TRACE synthetic demo inputs

1. demo_enhancement_low_contrast.png
   Synthetic low-contrast garden photograph. Use as an input to generate genuine analysis and enhancement outputs in LUMEN TRACE.

2. demo_forensics_duplicate_objects.png
   Synthetic garden photograph containing two similar-looking owl ornaments for demonstration. It is not a ground-truth copy-move manipulation and must not be used to claim detector accuracy.

3. demo_copy_move_controlled.png
   Controlled synthetic case: a 200 x 200 pixel region was copied exactly and pasted elsewhere in the image. Use this as a copy-move test input.

4. demo_copy_move_ground_truth.png
   Binary mask for the pasted destination rectangle in demo_copy_move_controlled.png. White marks the pasted region. This is ground truth for that destination only; source-region evaluation is separate.

These are generated sample input images, not screenshots of the MATLAB GUI or measured experimental results. Label them as synthetic demo inputs if included in a report or presentation.
