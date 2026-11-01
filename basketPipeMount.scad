/*

Created by Tim Tucker

================================================================================
PARAMETRIC COLLET PIPE-MOUNT SYSTEM WITH HEX GRID BOTTOMS (BOSL2)
================================================================================
Description:
  A 3D printable three-part clamping system with integrated device pockets:
  
  1. Threaded Drive Nut & Knob (`drive_nut`):
     - Height set to 0.75 grid units.
     - Angled extension pusher past threads to prevent hitting wedge seat.
     - Exposed threads at bottoming out with interior bore chamfers.

  2. Floating Split Collet (`inner_collet`):
     - Height fixed at 1.75 grid units (49mm at 28mm spacing).
     - 12 alternating slots with concave fillet roundings.

  3. Pocket Cuboid Outer Housing (`outer_housing`):
     - Integrated optional optimized hexagonal grid floor openings via `hexGrid.scad`.
     - Front pockets expand dynamically to distribute available width evenly.
     - Back pocket spans the exact gap between side pockets with uniform 4mm walls.
================================================================================

Licensed Creative Commons 4.0 Non-Commercial Sharable with Attribution (CC BY-NC-SA 4.0)

*/

include <BOSL2/std.scad>
include <BOSL2/threading.scad>

// Include external optimized hex grid pattern generator
use <hexGrid.scad>

/* [Part Selection / Display] */
// Select render view
part = "exploded"; // ["all": Assembled View, "exploded": Exploded View, "housing": Outer Housing, "collet": Floating Collet, "nut": Threaded Nut]

/* [Grid & Basic Parameters] */
// Standard grid spacing pitch (mm)
grid_spacing             = 28.0; 
// Total height of outer housing in grid units (MINIMUM: 3 units)
requested_grid_height    = 3; // [3 : 1 : 12]

/* [Hex Grid Floor Cutout Parameters] */
// Enable hexagonal grid openings on bottom floor of pockets
enable_hex_grid          = true;
// Minimum wall thickness between hexagonal cutouts (mm)
hex_wall_spacing         = 2.5;
// Minimum point-to-point radius for hex cutout calculation (mm)
hex_min_radius           = 5.0;
// Solid perimeter margin reserved around the inside pocket edges (mm)
hex_border_margin        = 4.0;

/* [Target Pocket Sizing & Fillets] */
// Standard nominal pocket width (mm)
pocket_w                 = 45.0;
// Standard nominal pocket length/depth (mm)
pocket_l                 = 85.0;
// Pocket wall/divider thickness (mm)
pocket_wall_thick        = 4.0;
// Fillet radius for internal pocket vertical corners (mm)
pocket_fillet_r          = 5.0;
// Fillet radius for internal pocket bottom floor transition (mm)
pocket_bottom_fillet_r   = 5.0;

/* [Housing Outer Dimensions & Offsets] */
// X offset to shift where the pipe passes through relative to center (mm)
pipe_x_offset            = 0.0;

/* [Pipe & Sleeve Parameters] */
// Outer diameter of the target pipe/tube (mm)
pipe_od                  = 25.0; 
// Base clearance tolerance added to pipe diameter for rigid bore / solid nut base (mm)
pipe_clearance           = 0.4;  

// Clearance tolerance for bottom of segmented collet against pipe (mm)
collet_pipe_clearance_bottom = 0.2;
// Clearance tolerance for top of segmented collet against pipe (mm)
collet_pipe_clearance_top    = -0.1;

// Radial clearance for the conical wedge section of the collet sleeve (mm)
wedge_clearance          = 0.0;  
// Minimum wall thickness of collet at top narrow end (mm)
collet_wall_min          = 3.5;  
// Angle of conical wedge taper in degrees (3-7 deg recommended)
wedge_angle              = 5.0;  

/* [Drive Nut & Wave Knob Parameters] */
// Height of tactile grip knob below the housing (mm)
knob_h              = 10.0; 
// Mean outer diameter of grip knob (mm)
knob_od             = pipe_od + 25.0; 
// Amplitude of wave pattern oscillation on knob (mm)
wave_amplitude      = 2.5;  
// Number of wave peaks around knob perimeter
knob_waves          = 6;    
// Chamfer size on bottom outer edge of knob (mm)
knob_chamfer        = 2.0;  
// Target length of exposed thread when drive nut pushes collet fully home (mm)
exposed_threads     = 5.0;
// Interior entry/exit chamfer on drive nut pipe bore (mm)
nut_bore_chamfer    = 1.0;

