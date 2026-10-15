/* Created by Tim Tucker

Charging station for power banks
- Hex grid cutouts for ventilation
- Waves at the bottom of each slot to improve airflow
- Channels to route charging cords in the middle / sides

Designed to be mounted on a side wall for Multiconnect

Slides onto rails from the side rather than the top:
- Makes it easier to print
- Allows for pulling out a single organizer in a stack without needing to move the rest

Recommended for use with Multiconnect rails in between mounts for extra support:
https://www.printables.com/model/1368797-opengrid-multiconnect-rails

For a 2 column / 3 row model, it was enough to use rails on the top and bottom slots.

Defaults to left mount, but can be changed to right-mount by mirroring before printing.

Credits:
    Credit to @David D on Printables and Jonathan at Keep Making for Multiconnect and Multiboard, respectively
    @Dontic on GitHub for Multiconnect v2 code
    @AndyLevesque on GitHub for item holder designs as inspiration / initial basis

Licensed Creative Commons 4.0 Non-Commercial Sharable with Attribution (CC BY-NC-SA 4.0)

*/
include <BOSL2/std.scad>
include <hexGrid.scad>

/* [Holder Parameters] */
item_rows = 3; // Number of stacked rows (Y-axis grid height)
item_columns = 2; // Number of horizontal columns (X-axis grid width)
wall_thickness = 2; // Spacing between slots and outer wall thickness (mm)

/* [Slot Dimensions] */
slot_width = 85; // Inner slot width (X axis)
slot_depth = 85; // Inner slot depth (Y axis)
slot_height = 45; // Inner slot nominal height (Z axis)
slant_angle = 15; // Forward/backward slant tilt (degrees)

finger_cutout_diameter = 30;

/* [Cable Hole Parameters] */
cable_hole_width = 8; // Cable pass-through hole width (X axis)
cable_hole_height = 16; // Cable pass-through hole height (Z axis)

/* [Wave Parameters] */
wave_period = 20; // Target wavelength (mm)
wave_amp = 3; // Wave amplitude (mm)

/* [Hex Grid Parameters] */
min_hex_diameter = 3; // Minimum point-to-point diameter of hex vents
hex_spacing = 2; // Minimum wall spacing between adjacent hexagons

/* [Multiconnect Parameters] */
multiconnectBackThickness = 6.5;
distanceBetweenSlots = 28;
multiConnectVersion = "v2"; // [v1, v2]
slotQuickRelease = false;
dimpleScale = 1;
slotTolerance = 1;
slotDepthMicroadjustment = 0;
onRampEnabled = false;
onRampEveryXSlots = 1;

/* [Quality] */
previewQuality = 8;
renderQuality = 64;

/* [Hidden] */
$fn =$preview ? previewQuality : renderQuality;

// Increase the slot height so that it works out correctly after the slant is applied
adjusted_slot_height = slot_height / cos(slant_angle);

// Enlarge vertical wall dividers to comfortably fit the cable hole width plus structural walls
left_divider_wall = max(2 * wall_thickness, cable_hole_width + (2 * wall_thickness));

column_divider_wall = left_divider_wall;
top_bottom_wall = 2 * wall_thickness;
side_outer_wall = left_divider_wall;

vent_spacing = 2 * wall_thickness;
min_vent_h = wave_period / 4;

// Helper Functions
function divider_thickness(row, wall, top_wall) =
  (row == 0) ? top_wall : wall;

function divider_z_pos(row, sh, wall, top_wall) =
  -(sh / 2) - (divider_thickness(row, wall, top_wall) / 2);

function top_wall_z_pos(sh, top_wall) =
  (sh / 2) + (top_wall / 2);

// =========================================================================
// MULTICONNECT MODULES
// =========================================================================

