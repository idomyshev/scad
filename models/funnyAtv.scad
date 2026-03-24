// Settings
$fn = 160;
thickness = 8;
hole_d = 4.9;
hole_d_tight = hole_d - 0.15;
// Pin holes (grid on side frame); separate from hole_d_tight for clarity
pin_hole = hole_d - 0.15;
// Minimum distance from pin center to the part outline (outer hull + bottom cut edge), mm
pin_hole_edge_clearance = 4.2;
pitch = 8; 
gear_dist = pitch * 3; 
wheel_dist = pitch * 9; 

// Same module for all gears so they can mesh
gear_module = 2;
gear_pressure_angle = 20;


// Middle gear pair: one knob; left/right rotate opposite (s * angle) so both stay meshable with neighbors
mid_gear_phase_z = 15.6; 

// Polar → XY: angle in degrees (0 = +X, increases CCW when looking from +Z; same as rotate([0,0,…])).
// distance is radius in model units (e.g. mm). Returns [x, y] for translate([p[0], p[1], z]).
function xy_from_angle_distance(angle_deg, distance) =
    [distance * cos(angle_deg), distance * sin(angle_deg)];

// --- Gear spacing (ideal mesh, same module on both gears) ---
// Nominal center distance for standard involute spur gears: pitch (reference) circles are tangent.
// That is the textbook "no backlash" distance; real prints often need a tiny extra gap (material, FDM).
//
// IMPORTANT: arguments must be PITCH diameters d = module * teeth — the same meaning as the first
// argument to drawGear() / your drawGearByTeeth() (teeth * gear_module). NOT outer (tip) diameter.
// If d1 and d2 are already pitch diameters, module does NOT go into the formula again — size is in d.
function gear_mesh_center_distance(pitch_diameter_1, pitch_diameter_2) =
    (pitch_diameter_1 + pitch_diameter_2) / 2;

// Pitch diameter from tooth count and module (same convention as drawGearByTeeth: z = max(8, round(teeth))).
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

// Same as gear_mesh_center_distance_teeth(z1, z2, gear_module) — for this file’s shared module only.
function gear_mesh_spacing_teeth(z1, z2) = gear_mesh_center_distance_teeth(z1, z2, gear_module);

// Paths relative to this file (models/funnyAtv.scad), not project root — use "..." not <...>
include <../lib/core/gears/drawGear.scad>

// --- Объявляем глобальные переменные ---
// Расстояние между центрами центральной и средних шестерен
center_mid_dist = gear_mesh_spacing_teeth(12, 20);
// Расстояние между центрами средних и нижних шестерен
mid_fin_dist = gear_mesh_spacing_teeth(20, 24);
// Позиции средних и нижних шестерен
mid_gear_xy = xy_from_angle_distance(-18, center_mid_dist);
fin_gear_xy = xy_from_angle_distance(-18, center_mid_dist + mid_fin_dist);

include <funnyAtv/sideFrame.scad>
include <funnyAtv/sideFrameGears.scad>
include <../lib/core/gears/mirroredGears.scad>
include <../lib/core/gears/drawGearByTeeth.scad>
include <../lib/core/lego/legoAxisHole.scad>
include <../lib/utils/getColor.scad>

// Build side frame (uses globals above + legoAxisHole(), getColor, thickness, pitch, wheel_dist)
sideFrame();
// Строим шестерни
sideFrameGears();







