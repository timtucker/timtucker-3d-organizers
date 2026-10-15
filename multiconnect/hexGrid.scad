/* Created by Tim Tucker

Cut generator for a hexagonal grid pattern

For a given area and constraints, it generates a grid of hexagonal cutouts optimizing the exact size for maximum surface area.

Licensed Creative Commons 4.0 Non-Commercial Sharable with Attribution (CC BY-NC-SA 4.0)

*/
include <BOSL2/std.scad>

// -------------------------------------------------------------------------
// GEOMETRY & GRID HELPERS
// -------------------------------------------------------------------------
function inverted_rounded_hex_2d(hex_r, corner_fillet) = 
    let(
        raw_hex = hexagon(r = hex_r),
        filleted = offset(r = corner_fillet, offset(r = -corner_fillet, raw_hex))
    )
    filleted;

function get_hex_px(c, r, x_shift, center_x, x_pitch, stagger_x) = 
    (c * x_pitch) + (stagger_x ? ((abs(r + x_shift) % 2) * (x_pitch / 2)) : 0) - center_x;

function get_hex_py(r, c, y_shift, center_y, y_pitch, stagger_x) = 
    (r * y_pitch) + (!stagger_x ? ((abs(c + y_shift) % 2) * (y_pitch / 2)) : 0) - center_y;

function single_hex_area(r) = 1.5 * sqrt(3) * r * r;

// Calculates total enclosed surface area for a specific radius & alignment
function eval_hex_grid_area(w, d, s, r, hex_angle = 90) = 
    let(
        norm_angle = ((hex_angle % 180) + 180) % 180,
        is_90 = (norm_angle == 90),
        stagger_x = is_90,

        x_pitch = is_90 ? (sqrt(3) * r + s) : (1.5 * r + (sqrt(3) / 2) * s),
        y_pitch = is_90 ? (1.5 * r + (sqrt(3) / 2) * s) : (sqrt(3) * r + s),

        hex_extent_x = is_90 ? (sqrt(3) / 2 * r) : r,
        hex_extent_y = is_90 ? r : (sqrt(3) / 2 * r),

        half_w = w / 2,
        half_d = d / 2,
        tol = 0.01,

        m = ceil((w + r) / x_pitch) + 1,
        n = ceil((d + r) / y_pitch) + 1,

        center_off_x = x_pitch / 2,
        center_off_y = y_pitch / 2,

        // Count complete hexes across all 4 alignment modes
        counts = [
            for (align = [0 : 3])
            let(
                sp = (align == 1 || align == 3) ? 1 : 0,
                cx = (align >= 2) ? center_off_x : 0,
                cy = (align >= 2) ? center_off_y : 0
            )
            len([
                for (row = [-n : n], col = [-m : m])
                let(
                    px = get_hex_px(col, row, sp, cx, x_pitch, stagger_x),
                    py = get_hex_py(row, col, sp, cy, y_pitch, stagger_x)
                )
                if ((abs(px) + hex_extent_x <= half_w + tol) && 
                    (abs(py) + hex_extent_y <= half_d + tol)) 1
            ])
        ],
        max_count = max(counts)
    )
    [max_count * single_hex_area(r), r];

// Finds the radius r that maximizes total complete hex surface area
function find_optimal_hex_radius(w, d, s, min_r, max_r, hex_angle = 90, samples = 100) = 
    let(
        r_step = (max_r - min_r) / samples,
        // Coarse sampling across range
        coarse_evals = [
            for (i = [0 : samples])
            let(test_r = min_r + i * r_step)
            eval_hex_grid_area(w, d, s, test_r, hex_angle)
        ],
        // Find coarse best
        max_coarse_area = max([for (e = coarse_evals) e[0]]),
        best_coarse = [for (e = coarse_evals) if (e[0] == max_coarse_area) e][0],
        coarse_r = best_coarse[1],

        // Fine resolution search around coarse optimum
        fine_min = max(min_r, coarse_r - r_step),
        fine_max = min(max_r, coarse_r + r_step),
        fine_step = (fine_max - fine_min) / 50,
        fine_evals = [
            for (i = [0 : 50])
            let(test_r = fine_min + i * fine_step)
            eval_hex_grid_area(w, d, s, test_r, hex_angle)
        ],
        max_fine_area = max([for (e = fine_evals) e[0]]),
        best_fine = [for (e = fine_evals) if (e[0] == max_fine_area) e][0]
    )
    best_fine[1];

