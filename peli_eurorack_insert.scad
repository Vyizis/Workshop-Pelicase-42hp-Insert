// Peli-style case insert for 42HP / 3U Eurorack
// Case marked: MG 235x165x45 (base)
// Outer profile shrinks at the floor to clear the case's floor-to-wall fillet
// (+ light draft). Print foot-down on A1 Mini; two halves.
//
// OpenSCAD Customizer:
//   part = "left" | "right" | "both" | "assembled"

/* [Which part] */
part = "left"; // ["left", "right", "both", "assembled"]

/* [Case interior] */
case_l = 235;
case_w = 165;
case_h = 45;
case_corner_r = 11;    // confirmed via corner fit test
fit_clearance = 2.5;   // was 1.0 — print was tight and bowed in the case
// Floor-to-wall fillet inside the case (confirmed via corner fit test)
base_fillet_r = 6;
// Extra inset at the very bottom for mould draft / print tolerance
draft_inset = 1.0;

/* [Frame] */
wall = 2.4;
foot_t = 2.0;
foot_w = 8.0;
deck_t = 2.8;
insert_h = 42;
rail_h = 8.0;
// Rail is asymmetric about the screw/nut centre (hole line):
// less material toward the bay (PCB clearance), more toward the panel edge.
rail_bay = 4.3;            // from slot centre toward module bay (~1.35mm nut wall)
rail_outer = 6.0;          // from slot centre toward panel edge
spine_w = 3.2;

/* [Eurorack — Doepfer / standard 3U] */
hp = 5.08;
hp_count = 42;
panel_l = hp_count * hp;   // 213.36 — nominal 42HP
panel_h = 128.5;           // standard 3U panel height
hole_inset = 3.0;          // hole centre from panel top/bottom edge
panel_t = 1.6;
module_drop = 0.5;         // seat panel this much below deck
panel_clear = 0.55;
panel_corner_r = 1.0;

/* [M3 square nut track] */
nut_cavity_w = 5.9;
nut_cavity_h = 2.6;
screw_slot = 3.4;          // M3 clearance — ~1.25mm nut overlap each side
slot_lip = 1.2;            // solid retainer over the nut


/* [Split join — filament / dowel pins] */
pin_d = 2.0;
pin_clear = 0.15;
join_boss_x = 16;
join_boss_h = 10;

/* [Quality] */
$fn = 64;

// ---------------------------------------------------------------------------
// Derived
// ---------------------------------------------------------------------------
outer_l = case_l - fit_clearance;
outer_w = case_w - fit_clearance;
outer_r = max(1, case_corner_r - fit_clearance / 2);

// Bottom footprint clears fillet + draft (usable floor is smaller than rim)
bottom_inset = base_fillet_r + draft_inset;
bottom_l = outer_l - 2 * bottom_inset;
bottom_w = outer_w - 2 * bottom_inset;
bottom_r = max(1, outer_r - bottom_inset);

rail_span = panel_l;                         // full 42HP
rail_hole_cc = panel_h - 2 * hole_inset;     // 122.5
rail_y0 = -rail_hole_cc / 2;
rail_y1 =  rail_hole_cc / 2;
rail_top_z = insert_h - panel_t - module_drop;
rail_z = rail_top_z - rail_h;
rail_len = rail_span + 2 * wall;
rail_w = rail_bay + rail_outer;              // total rail width

panel_pocket_l = panel_l + 2 * panel_clear;
panel_pocket_w = panel_h + 2 * panel_clear;

wall_inner_h = insert_h - deck_t;

echo(str("Rim outer: ", outer_l, " x ", outer_w, " R", outer_r));
echo(str("Floor outer: ", bottom_l, " x ", bottom_w, " R", bottom_r,
         " (fillet ", base_fillet_r, " + draft ", draft_inset, ")"));
