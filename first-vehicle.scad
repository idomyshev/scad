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
mid_gear_t = 0.421;
mid_gear_x = mid_gear_t * wheel_dist;
mid_gear_y = -mid_gear_t * pitch * 3;

my_body_color = [119/255, 136/255, 153/255, 0.9];
my_cutter_color = [1, 0, 0, 0.5];
my_gear_color = [0.55, 0.45, 0.35, 1];  // bronze/copper for gear

include <involute_gear.scad>

// --- Helper modules ---
module hole() {
    cylinder(d = hole_d, h = thickness + 2, center = true);
}

// Any diameter: teeth = diameter/module so tooth size stays same and gears mesh
module make_gear(diameter) { 
    teeth = max(8, round(diameter / gear_module));
    involute_gear(teeth * gear_module, teeth, thickness, gear_pressure_angle, involute_facets = 0, bore_diameter = false, cross_axle = true);
}

// --- Main part module ---
module side_plate() {
    difference() {
        color(my_body_color)
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
        color(my_cutter_color)   
        translate([0, -182, 0])
            cylinder(d = 330, h = thickness + 2, center = true);

        // Holes
        color(my_cutter_color) {
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
color(my_gear_color)
translate([0, 0, thickness])
    make_gear(24);

// Middle gears on line center–wheel; position by mid_gear_t (0..1)
color([0.55, 0.45, 1, 1])
for (s = [1, -1]) {
    translate([s * mid_gear_x, mid_gear_y, thickness])
        rotate([0, 0, s * 3])
            make_gear(40);
}

color([0.55, 0.45, 0.35, 1])
for (s = [1, -1]) {
    translate([s * wheel_dist, -pitch*3, thickness])
        rotate([0, 0, s * 0.65])
            make_gear(50);
}

// Second side plate (offset along Z so they face each other)
// 40mm is approximate spacing between side plates for motor width
// translate([0, 0, 40]) 
//     side_plate();