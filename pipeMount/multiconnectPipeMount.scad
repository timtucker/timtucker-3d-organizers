/* Created by Tim Tucker

================================================================================
PARAMETRIC TAPERED THREAD COLLET PIPE-MOUNT SYSTEM WITH MULTICONNECT RAILS (BOSL2)
================================================================================
Description:
  A 3D printable three-part clamping system with integrated Multiconnect rails:
  
  1. Threaded Drive Nut & Knob (`drive_nut`):
     - Height set to 0.75 grid units (21mm at 28mm spacing).
     - Angled extension pusher past threads to prevent hitting the wedge seat.
     - Leaves 5mm exposed threads at max engagement/bottoming out.
     - 1mm chamfers on interior bore at both top and bottom entry points.

  2. Floating Split Collet (`inner_collet`):
     - Height strictly fixed at 1.75 grid units (49mm at 28mm spacing) for ALL grid heights.
     - 12 alternating slots (6 top-down, 6 bottom-up) with concave fillet roundings.
     - 1mm interior chamfer at both ends for easy sliding onto pipe.
     - Independent top/bottom bore clearance values (bottom: +0.2mm, top: -0.1mm).

  3. Grid-Aligned Cuboid Outer Housing (`outer_housing`):
     - Grid height restricted to whole integers with a minimum of 3.
     - Internal upper extension bore absorbs extra height when requested_grid_height > 3.
     - Outer X/Y dimensions remain strictly invariant when height changes.
================================================================================

Credits:
    Credit to @David D on Printables and Jonathan at Keep Making for Multiconnect and Multiboard, respectively
    @Dontic on GitHub for Multiconnect v2 code
    @AndyLevesque on GitHub for item holder designs as inspiration / initial basis

Licensed Creative Commons 4.0 Non-Commercial Sharable with Attribution (CC BY-NC-SA 4.0)

*/

include <BOSL2/std.scad>
include <BOSL2/threading.scad>

// Include external Multiconnect parametric rail module
use <../multiconnect/lib/multiconnectRails.scad>

/* [Part Selection / Display] */
// Select render view
part = "exploded"; // ["all": Assembled View, "exploded": Exploded View, "housing": Outer Housing, "collet": Floating Collet, "nut": Threaded Nut]

/* [Grid & Sizing Parameters] */
// Standard Multiconnect grid spacing pitch (mm)
grid_spacing             = 28.0; 
// Total height of outer housing in grid units (MINIMUM: 3 units)
requested_grid_height    = 3; // [3 : 1 : 12]

/* [Multiconnect Rail Counts Per Face] */
// Number of vertical Multiconnect rails on Front (+Y) face (0 = disabled)
rails_front              = 1; // [0 : 1 : 6]
// Number of vertical Multiconnect rails on Back (-Y) face (0 = disabled)
rails_back               = 1; // [0 : 1 : 6]
// Number of vertical Multiconnect rails on Left (-X) face (0 = disabled)
rails_left               = 1; // [0 : 1 : 6]
// Number of vertical Multiconnect rails on Right (+X) face (0 = disabled)
rails_right              = 1; // [0 : 1 : 6]
// Tolerance gap for Multiconnect rails (mm)
rail_slot_tolerance      = 0.15; 

/* [Pipe & Sleeve Parameters] */
// Outer diameter of the target pipe/tube (mm)
pipe_od                  = 25.0; 
// Base clearance tolerance added to pipe diameter for rigid bore / solid nut base (mm)
pipe_clearance           = 0.4;  

// Clearance tolerance for bottom of segmented collet against pipe (mm) [default: 0.2]
collet_pipe_clearance_bottom = 0.2;
// Clearance tolerance for top of segmented collet against pipe (mm) [default: -0.1]
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
// Mean outer diameter of grip knob (mm) [default: pipe_od + 25mm]
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
// Minimum side wall thickness from thread major diameter to flat cuboid face (mm)
housing_wall_min    = 4.0;  
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
// DERIVED CALCULATIONS & GRID HEIGHT CONSTRAINTS
// =============================================================================
// Enforce whole integer steps with a minimum grid height of 3 units
housing_grid_height = max(3, round(requested_grid_height));
housing_height      = housing_grid_height * grid_spacing;

// Grid-proportional component base heights:
drive_base_h        = 0.75 * grid_spacing; 

// Collet Height strictly fixed at 1.75 grid units
collet_units        = 1.75;
collet_h            = collet_units * grid_spacing;

r_pipe              = (pipe_od + pipe_clearance) / 2;
thread_depth        = thread_pitch / 2;

