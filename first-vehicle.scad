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

// Polar → XY: angle in degrees (0 = +X, increases CCW when looking from +Z; same as rotate([0,0,…])).
// distance is radius in model units (e.g. mm). Returns [x, y] for translate([p[0], p[1], z]).
function xy_from_angle_distance(angle_deg, distance) =
    [distance * cos(angle_deg), distance * sin(angle_deg)];

// --- Gear spacing (ideal mesh, same module on both gears) ---
// Nominal center distance for standard involute spur gears: pitch (reference) circles are tangent.
// That is the textbook "no backlash" distance; real prints often need a tiny extra gap (material, FDM).
//
// IMPORTANT: arguments must be PITCH diameters d = module * teeth — the same meaning as the first
// argument to involute_gear() / your make_gear() (teeth * gear_module). NOT outer (tip) diameter.
// If d1 and d2 are already pitch diameters, module does NOT go into the formula again — size is in d.
function gear_mesh_center_distance(pitch_diameter_1, pitch_diameter_2) =
    (pitch_diameter_1 + pitch_diameter_2) / 2;

// Pitch diameter from tooth count and module (same convention as make_gear: z = max(8, round(teeth))).
function gear_pitch_diameter(teeth, module_) = max(8, round(teeth)) * module_;

// Same center distance, but from tooth counts + shared module (both gears use this module).
function gear_mesh_center_distance_teeth(teeth_1, teeth_2, module_) =
    gear_mesh_center_distance(
        gear_pitch_diameter(teeth_1, module_),
        gear_pitch_diameter(teeth_2, module_)
    );

// Aliases (older names)
function gear_center_distance_pitch_diameter(pitch_diameter_1, pitch_diameter_2) =
    gear_mesh_center_distance(pitch_diameter_1, pitch_diameter_2);

function gear_center_distance_teeth(teeth_1, teeth_2, module_) =
    gear_mesh_center_distance_teeth(teeth_1, teeth_2, module_);

// Same as gear_mesh_center_distance_teeth(z1, z2, gear_module) — for this file’s shared module only.
function gear_mesh_spacing_teeth(z1, z2) = gear_mesh_center_distance_teeth(z1, z2, gear_module);

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

// First side plate
side_plate();

// Gear opposite the center hole, touching the side plate on its face (same XY, offset by thickness along Z)
color(color_named("gear_bronze"))
translate([0, 0, thickness])
    make_gear(12);

center_mid_dist = gear_mesh_spacing_teeth(12, 20);
mid_gear_xy = xy_from_angle_distance(-18, center_mid_dist);
paired_mirrored_gears(20, -3, mid_gear_xy[0], mid_gear_xy[1], color_named("gear_middle_pair"));

mid_fin_dist = gear_mesh_spacing_teeth(20, 24);
fin_gear_xy = xy_from_angle_distance(-18, center_mid_dist + mid_fin_dist);
paired_mirrored_gears(24, 7, fin_gear_xy[0], fin_gear_xy[1], color_named("gear_bronze"));