/* [Outer Cuboid Housing Parameters] */
// Thickness of top solid cap/shield on cuboid housing (mm)
top_cap_thick       = 5.0; 
// Thickness of bottom floor under device pockets (mm)
bottom_floor_thick  = 3.0; 
// Minimum structural wall surrounding the internal clamp mechanism post (mm)
post_wall_min       = 4.0;  
// Fillet radius for top edges and vertical corners of cuboid housing (mm)
housing_fillet_r    = 3.0;  
// Base chamfer size on outer bottom corners of cuboid housing (mm)
bottom_chamfer_val  = 1.0;  

/* [Thread & Tolerance Settings] */
// Thread pitch (mm) - coarse pitch recommended for 3D printing
thread_pitch        = 4.0;  
// Thread profile angle (90 deg = 45 deg overhangs, self-supporting)
thread_angle        = 90;   
// Radial slop clearance for 3D printed thread fit (mm)
slop                = 0.25; 

/* [Collet Interdigital Expansion Slots] */
// Width of expansion slots (mm)
slit_width          = 2.0;  
// Fillet radius applied to vertical split wings of collet (mm)
wing_edge_radius    = 0.8;  
// Solid web remaining at slot ends (mm)
slot_margin         = 5.0;  
// Interior entry/exit chamfer on collet bore (mm)
collet_bore_chamfer = 1.0;

/* [Rendering Smoothness] */
$fn = $preview ? 64 : 128;

// =============================================================================
// DERIVED CALCULATIONS & BOUNDING BOX FIT
// =============================================================================
pocket_top_rim_fillet = pocket_wall_thick / 3.0;

housing_grid_height = max(3, round(requested_grid_height));
housing_height      = housing_grid_height * grid_spacing;

drive_base_h        = 0.75 * grid_spacing; 
collet_units        = 1.75;
collet_h            = collet_units * grid_spacing;

r_pipe              = (pipe_od + pipe_clearance) / 2;
thread_depth        = thread_pitch / 2;

collet_top_d        = (r_pipe + collet_wall_min) * 2;
collet_base_d       = collet_top_d + (2 * collet_h * tan(wedge_angle));

thread_root_d       = collet_base_d;
thread_major_d      = thread_root_d + (2 * thread_depth);

seat_transition_h   = (thread_major_d - thread_root_d) / 2;
L_thread_housing    = drive_base_h + 5.0;
seat_wedge_h        = collet_h;
seat_top_d          = collet_top_d;

nut_thread_h        = L_thread_housing - exposed_threads;
extension_h         = exposed_threads + seat_transition_h;
total_nut_proj_h    = nut_thread_h + extension_h;

ext_base_d          = thread_root_d;
ext_top_d           = ext_base_d - (2 * extension_h * tan(wedge_angle));

upper_bore_h        = housing_height - top_cap_thick - (L_thread_housing + seat_transition_h + seat_wedge_h);

post_outer_d        = thread_major_d + (2 * slop) + (2 * post_wall_min);
post_r              = post_outer_d / 2;

// Minimum outer X width accommodating 3 front pockets
min_pocket_x        = (3 * pocket_w) + (4 * pocket_wall_thick);
cuboid_x            = max(min_pocket_x, (abs(pipe_x_offset) + post_r + pocket_w + (2 * pocket_wall_thick)) * 2);

// Total housing depth ensuring full length for front AND side pockets + divider walls
cuboid_y            = pocket_l + (3 * pocket_wall_thick) + pocket_l;

// Allocate width evenly across 3 front pockets
front_pocket_w      = (cuboid_x - (4 * pocket_wall_thick)) / 3;

pocket_depth_z      = housing_height - bottom_floor_thick;

collet_exploded_z   = -grid_spacing - collet_h;
nut_exploded_z      = collet_exploded_z - (2 * grid_spacing);
exploded_span_height = housing_height + abs(nut_exploded_z) + knob_h;

