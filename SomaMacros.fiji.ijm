macro "Add ROI + Next Slice [q]" {

    // Fraction of image considered "edge" on each side.
    // e.g. 0.20 = middle 60% is acceptable.
    MARGIN = 0.20;

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

    if (x <= leftLimit || (x + w) >= rightLimit)
        axes = "X";

    if (y <= topLimit || (y + h) >= bottomLimit) {
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

macro "Generate Mask from ROIs [g]"{
    PREFIX = ""

    originalTitle = getTitle();
    directory = getDirectory("image");

    baseName = originalTitle;
    if (endsWith(baseName, ".tif"))
        baseName = substring(baseName, 0, lengthOf(baseName) - 4);
    if (endsWith(baseName, ".tiff"))
        baseName = substring(baseName, 0, lengthOf(baseName) - 5);

    maskTitle = baseName + "_mask.tif";

    run("Select None");

    // Duplicate the image
    run("Duplicate...", "title=" + maskTitle);

    // Make the entire duplicate black
    setForegroundColor(0, 0, 0);
    run("Select All");
    run("Fill");
    run("Select None");

    for (label = 1; ; label++) {

        n = roiManager("count");
        found = 0;

        // Check every ROI in the ROI Manager
        for (i = 0; i < n; i++) {

            name = RoiManager.getName(i);

            if (name == PREFIX + label) {
                found++;

                // Select this ROI regardless of what was initially selected
                roiManager("select", i);

                setForegroundColor(label, label, label);
                roiManager("measure");
                run("Fill", "slice");
            }
        }

        // Stop when no ROI has this name
        if (found == 0)
            break;
    }

    saveAs("Tiff", directory + maskTitle);
}

macro "Check Soma Annotation [c]" {
    getSelectionCoordinates(x, y);

    if (x.length == 0) {
        showMessage("No Point", "Click a soma with the Point Tool first.");
        exit();
    }

    px = x[0];
    py = y[0];

    n = roiManager("count");
    found = 0;

    for (i = 0; i < n; i++) {
        roiManager("select", i);

        if (selectionContains(px, py)) {
            found = 1;
            roiName = RoiManager.getName(i);
            break;
        }
    }

    if (found)
        showMessage("Already Annotated", "Soma is in ROI: " + roiName);
    else
        showMessage("Not Annotated", "No existing ROI contains this point.");
}