include <BOSL2/std.scad>
include <BOSL2/screws.scad>

$fn = $preview ? 16 : 128;

// Dedicated module for hex head bolts with corner-aware slot geometry
module reinforced_hex_bolt_hole(
  screw_spec = "#8-32",
  head_height,
  hole_len = 10,
  recess_depth = 0,
  num_slots = 6,
  slot_width = 1,
  slot_extent = 2,
  inner_clearance = 1.0,
  margin_top = 1.0,
  margin_bottom = 1.0,
) {
  info = screw_info(screw_spec, head="hex");

  // Extract shaft diameter safely
  shaft_d = is_def(struct_val(info, "shaft_diam")) ? struct_val(info, "shaft_diam") : 4.0;
  shaft_r = shaft_d / 2;

  // Extract head height safely
  head_h = is_def(head_height) ? head_height : (is_def(struct_val(info, "head_height")) ? struct_val(info, "head_height") : 3.0);

  // Extract head flat-to-flat width safely across BOSL2 data keys
  head_w = struct_val(
    info, "head_size",
    struct_val(
      info, "head_diam",
      struct_val(info, "drive", shaft_d * 2)
    )
  );

  // Hex outer radius (flat-to-flat / sqrt(3) gives point-to-point max radius)
  head_max_r = head_w / sqrt(3);
  outer_r = head_max_r + inner_clearance + slot_extent;

  // Total recess depth = head height + any additional counterbore recess depth
  total_recess_h = head_h + max(0, recess_depth);
  slot_h = max(0.1, hole_len - margin_top - margin_bottom);

  union() {
    // 1. Primary screw cutout
    screw_hole(
      screw_spec,
      l=hole_len + 0.002,
      head="hex",
      counterbore=recess_depth,
      anchor=TOP,
      teardrop=false
    );

    // 2. Perimeter reinforcement slots clearing the hex vertices
    difference() {
      intersection() {
        translate([0, 0, -(hole_len - margin_bottom)]) {
          cyl(r=outer_r, h=slot_h, anchor=BOTTOM);
        }

        zrot_copies(n=num_slots) {
          translate([0, -slot_width / 2, -hole_len]) {
            cube([outer_r + 1, slot_width, hole_len]);
          }
        }
      }

      // Rotated profile wall matching the total depth of the head pocket + shaft
      rotate_extrude() {
        polygon(
          points=[
            [0, 0.01],
            [head_max_r + inner_clearance, 0.01],
            [head_max_r + inner_clearance, -total_recess_h],
            [shaft_r + inner_clearance, -total_recess_h],
            [shaft_r + inner_clearance, -(hole_len + 0.01)],
            [0, -(hole_len + 0.01)],
          ]
        );
      }
    }
  }
}

// Reusable module: Generates a screw hole with internal perimeter-reinforcement slots
// Preserves original Minkowski logic for flat/countersunk head styles
module reinforced_screw_hole(
  screw_spec = "#8-32",
  head = "flat",
  hole_len = 10,
  recess_depth = 1.3,
  num_slots = 8,
  slot_width = 1,
  slot_extent = 2, // How far outward the void extends beyond the screw head (in mm)
  inner_clearance = 1.0, // Solid wall thickness around the screw profile (in mm)
  margin_top = 1.0, // Solid top cover margin
  margin_bottom = 1.0 // Solid bottom base margin
) {
  // Original logic for flat / standard heads using Minkowski expansion
  head_r = 3.6;
  outer_r = head_r + inner_clearance + slot_extent;

  union() {
    // 1. Primary screw hole cutout
    screw_hole(
      screw_spec,
      l=hole_len + 0.002,
      head=head,
      counterbore=recess_depth,
      anchor=TOP
    );

    // 2. Taper-matching perimeter reinforcement slots
    difference() {
      // Step A: Generate radial fin cutters bounded by outer radius and Z margins
      intersection() {
        // Outer boundary cylinder (restricts radial reach)
        translate([0, 0, -(hole_len - margin_bottom)]) {
          cyl(
            r=outer_r,
            h=hole_len - margin_top - margin_bottom,
            anchor=BOTTOM
          );
        }

        // Circular pattern of radial fin cutters
        for (a = [0:360 / num_slots:359]) {
          rotate([0, 0, a]) {
            translate([0, -slot_width / 2, -hole_len]) {
              cube([outer_r + 1, slot_width, hole_len]);
            }
          }
        }
      }

      // Step B: Subtract an expanded copy of the screw_hole profile
      translate([0, 0, -margin_top]) {
        minkowski() {
          screw_hole(
            screw_spec,
            l=hole_len,
            head=head,
            counterbore=recess_depth,
            anchor=TOP
          );
          cyl(r=inner_clearance, h=0.001, center=true);
        }
      }
    }
  }
}

// Render test

// reinforced_screw_hole(
//   screw_spec="1/4-20",
//   head="flat",
//   hole_len=15,
//   recess_depth=4,
//   num_slots=8,
//   slot_width=1,
//   slot_extent=2,
//   inner_clearance=1.0,
//   margin_top=1.0,
//   margin_bottom=1.0
// );

// reinforced_hex_bolt_hole(
//   screw_spec="1/4-20",
//   hole_len=15,
//   head_height = 10,
//   recess_depth=0,
//   num_slots=6,
//   slot_width=1,
//   slot_extent=2,
//   inner_clearance=1.0,
//   margin_top=1.0,
//   margin_bottom=1.0
// );