// Y position of the shared wall boundary behind the front pockets
front_pocket_rear_y = (cuboid_y / 2) - pocket_wall_thick - pocket_l;

// Pipe post Y position placed safely behind front pockets
pipe_y_offset       = front_pocket_rear_y - pocket_wall_thick - post_r;

// Inner wall bounds of side pockets along X
left_side_inner_x   = (-cuboid_x / 2) + pocket_wall_thick + pocket_w;
right_side_inner_x  = (cuboid_x / 2) - pocket_wall_thick - pocket_w;

// Sizing rear center pocket to fill the exact gap between side pockets with uniform wall thickness
rear_pocket_w       = (right_side_inner_x - left_side_inner_x) - (2 * pocket_wall_thick);
rear_pocket_l       = max(0.0, (pipe_y_offset - post_r) - ((-cuboid_y / 2) + pocket_wall_thick));

assert(upper_bore_h >= 0, "Housing grid height is too small for calculated seat dimensions!");

// =============================================================================
// HELPER MODULES
// =============================================================================

module knob_2d_profile(mean_r, amp, waves) {
    points = [
        for (a = [0 : 2 : 358]) 
        let (r = mean_r + amp * sin(a * waves))
        [r * cos(a), r * sin(a)]
    ];
    polygon(points);
}

module negative_radius_slot_2d(w_slot, r_fillet, cut_len) {
    union() {
        square([cut_len, w_slot], center = true);
        if (r_fillet > 0) {
            for (sy = [-1, 1]) {
                translate([0, sy * (w_slot / 2)])
                difference() {
                    square([cut_len, 2 * r_fillet], center = true);
                    for (sx = [-1, 1]) {
                        translate([sx * (cut_len / 2 + 0.1), sy * r_fillet])
                        circle(r = r_fillet, $fn = 32);
                    }
                }
            }
        }
    }
}

module angled_slot_cutter(r_mid, w_slot, r_fillet, cut_len, cut_h, taper_angle) {
    translate([r_mid, 0, 0])
    rotate([0, -taper_angle, 0])
    linear_extrude(height = cut_h, center = true)
    negative_radius_slot_2d(w_slot = w_slot, r_fillet = r_fillet, cut_len = cut_len);
}

// 3D Pocket Cutter using offset_sweep with os_circle() bottom & top profile shapes
module filleted_pocket_3d_cutter(cell_w, cell_d, depth, side_r, bottom_r, rim_r) {
    shape_profile = rect([cell_w, cell_d], rounding = side_r);
    
    offset_sweep(
        shape_profile,
        height = depth + 0.05,
        bottom = os_circle(r = bottom_r),
        top = os_circle(r = -rim_r),
        steps = $preview ? 16 : 32
    );
}

// Helper module to cut out optimized bottom floor hex mesh for a pocket
module pocket_hex_floor_cutter(pocket_width, pocket_length) {
    mesh_w = pocket_width - (2 * hex_border_margin);
    mesh_d = pocket_length - (2 * hex_border_margin);
    
    if (mesh_w > (hex_min_radius * 2) && mesh_d > (hex_min_radius * 2)) {
        translate([0, 0, bottom_floor_thick / 2])
        optimized_hex_grid(
            width = mesh_w,
            depth = mesh_d,
            height = bottom_floor_thick + 0.2,
            spacing = hex_wall_spacing,
            corner_rounding = 0.5,
            min_radius = hex_min_radius,
            max_radius = hex_min_radius * 1.25
        );
    }
}

// =============================================================================
// MAIN COMPONENT MODULES
// =============================================================================

// Part 1: Threaded Drive Nut & Wave Knob
module drive_nut() {
    nut_bore_d = pipe_od + pipe_clearance;

