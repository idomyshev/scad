// Involute spur gear library (ISO)
// Use: include <involute_gear.scad>
// Public: module involute_gear(pitch_diameter, teeth, gear_thickness, pressure_angle=20, involute_facets=0)

// Involute angle (degrees) at given radius
function involute_intersect_angle(base_r, r) = sqrt(pow(r / base_r, 2) - 1) * 180 / PI;

// Involute point [x,y] for base radius and angle in degrees
function involute(base_r, angle_deg) = [
    base_r * (cos(angle_deg) + (angle_deg * PI / 180) * sin(angle_deg)),
    base_r * (sin(angle_deg) - (angle_deg * PI / 180) * cos(angle_deg))
];

function _rotate_pt(angle_deg, p) = [
    cos(angle_deg) * p[0] + sin(angle_deg) * p[1],
    cos(angle_deg) * p[1] - sin(angle_deg) * p[0]
];

function _mirror_pt(p) = [p[0], -p[1]];

module _involute_tooth_2d(pitch_r, root_r, base_r, outer_r, half_thick_angle, facets) {
    min_r = max(base_r, root_r);
    pitch_pt = involute(base_r, involute_intersect_angle(base_r, pitch_r));
    pitch_angle = atan2(pitch_pt[1], pitch_pt[0]);
    centre_angle = pitch_angle + half_thick_angle;
    start_angle = involute_intersect_angle(base_r, min_r);
    stop_angle = involute_intersect_angle(base_r, outer_r);

    for (i = [1 : facets]) {
        t1 = (i - 1) / facets;
        t2 = i / facets;
        pt1 = involute(base_r, start_angle + (stop_angle - start_angle) * t1);
        pt2 = involute(base_r, start_angle + (stop_angle - start_angle) * t2);
        s1a = _rotate_pt(centre_angle, pt1);
        s1b = _rotate_pt(centre_angle, pt2);
        s2a = _mirror_pt(s1a);
        s2b = _mirror_pt(s1b);
        polygon(points = [[0, 0], s1a, s1b, s2b, s2a], paths = [[0, 1, 2, 3, 4, 0]]);
    }
}

module _gear_shape_2d(teeth, pitch_r, root_r, base_r, outer_r, half_thick_angle, facets) {
    union() {
        rotate(half_thick_angle) circle(r = root_r, $fn = teeth * 2);
        for (i = [1 : teeth]) {
            rotate([0, 0, i * 360 / teeth])
                _involute_tooth_2d(pitch_r, root_r, base_r, outer_r, half_thick_angle, facets);
        }
    }
}

// 2D cross (plus) for LEGO-style axle; circumscribed diameter and arm width in mm
module _cross_2d(cross_diameter, arm_width) {
    half_len = cross_diameter / 2;
    half_w = arm_width / 2;
    union() {
        polygon(points = [[-half_w, -half_len], [half_w, -half_len], [half_w, half_len], [-half_w, half_len]]);
        polygon(points = [[-half_len, -half_w], [half_len, -half_w], [half_len, half_w], [-half_len, half_w]]);
    }
}

// Public module: draw an involute spur gear (ISO).
// pitch_diameter = diameter of pitch circle (mm)
// teeth = number of teeth
// gear_thickness = height of gear (mm)
// pressure_angle = in degrees (default 20)
// involute_facets = segments per tooth flank (0 = use $fn/4)
// bore_diameter = diameter of central cylindrical hole (mm). false, 0 or undef = no bore
// cross_axle = central cross cutout for LEGO-style axle: false/undef = none; true = default LEGO size;
//   number = circumscribed diameter (mm); [diameter, arm_width] = full spec. When set, overrides bore_diameter in center
module involute_gear(pitch_diameter, teeth, gear_thickness, pressure_angle = 20, involute_facets = 0, bore_diameter = undef, cross_axle = false) {
    pitch_r = pitch_diameter / 2;
    base_r = pitch_r * cos(pressure_angle);
    module_val = pitch_diameter / teeth;
    addendum = module_val;
    dedendum = 1.25 * module_val;   // includes standard clearance 0.25*module
    outer_r = pitch_r + addendum;
    root_r = pitch_r - dedendum;
    half_thick_angle = (360 / teeth) / 4;
    facets = (involute_facets > 0) ? involute_facets : max(4, $fn / 4);

    use_bore = (bore_diameter != undef && bore_diameter != false && bore_diameter > 0);
    use_cross = (cross_axle != undef && cross_axle != false &&
        (cross_axle == true || (cross_axle > 0) || (is_list(cross_axle) && len(cross_axle) >= 1)));

    cross_d = (cross_axle == true) ? 4.85 : (is_list(cross_axle) ? cross_axle[0] : cross_axle);
    cross_w = (is_list(cross_axle) && len(cross_axle) >= 2) ? cross_axle[1] : 1.9;

    difference() {
        linear_extrude(gear_thickness, center = true)
            _gear_shape_2d(teeth, pitch_r, root_r, base_r, outer_r, half_thick_angle, facets);
        if (use_bore && !use_cross)
            cylinder(d = bore_diameter, h = gear_thickness + 2, center = true);
        if (use_cross)
            linear_extrude(gear_thickness + 2, center = true)
                _cross_2d(cross_d, cross_w);
    }
}