// -------------------------------------------------------------------------
// BASE HEX GRID PATTERN MODULE
// -------------------------------------------------------------------------
module hex_grid_pattern(
    width, 
    depth, 
    height, 
    spacing, 
    corner_rounding, 
    radius, 
    skew_angle = 0, 
    hex_angle = 90, 
    debug_grid_size = false
) {
    if (debug_grid_size) {
        %cube([width, depth, height], center = true);
    }

    if (width > (radius * 2) && depth > (radius * 2)) {
        fillet_r = radius / 4;
        half_w = width / 2;
        half_d = depth / 2;

        norm_angle = ((hex_angle % 180) + 180) % 180;

        is_90 = (norm_angle == 90);
        is_30 = (norm_angle == 30 || norm_angle == 150);
        stagger_x = is_90;

        x_pitch = is_90 ? (sqrt(3) * radius + spacing) :
                  is_30 ? (1.5 * radius + (sqrt(3) / 2) * spacing) :
                          (1.5 * radius + (sqrt(3) / 2) * spacing);

        y_pitch = is_90 ? (1.5 * radius + (sqrt(3) / 2) * spacing) :
                  is_30 ? (sqrt(3) * radius + spacing) :
                          (sqrt(3) * radius + spacing);

        hex_extent_x = is_90 ? (sqrt(3) / 2 * radius) : radius;
        hex_extent_y = is_90 ? radius : (sqrt(3) / 2 * radius);

        m = ceil((width + radius) / x_pitch) + 1;
        n = ceil((depth + radius) / y_pitch) + 1;

        tol = 0.01;

        count_0 = len([
            for (r = [-n : n], c = [-m : m])
            let(
                px = get_hex_px(c, r, 0, 0, x_pitch, stagger_x),
                py = get_hex_py(r, c, 0, 0, y_pitch, stagger_x)
            )
            if ((abs(px) + hex_extent_x <= half_w + tol) && (abs(py) + hex_extent_y <= half_d + tol)) 1
        ]);

        count_1 = len([
            for (r = [-n : n], c = [-m : m])
            let(
                px = get_hex_px(c, r, 1, 0, x_pitch, stagger_x),
                py = get_hex_py(r, c, 1, 0, y_pitch, stagger_x)
            )
            if ((abs(px) + hex_extent_x <= half_w + tol) && (abs(py) + hex_extent_y <= half_d + tol)) 1
        ]);

        center_off_x = x_pitch / 2;
        center_off_y = y_pitch / 2;

        count_0_centered = len([
            for (r = [-n : n], c = [-m : m])
            let(
                px = get_hex_px(c, r, 0, center_off_x, x_pitch, stagger_x),
                py = get_hex_py(r, c, 0, center_off_y, y_pitch, stagger_x)
            )
            if ((abs(px) + hex_extent_x <= half_w + tol) && (abs(py) + hex_extent_y <= half_d + tol)) 1
        ]);

        count_1_centered = len([
            for (r = [-n : n], c = [-m : m])
            let(
                px = get_hex_px(c, r, 1, center_off_x, x_pitch, stagger_x),
                py = get_hex_py(r, c, 1, center_off_y, y_pitch, stagger_x)
            )
            if ((abs(px) + hex_extent_x <= half_w + tol) && (abs(py) + hex_extent_y <= half_d + tol)) 1
        ]);

        max_c = max(count_0, count_1, count_0_centered, count_1_centered);
        
        use_centered = (max_c == count_0_centered || max_c == count_1_centered);
        shift_parity = (max_c == count_1 || max_c == count_1_centered) ? 1 : 0;

        cx = use_centered ? center_off_x : 0;
        cy = use_centered ? center_off_y : 0;

        hex_path_2d = inverted_rounded_hex_2d(radius, fillet_r);

        for (row = [-n : n]) {
            for (col = [-m : m]) {
                px = get_hex_px(col, row, shift_parity, cx, x_pitch, stagger_x);
                py = get_hex_py(row, col, shift_parity, cy, y_pitch, stagger_x);

                if ((abs(px) + hex_extent_x <= half_w + tol) &&
                    (abs(py) + hex_extent_y <= half_d + tol)) {
                    
                    translate([px, py, 0]) {
                        skew(syz = tan(skew_angle)) {
                            rot(hex_angle) {
                                down((height + 0.02) / 2) {
                                    offset_sweep(
                                        hex_path_2d,
                                        h = height + 0.02,
                                        bottom = os_circle(r = -corner_rounding, steps = min($fn, 16)),
                                        top = os_circle(r = -corner_rounding, steps = min($fn, 16))
                                    );
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// -------------------------------------------------------------------------
// OPTIMIZED HEX GRID WRAPPER MODULE
// -------------------------------------------------------------------------
module optimized_hex_grid(
    width, 
    depth, 
    height, 
    spacing, 
    corner_rounding = 0.5, 
    min_radius = 3.0, 
    max_radius = undef, 
    skew_angle = 0, 
    hex_angle = 90, 
    debug_grid_size = false
) {
    // Automatically set maximum allowable radius if not defined
    calc_max_r = is_undef(max_radius) ? min(min_radius * 5, min(width, depth) / 2) : max_radius;

    // Calculate optimal point-to-point radius
    opt_r = find_optimal_hex_radius(
        w = width, 
        d = depth, 
        s = spacing, 
        min_r = min_radius, 
        max_r = calc_max_r, 
        hex_angle = hex_angle
    );

    echo(str("== OPTIMIZED HEX GRID =="));
    echo(str("Grid Size: ", width, " x ", depth, " mm"));
    echo(str("Wall Spacing: ", spacing, " mm"));
    echo(str("Calculated Optimal Hex Radius (R): ", opt_r, " mm"));

    // Render pattern using optimal calculated radius
    hex_grid_pattern(
        width = width,
        depth = depth,
        height = height,
        spacing = spacing,
        corner_rounding = corner_rounding,
        radius = opt_r,
        skew_angle = skew_angle,
        hex_angle = hex_angle,
        debug_grid_size = debug_grid_size
    );
}