    difference() {
        union() {
            // Tactile Grip Knob
            translate([0, 0, -knob_h])
            difference() {
                linear_extrude(height = knob_h, $fn = $fn)
                knob_2d_profile(knob_od / 2, wave_amplitude, knob_waves);
                
                if (knob_chamfer > 0) {
                    rotate_extrude($fn = $fn) {
                        translate([knob_od / 2 + wave_amplitude + 1, 0])
                        polygon(points = [
                            [1, -1],
                            [-(knob_chamfer + 1.5), -1],
                            [1, knob_chamfer + 1.5]
                        ]);
                    }
                }
            }
            
            // Threaded Portion
            trapezoidal_threaded_rod(
                d = thread_major_d,
                l = nut_thread_h,
                pitch = thread_pitch,
                thread_angle = thread_angle,
                internal = false,
                anchor = BOTTOM
            );
            
            // Upper Extension Collar
            translate([0, 0, nut_thread_h])
            cylinder(
                h = extension_h,
                d1 = ext_base_d,
                d2 = ext_top_d,
                anchor = BOTTOM,
                $fn = $fn
            );
        }
        
        // Central Through-Bore for Pipe
        translate([0, 0, -knob_h - 1.0])
        cylinder(
            h = total_nut_proj_h + knob_h + 2.0,
            d = nut_bore_d,
            center = false,
            $fn = $fn
        );

        // Entry Chamfer at BOTTOM
        if (nut_bore_chamfer > 0) {
            translate([0, 0, -knob_h - 0.1])
            cylinder(
                h = nut_bore_chamfer + 0.1,
                d1 = nut_bore_d + (2 * nut_bore_chamfer),
                d2 = nut_bore_d,
                center = false,
                $fn = $fn
            );
        }

        // Exit Chamfer at TOP
        if (nut_bore_chamfer > 0) {
            translate([0, 0, total_nut_proj_h - nut_bore_chamfer])
            cylinder(
                h = nut_bore_chamfer + 0.1,
                d1 = nut_bore_d,
                d2 = nut_bore_d + (2 * nut_bore_chamfer),
                center = false,
                $fn = $fn
            );
        }
    }
}

// Part 2: Floating Split Collet
module inner_collet() {
    d1_wedge = collet_base_d - (2 * wedge_clearance);
    d2_wedge = collet_top_d - (2 * wedge_clearance);
    
    collet_bore_bottom_d = pipe_od + collet_pipe_clearance_bottom;
    collet_bore_top_d    = pipe_od + collet_pipe_clearance_top;

    r_inner_start = (collet_bore_bottom_d / 2) - 0.5;
    r_outer_end   = (thread_major_d / 2) + 5.0;
    cut_length    = r_outer_end - r_inner_start;
    r_midpoint    = (r_inner_start + r_outer_end) / 2;
    slot_h        = collet_h - slot_margin;

    difference() {
        cylinder(
            h = collet_h,
            d1 = d1_wedge,
            d2 = d2_wedge,
            center = false,
            $fn = $fn
        );
        
        translate([0, 0, -1.0])
        cylinder(
            h = collet_h + 2.0,
            d1 = collet_bore_bottom_d - (2.0 / collet_h) * (collet_bore_top_d - collet_bore_bottom_d),
            d2 = collet_bore_top_d + (1.0 / collet_h) * (collet_bore_top_d - collet_bore_bottom_d),
            center = false,
            $fn = $fn
        );
        
        if (collet_bore_chamfer > 0) {
            translate([0, 0, -0.1])
            cylinder(
                h = collet_bore_chamfer + 0.1,
                d1 = collet_bore_bottom_d + (2 * collet_bore_chamfer),
                d2 = collet_bore_bottom_d,
                center = false,
                $fn = $fn
            );
        }
        
        if (collet_bore_chamfer > 0) {
            translate([0, 0, collet_h - collet_bore_chamfer])
            cylinder(
                h = collet_bore_chamfer + 0.1,
                d1 = collet_bore_top_d,
                d2 = collet_bore_top_d + (2 * collet_bore_chamfer),
                center = false,
                $fn = $fn
            );
        }
        
        // 6 Top-Down Slots
        for (i = [0 : 5]) {
            rotate([0, 0, i * 60])
            translate([0, 0, collet_h - (slot_h / 2) + 0.1])
            angled_slot_cutter(
                r_mid       = r_midpoint,
                w_slot      = slit_width,
                r_fillet    = wing_edge_radius,
                cut_len     = cut_length,
                cut_h       = slot_h + 1.0,
                taper_angle = wedge_angle
            );
        }
        
        // 6 Bottom-Up Slots
        for (i = [0 : 5]) {
            rotate([0, 0, (i * 60) + 30])
            translate([0, 0, (slot_h / 2) - 0.1])
            angled_slot_cutter(
                r_mid       = r_midpoint,
                w_slot      = slit_width,
                r_fillet    = wing_edge_radius,
                cut_len     = cut_length,
                cut_h       = slot_h + 1.0,
                taper_angle = wedge_angle
            );
        }
    }
}