module slotTool(totalHeight) {
  scale(v=slotTolerance) let (slotProfile = [[0, 0], [10.15, 0], [10.15, 1.2121], [7.65, 3.712], [7.65, 5], [0, 5]])
  difference() {
    union() {
      // Round top 
      rotate(a=[90, 0, 0]) {
        rotate_extrude($fn=$fn) {
          polygon(points=slotProfile);
        }
      }
      // Long slot 
      translate(v=[0, 0, 0]) rotate(a=[180, 0, 0]) union() {
        difference() {
          linear_extrude(height=totalHeight + 1) {
            polygon(points=slotProfile);
          }
          if (slotQuickRelease == false && multiConnectVersion == "v2") {
            translate(v=[10.15, 0, 0]) {
              rotate(a=[-90, 0, 0]) {
                linear_extrude(height=5) {
                  polygon(points=[[0, 0], [-0.4, 0], [0, -8]]);
                }
              }
            }
          }
        }
        mirror([1, 0, 0]) {
          difference() {
            linear_extrude(height=totalHeight + 1) {
              polygon(points=slotProfile);
            }
            if (slotQuickRelease == false && multiConnectVersion == "v2") {
              translate(v=[10.15, 0, 0]) {
                rotate(a=[-90, 0, 0]) {
                  linear_extrude(height=5) {
                    polygon(points=[[0, 0], [-0.4, 0], [0, -8]]);
                  }
                }
              }
            }
          }
        }
      }
      if (onRampEnabled) {
        for (y = [1:onRampEveryXSlots:max(1, totalHeight / distanceBetweenSlots)]) {
          translate(v=[0, -5, -y * distanceBetweenSlots]) {
            rotate(a=[-90, 0, 0]) {
              cylinder(h=5, r1=12, r2=10.15, $fn=$fn);
            }
          }
        }
      }
    }
    if (slotQuickRelease == false && multiConnectVersion == "v1") {
      scale(v=dimpleScale) {
        rotate(a=[90, 0, 0]) {
          rotate_extrude($fn=$fn) {
            polygon(points=[[0, 0], [0, 1.5], [1.5, 0]]);
          }
        }
      }
    }
  }
}

module createMulticonnectSlots(backWidth, backHeight, distanceBetweenSlots, skewOffset = 0, edgeMargin = top_bottom_wall) {
  usableWidth = max(0, backWidth - skewOffset);
  usableHeight = max(0, backHeight - (2 * edgeMargin));

  bWidth = max(usableWidth, distanceBetweenSlots);
  bHeight = max(usableHeight, distanceBetweenSlots);
  slotCount = floor(bWidth / distanceBetweenSlots);

  start_x = skewOffset + (distanceBetweenSlots / 2) + (usableWidth - (slotCount * distanceBetweenSlots)) / 2;
  start_z = edgeMargin + max(0, bHeight - 13);

  if (slotCount > 0) {
    for (slotNum = [0:1:slotCount - 1]) {
      translate(
        v=[
          start_x + (slotNum * distanceBetweenSlots),
          -2.35 + slotDepthMicroadjustment,
          start_z,
        ]
      ) {
        slotTool(bHeight);
      }
    }
  }
}

// =========================================================================
// POSITIONING MODULES
// =========================================================================

module horizontal_divider_hex_grid(sw, sd, wall_h, r_val, cutout_d, slant, is_top_wall = false) {
  grid_w = is_top_wall ? (sw - (2 * wall_thickness)) : (cutout_d);

  front_limit_y = -(cutout_d / 2) - (wall_thickness);
  back_limit_y = -sd + (wall_thickness);
  grid_d = abs(back_limit_y - front_limit_y);
  center_y = front_limit_y - (grid_d / 2);

  translate([sw / 2, center_y, 0]) {
    optimized_hex_grid(
      width=grid_w,
      depth=grid_d,
      height=wall_h,
      min_radius=min_hex_diameter / 2,
      spacing=wall_thickness,
      corner_rounding=r_val,
      skew_angle=slant,
      hex_angle=90,
      debug_grid_size=false
    );
  }
}

// Side cutouts in vertical dividers (Elevated above cable hole)
module vertical_wall_hex_vents(sw, sd, sh, wall, r_val, slant, target_wall_thickness, hole_h) {
  front_limit_y = - wall_thickness;
  back_limit_y = -sd + wall_thickness;
  grid_d = abs(back_limit_y - front_limit_y);
  center_y = front_limit_y - (grid_d / 2);

  hole_clearance = hole_h > 0 ? (hole_h + wall_thickness) : 0;
  avail_h = max(0, sh - (2 * wall_thickness) - hole_clearance);
  center_z_shift = hole_clearance / 2;

  if (avail_h > min_hex_diameter) {
    translate([0, center_y, center_z_shift]) {
      rotate([0, 90, 0]) {
        optimized_hex_grid(
          width=avail_h,
          depth=grid_d,
          height=target_wall_thickness + 0.2,
          min_radius=min_hex_diameter / 2,
          spacing=hex_spacing,
          corner_rounding=r_val,
          skew_angle=0,
          hex_angle=90,
          debug_grid_size=false
        );
      }
    }
  }
}

