// Base cylinder for bathroom holder (circle variant): Ø40 mm, height 6.6 mm.
// Bottom on Z=0, extends along +Z.
module base_cylinder() {
    color([0.55, 0.33, 0.2])
        cylinder(h = 6.6, d = 40, center = false);
}