// Part 3: Cuboid Outer Housing with Hex Mesh Bottom Openings
module outer_housing() {
    difference() {
        // Main Outer Solid Block
        translate([0, 0, housing_height / 2])
        cuboid(
            size = [cuboid_x, cuboid_y, housing_height],
            rounding = housing_fillet_r,
            except = BOTTOM,
            anchor = CENTER,
            $fn = $fn
        );

        // --- 1. THREE EVENLY DISTRIBUTED FRONT POCKETS & HEX BOTTOMS ---
        front_y_center = (cuboid_y / 2) - pocket_wall_thick - (pocket_l / 2);
        for (i = [-1, 0, 1]) {
            fx_center = i * (front_pocket_w + pocket_wall_thick);
            
            // Main pocket volume subtraction
            translate([fx_center, front_y_center, bottom_floor_thick])
            filleted_pocket_3d_cutter(
                cell_w = front_pocket_w,
                cell_d = pocket_l,
                depth = pocket_depth_z,
                side_r = pocket_fillet_r,
                bottom_r = pocket_bottom_fillet_r,
                rim_r = pocket_top_rim_fillet
            );

            // Hex mesh floor opening
            if (enable_hex_grid) {
                translate([fx_center, front_y_center, 0])
                pocket_hex_floor_cutter(front_pocket_w, pocket_l);
            }
        }

        // --- 2. TWO EXTENDING SIDE POCKETS (45mm wide x 85mm long) & HEX BOTTOMS ---
        side_y_center = front_pocket_rear_y - pocket_wall_thick - (pocket_l / 2);
        
        // Left Side Pocket (-X)
        left_x_center = (-cuboid_x / 2) + pocket_wall_thick + (pocket_w / 2);
        translate([left_x_center, side_y_center, bottom_floor_thick])
        filleted_pocket_3d_cutter(
            cell_w = pocket_w,
            cell_d = pocket_l,
            depth = pocket_depth_z,
            side_r = pocket_fillet_r,
            bottom_r = pocket_bottom_fillet_r,
            rim_r = pocket_top_rim_fillet
        );
        if (enable_hex_grid) {
            translate([left_x_center, side_y_center, 0])
            pocket_hex_floor_cutter(pocket_w, pocket_l);
        }

        // Right Side Pocket (+X)
        right_x_center = (cuboid_x / 2) - pocket_wall_thick - (pocket_w / 2);
        translate([right_x_center, side_y_center, bottom_floor_thick])
        filleted_pocket_3d_cutter(
            cell_w = pocket_w,
            cell_d = pocket_l,
            depth = pocket_depth_z,
            side_r = pocket_fillet_r,
            bottom_r = pocket_bottom_fillet_r,
            rim_r = pocket_top_rim_fillet
        );
        if (enable_hex_grid) {
            translate([right_x_center, side_y_center, 0])
            pocket_hex_floor_cutter(pocket_w, pocket_l);
        }

        // --- 3. REAR CENTER POCKET & HEX BOTTOM ---
        if (rear_pocket_l > 5.0 && rear_pocket_w > 5.0) {
            rear_y_center = (-cuboid_y / 2) + pocket_wall_thick + (rear_pocket_l / 2);
            translate([0, rear_y_center, bottom_floor_thick])
            filleted_pocket_3d_cutter(
                cell_w = rear_pocket_w,
                cell_d = rear_pocket_l,
                depth = pocket_depth_z,
                side_r = min(pocket_fillet_r, rear_pocket_w / 4, rear_pocket_l / 3),
                bottom_r = min(pocket_bottom_fillet_r, rear_pocket_w / 4, rear_pocket_l / 3),
                rim_r = pocket_top_rim_fillet
            );

            if (enable_hex_grid) {
                translate([0, rear_y_center, 0])
                pocket_hex_floor_cutter(rear_pocket_w, rear_pocket_l);
            }
        }

        // --- INTERNAL CLAMP CAVITY SUBTRACTIONS (POST LOCATED AT REALIGNED Y OFFSET) ---
        translate([pipe_x_offset, pipe_y_offset, 0]) {
            // Lower Female Thread
            translate([0, 0, -0.1])
            trapezoidal_threaded_rod(
                d = thread_major_d,
                l = L_thread_housing + 0.1,
                pitch = thread_pitch,
                thread_angle = thread_angle,
                internal = true,
                $slop = slop,
                anchor = BOTTOM
            );
            
            // 45-Degree Transition Chamfer
            translate([0, 0, L_thread_housing - 0.05])
            cylinder(
                h = seat_transition_h + 0.1,
                d1 = thread_major_d + (2 * slop),
                d2 = thread_root_d + (2 * slop),
                center = false,
                $fn = $fn
            );
            
            // Conical Wedge Seat Ramp
            translate([0, 0, L_thread_housing + seat_transition_h - 0.05])
            cylinder(
                h = seat_wedge_h + 0.1,
                d1 = thread_root_d + (2 * slop),
                d2 = seat_top_d + (2 * slop),
                center = false,
                $fn = $fn
            );

            // Upper Clearance Extension Bore
            if (upper_bore_h > 0) {
                translate([0, 0, L_thread_housing + seat_transition_h + seat_wedge_h - 0.05])
                cylinder(
                    h = upper_bore_h + 0.1,
                    d = seat_top_d + (2 * slop),
                    center = false,
                    $fn = $fn
                );
            }
            
            // Upper Ceiling Overhang
            translate([0, 0, housing_height - top_cap_thick - 0.05])
            cylinder(
                h = top_cap_thick + 0.1,
                d1 = seat_top_d + (2 * slop),
                d2 = pipe_od + pipe_clearance,
                center = false,
                $fn = $fn
            );
            
            // Main Pipe Clearance Bore
            translate([0, 0, -1.0])
            cylinder(
                h = housing_height + 2.0,
                d = pipe_od + pipe_clearance,
                center = false,
                $fn = $fn
            );
        }

        // Base Bottom Corner Chamfers
        if (bottom_chamfer_val > 0) {
            for (sx = [-1, 1]) {
                for (sy = [-1, 1]) {
                    translate([sx * (cuboid_x / 2), sy * (cuboid_y / 2), -0.1])
                    rotate([0, 0, 45])
                    cylinder(
                        h = bottom_chamfer_val + 0.1,
                        d1 = bottom_chamfer_val * 3,
                        d2 = 0,
                        $fn = 4
                    );
                }
            }
        }
    }
}

