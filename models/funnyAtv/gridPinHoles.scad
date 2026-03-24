// Pin holes on a grid inside the axis-aligned bounding box of the sideFrame hull (three disks).
// Axis parallel to Z like legoAxisHole.
// Skips points too close to axle centers; skips points too close to the part edge (outer hull
// polyline + inner edge of the bottom opening cylinder — same geometry as sideFrame).

grid_pin_pitch = 8;
min_axle_clearance_for_pin_grid = 8;

// Bottom opening in sideFrame (XY), material removed for dist < r_cut
function _bottom_cut_center_() = [0, -182];
function _bottom_cut_radius_() = 330 / 2;

function _frame_disk_centers_radii_() =
    let(c1 = [0, 0], r1 = 15)
    let(c2 = [-wheel_dist, -pitch * 3], r2 = 8)
    let(c3 = fin_gear_xy, r3 = 8)
    [c1, r1, c2, r2, c3, r3];

function _hull_support_disk_(t, c, r) = c + r * [cos(t), sin(t)];

function _hull_support_point_(t, c1, r1, c2, r2, c3, r3) =
    let(u = [cos(t), sin(t)])
    let(s1 = c1[0] * u[0] + c1[1] * u[1] + r1)
    let(s2 = c2[0] * u[0] + c2[1] * u[1] + r2)
    let(s3 = c3[0] * u[0] + c3[1] * u[1] + r3)
    s1 >= s2 && s1 >= s3 ? _hull_support_disk_(t, c1, r1)
    : s2 >= s3 ? _hull_support_disk_(t, c2, r2)
    : _hull_support_disk_(t, c3, r3);

// Dense CCW outline of the convex hull of the three disks (matches hull() silhouette).
function _hull_outline_poly_(step = 0.25) =
    let(dr = _frame_disk_centers_radii_())
    let(c1 = dr[0], r1 = dr[1], c2 = dr[2], r2 = dr[3], c3 = dr[4], r3 = dr[5])
    [for (a = [0 : step : 359.99]) _hull_support_point_(a, c1, r1, c2, r2, c3, r3)];

function _cross2_(a, b) = a[0] * b[1] - a[1] * b[0];

function _point_in_convex_ccw_(p, poly, i = 0) =
    i >= len(poly) ? true
    : let(j = (i + 1) % len(poly))
      let(e = poly[j] - poly[i])
      _cross2_(e, p - poly[i]) >= -1e-3
      ? _point_in_convex_ccw_(p, poly, i + 1)
      : false;

function _dist_point_seg_2d_(p, a, b) =
    let(ab = b - a)
    let(l2 = ab[0] * ab[0] + ab[1] * ab[1] + 1e-12)
    let(ap = p - a)
    let(t = max(0, min(1, (ap[0] * ab[0] + ap[1] * ab[1]) / l2)))
    norm(p - (a + t * ab));

function _min_dist_closed_polyline_(p, pts, i = 0) =
    i >= len(pts) ? 1e9
    : min(
        _dist_point_seg_2d_(p, pts[i], pts[(i + 1) % len(pts)]),
        _min_dist_closed_polyline_(p, pts, i + 1)
      );

function _hull_bbox_side_frame_() =
    let(c1 = [0, 0], r1 = 15)
    let(c2 = [-wheel_dist, -pitch * 3], r2 = 8)
    let(c3 = fin_gear_xy, r3 = 8)
    let(xmin = min(c1[0] - r1, min(c2[0] - r2, c3[0] - r3)))
    let(xmax = max(c1[0] + r1, max(c2[0] + r2, c3[0] + r3)))
    let(ymin = min(c1[1] - r1, min(c2[1] - r2, c3[1] - r3)))
    let(ymax = max(c1[1] + r1, max(c2[1] + r2, c3[1] + r3)))
    [xmin, xmax, ymin, ymax];

function _axle_centers_side_frame_() = concat(
        [[0, 0]],
        [[pitch, 0], [-pitch, 0], [0, pitch], [0, -pitch]],
        [for (s = [-1, 1]) [s * mid_gear_xy[0], mid_gear_xy[1]]],
        [for (s = [-1, 1]) [s * fin_gear_xy[0], fin_gear_xy[1]]]
    );

function _min_dist_to_points_(p, pts, i = 0) =
    i >= len(pts) ? 1e9
    : min(norm(p - pts[i]), _min_dist_to_points_(p, pts, i + 1));

// Distance from p to the bottom cut circle (for p outside the removed disk: norm(p-c) >= r_cut).
function _clearance_from_bottom_cut_edge_(p) =
    let(c = _bottom_cut_center_())
    let(r = _bottom_cut_radius_())
    norm(p - c) - r;

function _pin_center_allowed_(p, hull_poly, axles) =
    let(e = pin_hole_edge_clearance)
    _point_in_convex_ccw_(p, hull_poly)
    && _min_dist_closed_polyline_(p, hull_poly) >= e
    && _clearance_from_bottom_cut_edge_(p) >= e
    && _min_dist_to_points_(p, axles) >= min_axle_clearance_for_pin_grid;

// Grid over bbox shrunk by edge clearance; cell centers are centered on the hull AABB center
// (same as frame center when the outline is symmetric in XY).
function grid_pin_hole_positions() =
    let(b = _hull_bbox_side_frame_())
    let(e = pin_hole_edge_clearance)
    let(xmin = b[0] + e, xmax = b[1] - e, ymin = b[2] + e, ymax = b[3] - e)
    let(cx = (xmin + xmax) / 2)
    let(cy = (ymin + ymax) / 2)
    let(wx = xmax - xmin)
    let(wy = ymax - ymin)
    let(nx = floor(wx / grid_pin_pitch))
    let(ny = floor(wy / grid_pin_pitch))
    let(x0 = cx - (nx - 1) * grid_pin_pitch / 2)
    let(y0 = cy - (ny - 1) * grid_pin_pitch / 2)
    let(hull_poly = _hull_outline_poly_())
    let(axles = _axle_centers_side_frame_())
    [
        for (kx = [0 : max(0, nx - 1)])
            for (ky = [0 : max(0, ny - 1)])
                let(x = x0 + kx * grid_pin_pitch)
                let(y = y0 + ky * grid_pin_pitch)
                let(p = [x, y])
                if (_pin_center_allowed_(p, hull_poly, axles))
                    p
    ];

module legoPinHole() {
    cylinder(d = pin_hole, h = thickness + 2, center = true);
}
