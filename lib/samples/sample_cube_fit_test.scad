// Fit-test brick: row of round holes (axis Z) through thickness for trying LEGO pins/axles.
// Expects globals: thickness, sample_cube_* (see funnyAtv.scad).

function _sample_cube_hole_count_() =
    let(n = floor((sample_cube_hole_d_max - sample_cube_hole_d_min) / sample_cube_hole_d_step + 1e-9) + 1)
    max(1, n);

function _sample_cube_hole_diameter_at_(i) = sample_cube_hole_d_min + i * sample_cube_hole_d_step;

// X positions along length (local coords, cube centered on origin), evenly spaced between margins.
function _sample_cube_hole_x_(i, n, L, margin) =
    n <= 1
    ? 0
    : -L / 2 + margin + i * (L - 2 * margin) / (n - 1);

module sample_cube_fit_test() {
    n = _sample_cube_hole_count_();
    difference() {
        translate([sample_cube_offset_x, sample_cube_offset_y, 0])
            color(sample_cube_color)
            cube([sample_cube_length, sample_cube_width, thickness], center = true);
        for (i = [0 : n - 1])
            let(d = _sample_cube_hole_diameter_at_(i))
            let(x = _sample_cube_hole_x_(i, n, sample_cube_length, sample_cube_hole_margin))
            translate([sample_cube_offset_x + x, sample_cube_offset_y, 0])
                cylinder(d = d, h = thickness + 2, center = true);
    }
}