echo(str("42HP x 3U panel: ", panel_l, " x ", panel_h));
echo(str("Panel pocket: ", panel_pocket_l, " x ", panel_pocket_w));
echo(str("Rail hole CC: ", rail_hole_cc, " (holes ", hole_inset, " from edge)"));
echo(str("Rail section: bay ", rail_bay, " / outer ", rail_outer,
         " (nut side wall ", rail_bay - nut_cavity_w / 2, " mm)"));
echo(str("Module drop: ", module_drop, " mm, slot lip: ", slot_lip, " mm"));
echo(str("Half length at rim: ", outer_l / 2, " mm"));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
module rounded_rect(size, r) {
    l = size[0];
    w = size[1];
    rr = min(r, l / 2 - 0.01, w / 2 - 0.01);
    offset(r = rr)
        square([l - 2 * rr, w - 2 * rr], center = true);
}

module frame_ring_2d(outer_size, inner_shrink, r) {
    difference() {
        rounded_rect(outer_size, r);
        rounded_rect(
            [outer_size[0] - 2 * inner_shrink, outer_size[1] - 2 * inner_shrink],
            max(0.4, r - inner_shrink)
        );
    }
}

// Cross-section of the case-fit outline at height z (0 = floor).
// Blends from reduced floor size up to full rim size over base_fillet_r.
module fit_profile_2d(z, inset = 0) {
    t = base_fillet_r <= 0 ? 1 : min(1, max(0, z) / base_fillet_r);
    l = bottom_l + t * (outer_l - bottom_l) - 2 * inset;
    w = bottom_w + t * (outer_w - bottom_w) - 2 * inset;
    r = max(0.4, bottom_r + t * (outer_r - bottom_r) - inset);
    rounded_rect([max(l, 1), max(w, 1)], r);
}

// Solid loft that follows the case fillet (small at floor → full at rim)
module fit_loft_solid(h, inset = 0) {
    hull() {
        translate([0, 0, 0])
            linear_extrude(height = 0.02)
                fit_profile_2d(0, inset);
        translate([0, 0, base_fillet_r])
            linear_extrude(height = 0.02)
                fit_profile_2d(base_fillet_r, inset);
        if (h > base_fillet_r + 0.05)
            translate([0, 0, h])
                linear_extrude(height = 0.02)
                    fit_profile_2d(base_fillet_r, inset);
    }
}

module t_slot_rail(length, bay_dir) {
    // bay_dir: sign toward the module bay (+1 or -1 along Y)
    // Slot/nut stay on the hole centreline. Body is asymmetric:
    // rail_bay toward the bay (PCB clearance), rail_outer toward the panel edge.
    nut_z = rail_h - slot_lip - nut_cavity_h / 2;
    y_bay = bay_dir * rail_bay;
    y_outer = -bay_dir * rail_outer;
    y_min = min(y_bay, y_outer);
    y_max = max(y_bay, y_outer);
    body_w = y_max - y_min;
    body_cy = (y_min + y_max) / 2;

    difference() {
        translate([0, body_cy, rail_h / 2])
            cube([length, body_w, rail_h], center = true);

        // Nut gallery — centred on the hole/slot line (Y=0 local)
        translate([0, 0, nut_z])
            cube([length - 2 * wall, nut_cavity_w, nut_cavity_h + 0.05], center = true);

        // Screw slot through top lip
        translate([0, 0, rail_h - slot_lip / 2])
            cube([length - 2 * wall, screw_slot, slot_lip + 0.2], center = true);

        // End-loading ports for square nuts
        for (sx = [-1, 1])
            translate([sx * (length / 2 - wall / 2), 0, nut_z])
                cube([wall + 0.4, nut_cavity_w, nut_cavity_h + 0.05], center = true);
    }
}

module top_deck() {
    // Frame only — never build a full plate over the bay (avoids a leftover skin)
    translate([0, 0, insert_h - deck_t])
        linear_extrude(height = deck_t)
            difference() {
                rounded_rect([outer_l, outer_w], outer_r);
                rounded_rect([panel_pocket_l, panel_pocket_w], panel_corner_r);
            }
}

