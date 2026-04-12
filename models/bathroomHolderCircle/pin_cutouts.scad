// Pin holes: rounded-rectangle profile in plan (flat sides, arcs only in corners — not ellipse-like).
// Axis along Z (normal to the flat lid). Centers symmetric on ±X at pin_offset_from_axis.

pin_plan_w = 7.2;
pin_plan_h = 3.6;
// Corner radius: must be < min(w,h)/2 (here h/2 = 1.8) so a thin flat remains on the short sides.
pin_corner_r = 1.75;
pin_height = 3;

// Half-distance from Z-axis to each pin center (pair is symmetric through origin).
pin_offset_from_axis = 12.5;

// 2D rounded rectangle centered at origin (w ≥ h after rotation at call site).
module rounded_rect_2d(w, h, r) {
    iw = w / 2 - r;
    ih = h / 2 - r;
    hull() {
        translate([iw, ih])
            circle(r = r);
        translate([-iw, ih])
            circle(r = r);
        translate([iw, -ih])
            circle(r = r);
        translate([-iw, -ih])
            circle(r = r);
    }
}

// Extruded rounded rect; rotation_z_deg swaps long/short axis in plan (horizontal vs vertical).
module rounded_rect_pin_cutout(rotation_z_deg) {
    rotate([0, 0, rotation_z_deg])
        linear_extrude(height = pin_height, center = false)
            rounded_rect_2d(pin_plan_w, pin_plan_h, pin_corner_r);
}

module pin_cutouts() {
    translate([0, 0, -1]) {
        translate([pin_offset_from_axis, 0, 0])
            rounded_rect_pin_cutout(0);
        translate([-pin_offset_from_axis, 0, 0])
            rounded_rect_pin_cutout(90);
    }
}