function main_slot_profile_2d(w, h_val, cutout_d, target_period, amp, is_top_slot) =
  let (
    center_x = w / 2,
    r = cutout_d / 2,
    x_flat_start = center_x - r,
    x_flat_end = center_x + r,
    side_width = x_flat_start,
    num_cycles = max(1, floor(side_width / target_period)),
    actual_period = side_width / num_cycles,
    wave_offset = function(x)
    (x < x_flat_start) ?
      amp * (1 - cos(x * 360 / actual_period))
    : (x <= x_flat_end) ?
      0
    : amp * (1 - cos((w - x) * 360 / actual_period)),
    top_path = is_top_slot ?
      [[0, h_val / 2], [w, h_val / 2]]
    : [for (x = [0:0.5:w]) [x, h_val / 2 + wave_offset(x)]],
    bot_path = [for (x = [w:-0.5:0]) [x, -h_val / 2 + wave_offset(x)]],
    raw_profile = concat(top_path, bot_path)
  ) deduplicate(raw_profile);

module main_slot_cutout_3d(w, d, h_val, r, cutout_d, target_period, amp, is_top_slot) {
  poly_2d = main_slot_profile_2d(w, h_val, cutout_d, target_period, amp, is_top_slot);

  rotate([90, 0, 0])
    offset_sweep(
      poly_2d,
      h=d,
      bottom=os_circle(r=-r, steps=min($fn, 16)),
      top=os_circle(r=r, steps=min($fn, 16))
    );
}

module back_wall_heat_vents(sw, sd, sh, wall, r_val, amp) {
  z_min = -sh / 2 + (2 * amp) + wall;
  z_max = (sh / 2) - wall;
  avail_h = z_max - z_min;
  center_z = (z_min + z_max) / 2;
  avail_w = sw - (2 * wall_thickness);

  translate([sw / 2, -sd - (wall / 2), center_z]) {
    rotate([90, 0, 0]) {
      optimized_hex_grid(
        width=avail_w,
        depth=avail_h,
        height=wall + 0.1,
        min_radius=min_hex_diameter / 2,
        spacing=hex_spacing,
        corner_rounding=r_val,
        skew_angle=0,
        hex_angle=90,
        debug_grid_size=false
      );
    }
  }
}

// Continuous rounded rectangle cable pass-through hole with negative fillet (front) and negative chamfer (back)
module cable_hole_cutout(sd, ch_w, ch_h, r_val) {
  corner_r = min(ch_w, ch_h) / 4;
  chamfer_val = 1.5;

  // 2D Rounded Rectangle Base Profile
  rect_2d = rect([ch_w, ch_h], rounding=corner_r);

  rotate([90, 0, 0])
    offset_sweep(
      rect_2d,
      h=sd,
      bottom=os_circle(r=-r_val, steps=min($fn, 16)), // Negative Fillet at Front
      top=os_circle(r=-chamfer_val, steps=1) // Negative Chamfer at Back
    );
}

module cutout_item_slots(rows, cols, wall, sw, sd, sh, r_val, period, amp, slant) {
  w = finger_cutout_diameter;
  half_w = w / 2;

  wave_cutout_2d = deduplicate(
    concat(
      [
        for (x = [-half_w:0.5:half_w]) [x, -(half_w / 2) * (1 + cos(x * 180 / half_w))],
      ],
      [[half_w, 1], [-half_w, 1]]
    )
  );