// Collet Cone Diameters
collet_top_d        = (r_pipe + collet_wall_min) * 2;
collet_base_d       = collet_top_d + (2 * collet_h * tan(wedge_angle));

// Thread Root aligns with collet base; Major Thread extends OUTWARD
thread_root_d       = collet_base_d;
thread_major_d      = thread_root_d + (2 * thread_depth);

// 45-Degree Transition Height between Female Thread and Cone Seat in housing
seat_transition_h   = (thread_major_d - thread_root_d) / 2;

// Housing Internal Geometry
L_thread_housing    = drive_base_h + 5.0; // Internal female thread depth in housing
seat_wedge_h        = collet_h;            // Internal wedge seat matches collet height (1.75 units)
seat_top_d          = collet_top_d;

// Calculations for Knob Thread vs Extension Collar:
// Thread stops at housing depth minus target exposed thread length
nut_thread_h        = L_thread_housing - exposed_threads;
// Extension collar reaches from thread end past the 45-deg transition to press the collet base
extension_h         = exposed_threads + seat_transition_h;
total_nut_proj_h    = nut_thread_h + extension_h; // = L_thread_housing + seat_transition_h

// Taper collar outer diameter at base and top so it clears housing transition & wedge seat
ext_base_d          = thread_root_d;
ext_top_d           = ext_base_d - (2 * extension_h * tan(wedge_angle));

// Internal upper clearance extension bore (absorbs remaining grid height above seat)
upper_bore_h        = housing_height - top_cap_thick - (L_thread_housing + seat_transition_h + seat_wedge_h);

// --- STRICTLY CONSTANT GRID-ALIGNED CUBOID SIZING ---
min_housing_d       = thread_major_d + (2 * slop) + (2 * housing_wall_min);

min_x_for_rails     = max(1, rails_front, rails_back) * grid_spacing;
min_y_for_rails     = max(1, rails_left, rails_right) * grid_spacing;

min_raw_x           = max(min_housing_d, min_x_for_rails);
min_raw_y           = max(min_housing_d, min_y_for_rails);

cuboid_x            = ceil(min_raw_x / (2 * grid_spacing)) * (2 * grid_spacing);
cuboid_y            = ceil(min_raw_y / (2 * grid_spacing)) * (2 * grid_spacing);

// --- EXPLODED VIEW OFFSETS ---
collet_exploded_z   = -grid_spacing - collet_h;
nut_exploded_z      = collet_exploded_z - (2 * grid_spacing);

exploded_span_height = housing_height + abs(nut_exploded_z) + knob_h;

// Sanity check
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

// =============================================================================
// MAIN COMPONENT MODULES
// =============================================================================

// Part 1: Threaded Drive Nut & Wave Knob (with Interior Bore Chamfers)
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
            
            // Threaded Portion (ends early so 5mm threads stay exposed at bottoming out)
            trapezoidal_threaded_rod(
                d = thread_major_d,
                l = nut_thread_h,
                pitch = thread_pitch,
                thread_angle = thread_angle,
                internal = false,
                anchor = BOTTOM
            );
            
            // Upper Extension Collar (Angled inward at wedge_angle to clear housing seat)
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

        // 1mm Chamfer around interior bore at BOTTOM (Knob entry)
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

        // 1mm Chamfer around interior bore at TOP (Extension exit)
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

// Part 2: Floating Split Collet (With Separate Top & Bottom Bore Clearances)
module inner_collet() {
    d1_wedge = collet_base_d - (2 * wedge_clearance);
    d2_wedge = collet_top_d - (2 * wedge_clearance);
    
    // Derived inner bore diameters at bottom and top
    collet_bore_bottom_d = pipe_od + collet_pipe_clearance_bottom;
    collet_bore_top_d    = pipe_od + collet_pipe_clearance_top;

    r_inner_start = collet_bore_bottom_d / 2 - 0.5;
    r_outer_end   = (thread_major_d / 2) + 5.0;
    cut_length    = r_outer_end - r_inner_start;
    r_midpoint    = (r_inner_start + r_outer_end) / 2;
    slot_h        = collet_h - slot_margin;