// Visual Pipe Reference
module reference_pipe() {
    pipe_h = 2.5 * exploded_span_height;
    color("LightGray", 0.4)
    translate([pipe_x_offset, pipe_y_offset, (housing_height + nut_exploded_z - knob_h) / 2])
    cylinder(h = pipe_h, d = pipe_od, center = true, $fn = $fn);
}

// =============================================================================
// DISPLAY ROUTER
// =============================================================================

if (part == "housing") {
    color("DarkOrange") outer_housing();
} else if (part == "collet") {
    color("LimeGreen") inner_collet();
} else if (part == "nut") {
    color("DeepSkyBlue") drive_nut();
} else if (part == "exploded") {
    reference_pipe();
    
    color("DarkOrange", 0.85) 
    outer_housing();
    
    color("LimeGreen", 0.9) 
    translate([pipe_x_offset, pipe_y_offset, collet_exploded_z]) 
    inner_collet();
    
    color("DeepSkyBlue", 0.9) 
    translate([pipe_x_offset, pipe_y_offset, nut_exploded_z]) 
    drive_nut();
} else if (part == "all") {
    reference_pipe();
    
    color("DarkOrange", 0.85) 
    outer_housing();
    
    color("LimeGreen", 0.85) 
    translate([pipe_x_offset, pipe_y_offset, L_thread_housing + seat_transition_h]) 
    inner_collet();
    
    color("DeepSkyBlue", 0.85) 
    translate([pipe_x_offset, pipe_y_offset, -exposed_threads]) 
    drive_nut();
}