// Solid outer rim: full case-fit loft minus the panel pocket.
// Only the middle-front access pocket stays open (no hollow gallery cells).
module solid_outer_rim() {
    win_z = base_fillet_r + 2;
    win_h = max(8, wall_inner_h - win_z - 2);
    front_pocket_w = 40;
    front_depth = (outer_w - panel_pocket_w) / 2 + wall;

    difference() {
        fit_loft_solid(wall_inner_h, 0);

        // Punch the module bay fully through the rim (overlap past both ends)
        translate([0, 0, -1])
            linear_extrude(height = wall_inner_h + 2)
                rounded_rect([panel_pocket_l, panel_pocket_w], panel_corner_r);

        // Middle-front access pocket only
        translate([0, -(outer_w / 2 - front_depth / 2), win_z + win_h / 2])
            cube([front_pocket_w, front_depth + 1, win_h], center = true);
    }
}

module rail_spine(y) {
    translate([0, y, rail_z / 2])
        cube([rail_len, spine_w, rail_z], center = true);
}

module pin_holes() {
    d = pin_d + pin_clear;
    z = join_boss_h / 2;
    for (y = [rail_y0, rail_y1])
        translate([0, y, z])
            rotate([0, 90, 0])
                cylinder(d = d, h = join_boss_x + 2, center = true);
}

module insert_body() {
    difference() {
        union() {
            // Foot follows the reduced floor outline (sits inside the fillet)
            linear_extrude(height = foot_t)
                frame_ring_2d([bottom_l, bottom_w], foot_w, bottom_r);

            // Solid outer rim (only middle-front access pocket left open)
            solid_outer_rim();

            top_deck();

            translate([0, rail_y0, rail_z]) t_slot_rail(rail_len, +1); // bay toward +Y
            translate([0, rail_y1, rail_z]) t_slot_rail(rail_len, -1); // bay toward -Y

            rail_spine(rail_y0);
            rail_spine(rail_y1);

            // End ties between rails
            for (sx = [-1, 1])
                translate([sx * (rail_span / 2 + wall / 2), 0, rail_z + rail_h / 2])
                    cube([wall, rail_hole_cc + rail_w, rail_h], center = true);

            for (y = [rail_y0, rail_y1])
                translate([0, y, foot_t / 2])
                    cube([rail_len, spine_w, foot_t], center = true);

            for (x = [-rail_span * 0.35, -rail_span * 0.12, rail_span * 0.12, rail_span * 0.35])
                translate([x, 0, foot_t / 2])
                    cube([spine_w, rail_hole_cc, foot_t], center = true);

            for (y = [rail_y0, rail_y1])
                translate([0, y, join_boss_h / 2])
                    cube([join_boss_x, rail_w, join_boss_h], center = true);

            translate([0, 0, foot_t / 2])
                cube([join_boss_x, rail_hole_cc, foot_t], center = true);
        }

        pin_holes();
    }
}

// ---------------------------------------------------------------------------
// Split (cut at X=0)
// ---------------------------------------------------------------------------
module half_body(which) {
    intersection() {
        insert_body();
        translate([which == "left" ? -outer_l / 2 : outer_l / 2, 0, insert_h / 2])
            cube([outer_l + 0.02, outer_w + 20, insert_h + 20], center = true);
    }
}

module printable(which) {
    translate([which == "left" ? outer_l / 4 : -outer_l / 4, 0, 0])
        half_body(which);
}

if (part == "left") {
    printable("left");
} else if (part == "right") {
    printable("right");
} else if (part == "both") {
    translate([0, -(outer_w / 2 + 10), 0]) printable("left");
    translate([0,  (outer_w / 2 + 10), 0]) printable("right");
} else {
    color("#4a6d8c") half_body("left");
    color("#8ca8c0") half_body("right");
}