    difference() {
        // Conical Wedge Body
        cylinder(
            h = collet_h,
            d1 = d1_wedge,
            d2 = d2_wedge,
            center = false,
            $fn = $fn
        );
        
        // Conical Inner Bore for Tapered Pipe Clearance
        // Extra height extended beyond top/bottom to guarantee clean boolean subtraction
        translate([0, 0, -1.0])
        cylinder(
            h = collet_h + 2.0,
            d1 = collet_bore_bottom_d - (2.0 / collet_h) * (collet_bore_top_d - collet_bore_bottom_d),
            d2 = collet_bore_top_d + (1.0 / collet_h) * (collet_bore_top_d - collet_bore_bottom_d),
            center = false,
            $fn = $fn
        );
        
        // 1mm Chamfer around interior bore at BOTTOM end
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
        
        // 1mm Chamfer around interior bore at TOP end
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

// Part 3: Grid-Aligned Outer Cuboid Housing with Multiconnect Rails
module outer_housing() {
    bottom_chamfer = 2;
    rail_h = housing_height - top_cap_thick - bottom_chamfer;

    difference() {
        // --- 1. CUBOID HOUSING & MULTICONNECT RAILS ---
        union() {
            translate([0, 0, housing_height / 2])
            cuboid(
                size = [cuboid_x, cuboid_y, housing_height],
                rounding = housing_fillet_r,
                except=BOTTOM,
                anchor = CENTER,
                $fn = $fn
            );
            
            // Rails
            translate([0, 0, bottom_chamfer]) {
                // Front Face (+Y)
                if (rails_front > 0) {
                    translate([0, cuboid_y / 2, 0])
                    rotate([0, 0, 0])
                    multiconnect_rails(
                        num_rails = rails_front,
                        rail_spacing = grid_spacing,
                        height = rail_h,
                        slot_tolerance = rail_slot_tolerance,
                        center = true,
                        top_cap = true,
                        chamfer_size = 10.0,
                        $fn = 32
                    );
                }

                // Back Face (-Y)
                if (rails_back > 0) {
                    translate([0, -cuboid_y / 2, 0])
                    rotate([0, 0, 180])
                    multiconnect_rails(
                        num_rails = rails_back,
                        rail_spacing = grid_spacing,
                        height = rail_h,
                        slot_tolerance = rail_slot_tolerance,
                        center = true,
                        top_cap = true,
                        chamfer_size = 10.0,
                        $fn = 32
                    );
                }

                // Right Face (+X)
                if (rails_right > 0) {
                    translate([cuboid_x / 2, 0, 0])
                    rotate([0, 0, -90])
                    multiconnect_rails(
                        num_rails = rails_right,
                        rail_spacing = grid_spacing,
                        height = rail_h,
                        slot_tolerance = rail_slot_tolerance,
                        center = true,
                        top_cap = true,
                        chamfer_size = 10.0,
                        $fn = 32
                    );
                }

                // Left Face (-X)
                if (rails_left > 0) {
                    translate([-cuboid_x / 2, 0, 0])
                    rotate([0, 0, 90])
                    multiconnect_rails(
                        num_rails = rails_left,
                        rail_spacing = grid_spacing,
                        height = rail_h,
                        slot_tolerance = rail_slot_tolerance,
                        center = true,
                        top_cap = true,
                        chamfer_size = 10.0,
                        $fn = 32
                    );
                }
            }
        }
        
        // --- 2. INTERNAL CAVITY SUBTRACTIONS ---
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
        
        // 45-Degree Self-Supporting Transition Chamfer
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

        // Upper Straight Clearance Extension Bore (Absorbs remaining grid height)
        if (upper_bore_h > 0) {
            translate([0, 0, L_thread_housing + seat_transition_h + seat_wedge_h - 0.05])
            cylinder(
                h = upper_bore_h + 0.1,
                d = seat_top_d + (2 * slop),
                center = false,
                $fn = $fn
            );
        }
        
        // Upper Internal Ceiling Overhang (45-deg transition to top wall)
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
        
        // Subtractive Corner Chamfers on the Cuboid Base
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
    translate([0, 0, (housing_height + nut_exploded_z - knob_h) / 2])
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
    
    // Main Outer Housing
    color("DarkOrange", 0.85) 
    outer_housing();
    
    // Floating Collet shifted down by collet_exploded_z
    color("LimeGreen", 0.9) 
    translate([0, 0, collet_exploded_z]) 
    inner_collet();
    
    // Threaded Drive Nut shifted down by nut_exploded_z
    color("DeepSkyBlue", 0.9) 
    translate([0, 0, nut_exploded_z]) 
    drive_nut();
} else if (part == "all") {
    reference_pipe();
    
    color("DarkOrange", 0.85) 
    outer_housing();
    
    color("LimeGreen", 0.85) 
    translate([0, 0, L_thread_housing + seat_transition_h]) 
    inner_collet();
    
    // Render drive nut bottomed out against the collet (exposing 5mm of threads)
    color("DeepSkyBlue", 0.85) 
    translate([0, 0, -exposed_threads]) 
    drive_nut();
}