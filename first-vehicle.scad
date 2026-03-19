// Settings
$fn = 160;
thickness = 8;
hole_d = 4.9;
hole_d_tight = hole_d - 0.15;
pitch = 8; 
gear_dist = pitch * 3; 
wheel_dist = pitch * 9; 

// Same module for all gears so they can mesh
gear_module = 2;
gear_pressure_angle = 20;

// Middle gear position on line center(0,0)–wheel(wheel_dist, -pitch*3): 0 = at center, 1 = at wheel
mid_gear_t = 0.410;
mid_gear_x = mid_gear_t * wheel_dist;
mid_gear_y = -mid_gear_t * pitch * 3;
// Middle gear pair: one knob; left/right rotate opposite (s * angle) so both stay meshable with neighbors
mid_gear_phase_z = 15.6;

// Named RGBA colors (OpenSCAD has no object/map; use lookup via color_named("key"))
COLORS = [
    ["body", [119 / 255, 136 / 255, 153 / 255, 0.9]],
    ["cutter", [1, 0, 0, 0.5]],
    ["gear_bronze", [0.55, 0.45, 0.35, 1]],
    ["gear_middle_pair", [0.55, 0.45, 1, 1]],
];

function _color_named(name, entries, i = 0) =
    i >= len(entries)
        ? [1, 0, 1, 1]  // unknown key: magenta
        : entries[i][0] == name
            ? entries[i][1]
            : _color_named(name, entries, i + 1);

function color_named(name) = _color_named(name, COLORS);

include <involute_gear.scad>

// --- Helper modules ---
module hole() {
    cylinder(d = hole_d, h = thickness + 2, center = true);
}

// Integer tooth count; pitch diameter = teeth * gear_module (same module everywhere so gears mesh)
module make_gear(teeth) {
    z = max(8, round(teeth));
    involute_gear(z * gear_module, z, thickness, gear_pressure_angle, involute_facets = 0, bore_diameter = false, cross_axle = true);
}

// Two identical gears on ±X from the Y axis, opposite Z rotation for meshing (uses global thickness).
// Odd tooth count has no 180° rotational symmetry on the tooth lattice, so ±phase alone looks
// asymmetric left vs right; add 180° on the s = -1 side (negative X) to mirror the pattern visually.
module paired_mirrored_gears(teeth, phase_z, gx, gy, gear_color) {
    z = max(8, round(teeth));
    odd_z_mirror = (z % 2 == 1) ? 1 : 0;
    color(gear_color)
    for (s = [1, -1]) {
        extra_z = odd_z_mirror * ((s == -1) ? 180 : 0);
        translate([s * gx, gy, thickness])
            rotate([0, 0, s * phase_z + extra_z])
                make_gear(teeth);
    }
}

// --- Main part module ---
module side_plate() {
    difference() {
        color(color_named("body"))
        union() {
            // Arms to wheels
            hull() {
                cylinder(d = 30, h = thickness, center = true);
                translate([-wheel_dist, -pitch*3, 0]) 
                    cylinder(d = 16, h = thickness, center = true);
                translate([wheel_dist, -pitch*3, 0])  
                    cylinder(d = 16, h = thickness, center = true);
            }
        }
        
        // Lower arc cutout
        color(color_named("cutter"))
        translate([0, -182, 0])
            cylinder(d = 330, h = thickness + 2, center = true);

        // Holes
        color(color_named("cutter")) {
            // Center (motor shaft)
            hole();

            // Motor mount (16x16mm square)
            for (pos = [[pitch, 0], [-pitch, 0], [0, pitch], [0, -pitch]]) {
                translate([pos[0], pos[1], 0]) hole();
            }

            // Middle and wheel axle holes (middle position from mid_gear_t)
            for (s = [-1, 1]) {
                translate([s * mid_gear_x, mid_gear_y, 0]) hole();
                translate([s * wheel_dist, -pitch*3, 0]) hole();
            }

            // Cross beam mounts
            // translate([-wheel_dist/2, 10, 0]) hole();
            // translate([wheel_dist/2, 10, 0])  hole();
        }
    }
}

// --- Render parts ---

// First side plate
side_plate();

// Gear opposite the center hole, touching the side plate on its face (same XY, offset by thickness along Z)
color(color_named("gear_bronze"))
translate([0, 0, thickness])
    make_gear(12);

// Middle gears on line center–wheel; position by mid_gear_t (0..1)
paired_mirrored_gears(19, mid_gear_phase_z, mid_gear_x, mid_gear_y, color_named("gear_middle_pair"));

color(color_named("gear_bronze"))
for (s = [1, -1]) {
    translate([s * wheel_dist, -pitch*3, thickness])
        rotate([0, 0, s * 0.65])
            make_gear(24);
}

// Second side plate (offset along Z so they face each other)
// 40mm is approximate spacing between side plates for motor width
// translate([0, 0, 40]) 
//     side_plate();