  for (col = [0:cols - 1]) {
    col_x = side_outer_wall + col * (sw + column_divider_wall);
    center_x = col_x + (sw / 2);

    // Visual LEFT divider wall for slot `col` is at local right edge (`col_x + sw + column_divider_wall / 2`)
    visual_left_wall_x = col_x + sw + (column_divider_wall / 2);

    for (row = [0:rows - 1]) {
      z_pos = top_bottom_wall + (sh / 2) + (row * (sh + wall));
      is_top = (row == rows - 1);

      scoop_wall_h = divider_thickness(row, wall, top_bottom_wall);
      divider_z = divider_z_pos(row, sh, wall, top_bottom_wall);
      top_wall_z = top_wall_z_pos(sh, top_bottom_wall);

      up(z_pos) {
        // Main item slot cutout
        translate([col_x, 0.01, 0]) {
          main_slot_cutout_3d(sw, sd, sh, r_val, finger_cutout_diameter, period, amp, is_top);
        }

        // Cable Pass-Through Hole: At middle dividers & visual-left outer wall
        translate(
          [
            visual_left_wall_x,
            0.01,
            -(sh / 2) + (cable_hole_height / 2),
          ]
        ) {
          cable_hole_cutout(sd + (2 * wall_thickness) + 0.02, cable_hole_width, cable_hole_height, r_val);
        }

        // Cable Pass-Through Hole: At visual far-right outer wall (when col == 0)
        if (col == 0) {
          translate(
            [
              col_x - (side_outer_wall / 2),
              0.01,
              -(sh / 2) + (cable_hole_height / 2),
            ]
          ) {
            cable_hole_cutout(sd + (2 * wall_thickness) + 0.02, cable_hole_width, cable_hole_height, r_val);
          }
        }

        translate([center_x, 0, divider_z - (scoop_wall_h / 2) - 0.01]) {
          offset_sweep(
            wave_cutout_2d,
            h=scoop_wall_h + 0.02,
            bottom=os_circle(r=-r_val, steps=min($fn, 16)),
            top=os_circle(r=-r_val, steps=min($fn, 16))
          );
        }

        if (is_top) {
          translate([center_x, 0, (sh / 2) - 0.01]) {
            offset_sweep(
              wave_cutout_2d,
              h=top_bottom_wall + 0.02,
              bottom=os_circle(r=-r_val, steps=min($fn, 16)),
              top=os_circle(r=-r_val, steps=min($fn, 16))
            );
          }
        }

        translate([col_x, 0, 0]) {
          back_wall_heat_vents(sw, sd, sh, wall, r_val, amp);
        }

        translate([col_x, 0, divider_z]) {
          horizontal_divider_hex_grid(sw, sd, scoop_wall_h, r_val, finger_cutout_diameter, slant, is_top_wall=false);
        }

        if (is_top) {
          translate([col_x, 0, top_wall_z]) {
            horizontal_divider_hex_grid(sw, sd, top_bottom_wall, r_val, finger_cutout_diameter, slant, is_top_wall=true);
          }
        }

        // Hex vents in visual LEFT divider walls (elevated above cable hole for all columns)
        translate([visual_left_wall_x, 0, 0]) {
          vertical_wall_hex_vents(sw, sd, sh, wall, r_val, slant, column_divider_wall, cable_hole_height);
        }

        // Hex vents in visual FAR RIGHT outer wall (when col == 0, elevated above cable hole)
        if (col == 0) {
          translate([col_x - (side_outer_wall / 2), 0, 0]) {
            vertical_wall_hex_vents(sw, sd, sh, wall, r_val, slant, side_outer_wall, cable_hole_height);
          }
        }
      }
    }
  }
}

module rawMainBody(
  rows = 3,
  cols = 2,
  wall = 3,
  sw = 70,
  sd = 80,
  sh = 36,
  slant = 15,
  period = 15,
  amp = 3
) {
  r_val = wall / 3;

  total_width = (cols * sw) + (2 * side_outer_wall) + ((cols - 1) * column_divider_wall) + multiconnectBackThickness;
  total_depth = sd + wall;
  total_height = (rows * sh) + ((rows - 1) * wall) + (2 * top_bottom_wall);

  x_after_rotation = total_height + wall_thickness;
  y_after_rotation = total_width - multiconnectBackThickness;
  z_after_rotation = total_depth * cos(slant);

  translate([x_after_rotation, y_after_rotation, z_after_rotation]) {
    rot([slant + 90, 0, -90]) {
      skew(syz=tan(slant)) {
        difference() {
          cuboid(
            [total_width, total_depth, total_height],
            anchor=BOTTOM + LEFT + BACK,
            rounding=wall / 2
          );

          cutout_item_slots(rows, cols, wall, sw, sd, sh, r_val, period, amp, slant);
        }
      }
    }
  }
}

module finalAssembly() {
  total_depth = slot_depth + wall_thickness;
  total_height = (item_rows * adjusted_slot_height) + ((item_rows - 1) * wall_thickness) + (2 * top_bottom_wall);

  skew_offset = total_depth * tan(slant_angle);

  difference() {
    rawMainBody(
      rows=item_rows,
      cols=item_columns,
      wall=wall_thickness,
      sw=slot_width,
      sd=slot_depth,
      sh=adjusted_slot_height,
      slant=slant_angle,
      period=wave_period,
      amp=wave_amp
    );

    translate([0, 0, 0]) {
      createMulticonnectSlots(
        backWidth=total_height,
        backHeight=total_depth,
        distanceBetweenSlots=distanceBetweenSlots,
        skewOffset=skew_offset,
        edgeMargin=top_bottom_wall
      );
    }
  }
}

finalAssembly();