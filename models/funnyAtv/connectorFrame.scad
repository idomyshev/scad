include <settings.scad>

// LEGO pin holes cut through connector body (same frame as parent difference)
// Several solids in one module body are implicitly unioned — no extra union() needed
module connectorFramePinHoleCutters(shift, s) {
    translate([shift, generalThickness * 2, 0])
        rotate([0, 90, 0])
            legoPinHole();
    translate([shift, generalThickness * 2, generalThickness])
        rotate([0, 90, 0])
            legoPinHole();
    translate([shift, -generalThickness * 2, 0])
        rotate([0, 90, 0])
            legoPinHole();
    translate([shift, -generalThickness * 2, -generalThickness])
        rotate([0, 90, 0])
            legoPinHole();
    for (s1 = [0, 1, 2]) {
        translate([shift + s * generalThickness, -generalThickness * s1, generalThickness * 4])
            rotate([0, 90, 0])
                legoPinHole();
    }
}

module connectorFrame() {
    translate([36, -15, connectorFrameWidth / 2 + generalThickness / 2 + 80])
        rotate([0, 90, 90])
            difference() {
                union() {
                    color(connectorColor)
                        cube(
                            [connectorFrameWidth, connectorFrameDepth, connectorFrameHeight],
                            center = true
                        );
                    translate([0, connectorFrameDepth / 2 - generalThickness / 2, generalThickness])
                        color(connectorColorAdditional)
                            cube(
                                [connectorFrameWidth, generalThickness, connectorFrameHeight],
                                center = true
                            );
                    translate([0, -connectorFrameDepth / 2 + generalThickness / 2, -generalThickness])
                        color(connectorColorAdditional)
                            cube(
                                [connectorFrameWidth, generalThickness, connectorFrameHeight],
                                center = true
                            );
                    // translate([0, -generalThickness / 2, generalThickness])
                    //     color(connectorColorAdditional3)
                    //         rotate([0, 0, 90])
                    //             cube(
                    //                 [connectorFrameDepth - generalThickness, generalThickness, connectorFrameHeight],
                    //                 center = true
                    //             );
                    for (s = [-1, 1]) {
                        translate([s * (generalThickness / 2 + generalThickness * 4), -generalThickness + 1, generalThickness * 2.5])
                            color(connectorColorAdditional2)
                                rotate([0, 0, 90])
                                    cube(
                                        [generalThickness * 3, generalThickness, generalThickness * 4],
                                        center = true
                                    );  
                    }
                }
                connectorFramePinHoleCutters(-connectorFrameWidth / 2 + generalPinHoleWidth / 2 - 1, 1);
                connectorFramePinHoleCutters(connectorFrameWidth / 2 - generalPinHoleWidth / 2 + 1, -1);
            }
}
