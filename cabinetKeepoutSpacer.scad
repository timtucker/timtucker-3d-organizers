/*
Small cabinet organizer designed to have a keep-away area for openGrid mounted items on the back of the door
*/
include <BOSL2/std.scad>
include <./reinforced_screw_hole.scad>

// Fast preview ($fn = 16) / smooth render ($fn = 128)
$fn = $preview ? 16 : 128;

height = 5;
base_depth = 50;
base_width = 120;

module base() {
  // Base 2D shape
  shape2d_base = rect([base_depth, base_width], rounding=[15, 2, 20, 2]);

  // Sweep base upwards with bottom chamfer and top fillet
  offset_sweep(
    shape2d_base,
    height=height,
    bottom=os_chamfer(width=2),
    top=os_circle(r=2)
  );
}

// Box specifications
box_right_width = 35;
box_right_height = 45;
pocket_depth = 35;
pocket_count = 5;
box_right_depth = pocket_depth * pocket_count;
box_right_shift_back = 15;
box_right_wall_thickness = 3;

// Outer 2D profile
shape2d_right = rect([box_right_depth, box_right_width], rounding=[2, 2, 10, 10]);

divider_count = pocket_count - 1;
num_compartments = divider_count + 1;

// Dimensions for interior compartment pockets
total_interior_length = box_right_depth - (2 * box_right_wall_thickness);
total_divider_thickness = divider_count * box_right_wall_thickness;
pocket_length = (total_interior_length - total_divider_thickness) / num_compartments;
pocket_width = box_right_width - (2 * box_right_wall_thickness);

// Pocket profiles
inner_corner_r = max(1, 10 - box_right_wall_thickness);
pocket_profile = rect([pocket_length, pocket_width], rounding=inner_corner_r);

box_right_y_position = base_width / 2 - box_right_width / 2;

difference() {
  union() {
    // Base
    base();

    translate([-box_right_depth / 2 + base_depth / 2 - box_right_shift_back, box_right_y_position, 0]) {
      // 1. Solid Outer Body
      offset_sweep(
        shape2d_right,
        height=box_right_height,
        bottom=os_chamfer(width=2),
        top=os_circle(r=2)
      );
    }
  }

  screw_pocket_height = 20;
  screw_recess = screw_pocket_height - 15 - 1.3;

  translate([-box_right_depth / 2 + base_depth / 2 - box_right_shift_back, box_right_y_position, 0]) {
    // 2. Subtract individual rounded pockets
    for (i = [0:divider_count]) {
      pocket_x = -box_right_depth / 2 + box_right_wall_thickness + pocket_length / 2 + i * (pocket_length + box_right_wall_thickness);

      pocket_bottom_height = (i == divider_count) ? screw_pocket_height : 3;

      translate([pocket_x, 0, pocket_bottom_height]) {
        offset_sweep(
          pocket_profile,
          height=box_right_height - pocket_bottom_height + 0.001,
          bottom=os_circle(r=3),
          top=os_circle(r=-1)
        );
      }

      // Last pocket screw mounting logic
      if (i == divider_count) {
        translate([pocket_x, 0, pocket_bottom_height]) {
          reinforced_screw_hole(
            screw_spec="#8-32",
            hole_len=pocket_bottom_height,
            recess_depth=screw_recess,
            num_slots=8,
            slot_width=1.2,
            inner_clearance = 1.6, // Solid wall thickness around the screw profile (in mm)
            margin_top      = 2, // Solid top cover margin
            margin_bottom   = 2  // Solid bottom base margin
          );
        }
      }
    }
  }
}