macro "Add ROI + Next Slice [q]" {

    // Fraction of image considered "edge" on each side.
    // e.g. 0.20 = middle 60% is acceptable.
    MARGIN = 0.10;

    currentSlice = getSliceNumber();

    // Add the new selection temporarily
    roiManager("Add");
    newIndex = roiManager("count") - 1;

    n = roiManager("count");
    overlap = 0;
    overlapName = "";

    // ------------------------------
    // Overlap check
    // ------------------------------
    for (i = 0; i < newIndex; i++) {

        roiManager("select", i);
        Roi.getPosition(c, z, t);

        // Only compare ROIs on this slice
        if (z == currentSlice || z == 0) {

            roiManager("select", newArray(i, newIndex));
            roiManager("and");

            if (selectionType() != -1) {
                overlap = 1;
                overlapName = RoiManager.getName(i);
                break;
            }
        }
    }

    if (overlap) {

        // Enter defaults to "No"
        if (getBoolean(
            "Selection overlaps with soma " + overlapName + "; continue?",
            "No",
            "Yes"
        )) {
            roiManager("select", newIndex);
            roiManager("delete");
            run("Select None");
            exit();
        }
    }

    // ------------------------------
    // Edge check
    // ------------------------------

    getDimensions(width, height, channels, slices, frames);

    leftLimit   = width * MARGIN;
    rightLimit  = width * (1.0 - MARGIN);

    topLimit    = height * MARGIN;
    bottomLimit = height * (1.0 - MARGIN);

    frontLimit  = slices * MARGIN;
    backLimit   = slices * (1.0 - MARGIN);

    // Restore the new ROI and get its bounds
    roiManager("select", newIndex);
    getSelectionBounds(x, y, w, h);

    axes = "";

    if ((x + w) <= leftLimit || x >= rightLimit)
        axes = "X";

    if ((y + h) <= topLimit || y >= bottomLimit) {
        if (axes != "")
            axes += ", ";
        axes += "Y";
    }

    if (currentSlice <= frontLimit || currentSlice >= backLimit) {
        if (axes != "")
            axes += ", ";
        axes += "Z";
    }

    if (axes != "") {

        if (getBoolean(
            "Selection is outside the middle " +
            (100 - 2*MARGIN*100) +
            "% of the image (" + axes + "). Continue?",
            "No",
            "Yes"
        )) {
            roiManager("select", newIndex);
            roiManager("delete");
            run("Select None");
            exit();
        }
    }

    // ------------------------------
    // Continue workflow
    // ------------------------------

    roiManager("select", newIndex);

    run("Next Slice [>]");

    run("Select None");
}

macro "Rename Non-Integer ROIs [w]" {
    n = roiManager("count");
    highest = 0;

    // Find highest integer-valued ROI name
    for (i = 0; i < n; i++) {
        name = RoiManager.getName(i);

        if (matches(name, "[0-9]+")) {
            value = parseFloat(name);

            if (value > highest)
                highest = value;
        }
    }

    newName = highest + 1;
    count = 0;

    // Rename every non-integer ROI to the same name
    for (i = 0; i < n; i++) {
        name = RoiManager.getName(i);

        if (!matches(name, "[0-9]+")) {
            roiManager("select", i);
            roiManager("Rename", "" + newName);
            count++;
        }
    }

    showMessage("Complete", count + " ROIs named " + newName);
}

macro "Save ROIs [e]" {
    if (!getBoolean("Are you sure? This will overwrite the existing export ZIP.")) exit();

    dir = getDirectory("image");
    filename = getTitle();

    // Remove file extension
    if (endsWith(filename, ".tif"))
        filename = substring(filename, 0, lengthOf(filename) - 4);
    if (endsWith(filename, ".tiff"))
        filename = substring(filename, 0, lengthOf(filename) - 5);

    roiManager("Save", dir + filename + "_ROIs.zip");

    showMessage("ROIs Saved", filename + "_ROIs.zip");
}

macro "Load ROIs [p]" {
    if (!getBoolean("Are you sure? This will overwrite existing ROIs.")) exit();

    dir = getDirectory("image");
    filename = getTitle();

    if (endsWith(filename, ".tif"))
        filename = substring(filename, 0, lengthOf(filename) - 4);
    if (endsWith(filename, ".tiff"))
        filename = substring(filename, 0, lengthOf(filename) - 5);

    roiManager("reset");
    roiManager("Open", dir + filename + "_ROIs.zip");

    // Restore duplicate integer names
    n = roiManager("count");

    for (i = 0; i < n; i++) {
        name = RoiManager.getName(i);

        // Convert names like "1-1" and "1-2" back to "1"
        if (matches(name, "[0-9]+-[0-9]+")) {
            dash = indexOf(name, "-");
            originalName = substring(name, 0, dash);

            roiManager("select", i);
            roiManager("Rename", originalName);
        }
    }
}

macro "Rename Selected ROIs [r]" {
    name = getString("Enter new ROI name:", "1");
    indexes = split(call("ij.plugin.frame.RoiManager.getIndexesAsString"));

    for (i = 0; i < indexes.length; i++) {
        roiManager("select", parseInt(indexes[i]));
        roiManager("rename", name);
    }
}

macro "Generate Mask from ROIs [g]" {

    PREFIX = "";

    originalTitle = getTitle();
    directory = getDirectory("image");

    // Remove extension
    baseName = originalTitle;
    if (endsWith(baseName, ".tif"))
        baseName = substring(baseName, 0, lengthOf(baseName) - 4);
    if (endsWith(baseName, ".tiff"))
        baseName = substring(baseName, 0, lengthOf(baseName) - 5);

    maskTitle = baseName + "_mask";

    // Get dimensions of original stack
    getDimensions(width, height, channels, slices, frames);

    // Create blank 8-bit stack with same XY and Z dimensions
    run("New...", 
        "name=" + maskTitle +
        " type=8-bit" +
        " width=" + width +
        " height=" + height +
        " slices=" + slices);

    // New image is already black (pixel value 0)

    // Process every ROI
    n = roiManager("count");

    for (i = 0; i < n; i++) {

        name = RoiManager.getName(i);

        if (matches(name, "[0-9]+")) {

            label = parseInt(name);

            roiManager("select", i);

            // Get the ROI's Z position
            Roi.getPosition(c, z, t);

            if (z == 0)
                z = 1;

            // Go to that Z slice in the mask
            setSlice(z);

            // Set pixel value corresponding to ROI label
            setForegroundColor(label, label, label);

            // IMPORTANT: fill only this slice
            run("Fill", "slice");
        }
    }

    // Save mask
    saveAs("Tiff", directory + maskTitle + ".tif");

    showMessage(
        "Mask Generated",
        "Created:\n" +
        maskTitle + ".tif\n\n" +
        "Dimensions: " +
        width + " × " +
        height + " × " +
        slices
    );
}

macro "Condense Z Stacks [c]" {
    run("Z Project...", "projection=[Max Intensity]");
}
