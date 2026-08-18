// Peli-style case insert for 42HP / 3U Eurorack
// Case marked: MG 235x165x45 (base)
// Outer profile shrinks at the floor to clear the case's floor-to-wall fillet.
// Print deck-down (top surface on the bed) on A1 Mini; two halves.
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
deck_t = 2.8;
insert_h = 42;
rail_h = 8.0;
// Rail is asymmetric about the screw/nut centre (hole line):
// less material toward the bay (PCB clearance), more toward the panel edge.
rail_bay = 4.3;            // from slot centre toward module bay (~1.35mm nut wall)
rail_outer = 6.0;          // from slot centre toward panel edge

/* [Eurorack — Doepfer / standard 3U] */
hp = 5.08;
hp_count = 42;
panel_l = hp_count * hp;   // 213.36 — nominal 42HP
panel_h = 128.5;           // standard 3U panel height
hole_inset = 3.0;          // hole centre from panel top/bottom edge
panel_t = 1.6;
module_drop = 0;           // 0 = panel flush with deck; pocket depth = panel_t
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
join_boss_y = 8;
join_boss_h = 10;          // requested height; clamped below so bosses never poke through the deck
// Bosses live in the outer rim band (outboard of the panel pocket),
// never on the rail centreline — that blocked nut loading at the split.

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
echo(str("Panel pocket depth (surface → rail top): ", insert_h - rail_top_z, " mm (panel_t ", panel_t, ")"));
echo(str("Half length at rim: ", outer_l / 2, " mm"));

// Join bosses sit in the rim band outboard of the panel pocket (clear of T-slots)
join_boss_ys = [
    -(panel_pocket_w / 2 + join_boss_y / 2 + 0.2),
     (panel_pocket_w / 2 + join_boss_y / 2 + 0.2)
];
// Never let bosses protrude above the deck (was +0.4mm when module_drop=0)
join_boss_h_eff = min(join_boss_h, insert_h - rail_z);

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

// Outer frame: fillet loft + walls + deck as one solid (no lip on short ends).
// Front access stays mid-height — same as before the lip tweaks.
module solid_outer_rim() {
    win_z = base_fillet_r + 2;
    win_h = max(8, wall_inner_h - win_z - 2);
    front_pocket_w = 40;
    front_depth = (outer_w - panel_pocket_w) / 2 + wall;

    difference() {
        union() {
            fit_loft_solid(base_fillet_r, 0);
            translate([0, 0, base_fillet_r])
                linear_extrude(height = insert_h - base_fillet_r)
                    rounded_rect([outer_l, outer_w], outer_r);
        }

        // Module bay through the full height (rim + deck)
        translate([0, 0, -1])
            linear_extrude(height = insert_h + 2)
                rounded_rect([panel_pocket_l, panel_pocket_w], panel_corner_r);

        // Middle-front access pocket only (unchanged)
        translate([0, -(outer_w / 2 - front_depth / 2), win_z + win_h / 2])
            cube([front_pocket_w, front_depth + 1, win_h], center = true);
    }
}

module pin_holes() {
    d = pin_d + pin_clear;
    z = rail_z + join_boss_h_eff / 2;
    for (y = join_boss_ys)
        translate([0, y, z])
            rotate([0, 90, 0])
                cylinder(d = d, h = join_boss_x + 2, center = true);
}

module insert_body() {
    difference() {
        union() {
            // Solid outer rim + deck (only middle-front access pocket left open)
            solid_outer_rim();

            translate([0, rail_y0, rail_z]) t_slot_rail(rail_len, +1); // bay toward +Y
            translate([0, rail_y1, rail_z]) t_slot_rail(rail_len, -1); // bay toward -Y

            // End ties fully in the end-wall band — must not protrude into the pocket
            // (that protrusion was the short-end lip)
            end_tie_w = rail_hole_cc - 2 * rail_bay;
            for (sx = [-1, 1])
                translate([sx * (panel_pocket_l / 2 + wall / 2), 0, rail_z + rail_h / 2])
                    cube([wall, end_tie_w, rail_h], center = true);

            // Join bosses in the rim at the split — clear of the nut galleries
            for (y = join_boss_ys)
                translate([0, y, rail_z + join_boss_h_eff / 2])
                    cube([join_boss_x, join_boss_y, join_boss_h_eff], center = true);
        }

        pin_holes();

        // Belt-and-braces: shave any remaining short-end lip inside the pocket
        // (between the rails only — does not touch the T-slots)
        short_lip_clear = 1.0;
        for (sx = [-1, 1])
            translate([sx * (panel_pocket_l / 2 - short_lip_clear / 2), 0, insert_h / 2])
                cube([
                    short_lip_clear,
                    max(0.1, rail_hole_cc - 2 * rail_bay - 0.4),
                    insert_h + 2
                ], center = true);
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
    // Deck on the bed for efficient printing
    translate([which == "left" ? outer_l / 4 : -outer_l / 4, 0, insert_h])
        rotate([180, 0, 0])
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
    // Assembled preview stays in case orientation (deck up)
    color("#4a6d8c") half_body("left");
    color("#8ca8c0") half_body("right");
}
