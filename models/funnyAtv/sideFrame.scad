// Боковина рамы.
module sideFrame() {
    difference() {
        color(getColor("body"))
        union() {
            // Плечи
            hull() {
                cylinder(d = 30, h = thickness, center = true);
                translate([-wheel_dist, -pitch*3, 0]) 
                    cylinder(d = 16, h = thickness, center = true);
                translate([fin_gear_xy[0], fin_gear_xy[1], 0])  
                    cylinder(d = 16, h = thickness, center = true);
            }
        }
        
        // Большая окружность снизу для вырезания боковины
        color(getColor("cutter"))
        translate([0, -182, 0])
            cylinder(d = 330, h = thickness + 2, center = true);

        for (s = [-1, 1]) {
            // Отверстия под валы средних шестеренок
            translate([s * mid_gear_xy[0], mid_gear_xy[1], 0]) legoAxisHole();  
            // Отверстия под валы нижних шестеренок
            translate([s * fin_gear_xy[0], fin_gear_xy[1], 0]) legoAxisHole();
        }

        // Крепление мотора: 4 отверстия - квадрат 16*16мм
        for (pos = [[pitch, 0], [-pitch, 0], [0, pitch], [0, -pitch]]) {
            translate([pos[0], pos[1], 0]) legoAxisHole();
        }

        // Центральное отверстие под вал центральной шестерни
        color(getColor("cutter")) {
            legoAxisHole();
        }
    }
}