# Annotating Somas Quickly Using FIJI

## Setup

### ROI Manager Settings

Using the `Freeform selections` tool in the FIJI menu, create your first region. Press the `t` key to save it as an ROI (Region Of Interest) and open the ROI Manager. Deselect any ROIs and then navigate to `More > Options > Associate "Show All" ...`. This should be checked.

### Macros

Copy `SomaMacros.fiji.ijm` to `FIJI/macros/toolsets`. Then in FIJI, everytime upon opening, click `>>` on the right-hand side of the toolbar, followed by `SomaMacros.fiji`. This installs the macros.

## Commands to Know

* Move through z-slices: `<`/`>` OR `left`/`right` keys OR touchpad/scroll
* Pan: `spacebar` + click
* Zoom: `+`/`-` OR `up`/`down` keys
* Save region as ROI: `T`
* Fill (one ROI): `ctrl` + `F`

### Macro Shortcuts

* Add ROI and advance: `Q`
* Rename non-int ROIs to next int: `W`
* Save ROIs as ZIP (do this often): `E`
* Rename selected ROIs: `R`
* Load ZIP to ROIs: `P`
* Generate mask: `G`
* Condense Z Stacks: `C`

## Workflow

### Log ROIs

1. Open the .TIF in FIJI, and press `C` to generate a condensed version of the image and locate the somas.

2. For one soma within the middle 80% of the volume (or whatever limit is being used), step through z-stacks and use the `Freeform selections` tool to capture each outline, adding and advancing quickly using `Q`.

3. After capturing each slice of the soma, press `W`. This executes the macro and renames the soma to the correct integer. If corrections are needed, you can always select the ROIs, press `R`, and enter the correct names.

4. Repeat Steps 2 and 3 for each soma. Remember to press `E` often to save. Use the "Show All" checkbox in the ROI Manager to confirm that each soma has been annotated.

### Fill ROIs

Once all somas have been added to the ROI Manager, press `G`. The mask will be generated and saved to the same directory as the original .TIF.

Make sure all ROIs are saved (`E`). Then, they can at any time be loaded with `P` and used to generate the masks (`G`).

### Saving Annotations

Use `E` to save and `P` to load. Note: loading clears all existing ROIs.

## Time Benchmarking

Around the time of writing this, no mouse, I'm averaging:

* 5s / soma-slice ROI
* Assuming an average depth of 15 z-slices per soma => ~75s / soma
* Assuming an average of 10 somas per image => ~20m / image


















