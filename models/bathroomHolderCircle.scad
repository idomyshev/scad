include <bathroomHolderCircle/base_cylinder.scad>
include <bathroomHolderCircle/cutout_cylinder.scad>
include <bathroomHolderCircle/pin_cutouts.scad>

$fn = 64; // more then enought to print on BambuLab A1 mini

difference() {
    base_cylinder();
    cutout_cylinder();
    pin_cutouts();
}
