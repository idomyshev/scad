// Cutout cylinder: Ø33 mm. Height = (base height 6.6 − bottom wall 1.8) + 1 mm past the
// top face so the boolean is not coplanar with the lid. Same XY center as base_cylinder().
module cutout_cylinder() {
    translate([0, 0, 1.8])
        cylinder(h = 5.8, d = 33, center = false);
}
