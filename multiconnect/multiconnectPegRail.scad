/*Created by Tim Tucker

- Modified for Multiconnect Hex Openings & Front-Inserting Markers

Credits: Credit to @David D on Printables and Jonathan at Keep Making for Multiconnect and Multiboard, respectively 
@Dontic on GitHub for Multiconnect v2 code 
Andy Levesque (original scripts for rounded item holder from https://github.com/AndyLevesque/QuackWorks) 
Licensed Creative Commons 4.0 Attribution Non-Commercial Sharable with Attribution 

Change Log: 
- 2026-08-22 - Created 
- 2026-08-24 - Updated to use cutoutWidth and cutoutLength with dynamic stadium slot shape logic
- 2026-10-31 - Replaced cable cutouts with centered counterbored hex bolt openings using BOSL2 lookup
- 2026-10-31 - Corrected edge treatment: chamfers assigned strictly to the bottom face, fillets to front and side faces
- 2026-10-31 - Added threaded bolt cap module using BOSL2 screw_hole with base taper and top ridge
- 2026-11-01 - Replaced screw-together cap/bolt with unified front-inserting Marker
- 2026-11-01 - Added double chamfers for face-down printing and a 6-point star press-fit peg with dynamic 10mm max depth
- 2026-11-01 - Replaced primitive CSG cuts with native BOSL2 cuboids with end chamfers
*/
include <BOSL2/std.scad>
include <BOSL2/screws.scad>
include <./multiconnectSlots.scad>

/*[Render Selection]*/
// Select which part to render
itemToRender = "Marker"; // ["Main Body", "Bolt Cap", "Marker", "All Assembly"]

/*[Bolt Hole Parameters]*/
// Selectable standard imperial or metric bolt size
boltSize = "1/4-20"; // ["1/4-20", "5/16-18", "3/8-16", "M3", "M4", "M5", "M6", "M8", "M10", "Custom"]

// Manual Shaft diameter override (Set to 0 to auto-calculate from boltSize lookup)
boltDiameterOverride = 0; // [0:0.05:15]

// Manual Hex head flat-to-flat width override (Set to 0 to auto-calculate from boltSize lookup)
hexFlatToFlatOverride = 0; // [0:0.1:25]

// Depth of the hex recess from the multiconnect slot floor (0 defaults to standard hex head height via BOSL2)
hexDepthOverride = 0; // [0:0.5:20]

// Multiconnect rail recess depth compensation offset
multiconnectRailDepth = 4.25;

/*[Fit Tolerances]*/
// Clearance slop for unthreaded parts (Higher value = looser fit / wider holes & thinner shaft)
boltFitSlop = -0.10; // [-5.00:0.05:0.50]
capThreadSlop = 0.2; // [0.00:0.05:0.50]

// Fine-tuning clearance offset for the star peg fins (0.00 - 0.15mm works best for press-fit)
starPegSlop = 0.10; // [0.00:0.01:0.30]

/*[Standard Bolt Cap Parameters]*/
// Total length of the exposed bolt sticking out to be covered by the cap
exposedBoltLength = 92; // [10:1:200]

// Distance from the base where the active threads start
threadsStart = 70; // [0:1:200]

// Minimum wall thickness surrounding the bolt cavity
capWallThickness = 2.5; // [1:0.5:10]

// Outer base radius of the standard cap
capBaseRadius = 9; // [5:0.5:30]

// Height of the sine-wave taper transition
taperHeight = 12; // [5:1:30]

// Fillet radius for external profile transitions on the top grip ridge
filletRadius = 0.8; // [0.1:0.1:2.0]

/*[Front-Inserting Marker Parameters]*/
// Outer radius of the marker cap head collar
markerRadius = 9; // [5:0.5:25]

// Total thickness of the exposed marker head collar
markerHeadHeight = 5; // [3:0.5:15]

// Chamfer depth on both front and back edges of the marker head
markerChamfer = 1.0; // [0.5:0.5:3.0]

// Target insertion depth into the bolt hole (dynamically limited if hole depth is smaller)
targetInsertionDepth = 10; // [3:1:20]

/*[Guide Parameters]*/
// How thick the guide itself is
thickness = 25; // [6.5:0.5:30] 

/*[Multiconnect]*/
// Number of horizontal slots for the attachment
slotsWide = 4; // [1:1:20] 
// Number of vertical slots for the attachment
slotsHigh = 1; // [1:0.5:20] 
// Version of multiconnect (dimple or snap) 
multiConnectVersion = "v2"; // [v1, v2] 
// Distance between Multiconnect slots on the back (25mm is standard for MultiBoard, 28mm for openGrid) 
distanceBetweenSlots = 28;
// QuickRelease removes the small indent in the top of the slots that lock the part into place 
slotQuickRelease = false;
// Dimple scale tweaks the size of the dimple in the slot for printers that need a larger dimple to print correctly 
dimpleScale = 1; // [0.5:0.05:1.5] 
// Scale the size of slots in the back (Use smaller values for a tighter fit. Increase if too tight.) 
slotTolerance = 1; // [0.925:0.005:1.075] 
// Move the slot in (positive) or out (negative) 
slotDepthMicroadjustment = 0; // [-0.5:0.05:0.5] 
// Enable a slot on-ramp for easy mounting of tall items 
onRampEnabled = false;
// Frequency of slots for on-ramp. 1 = every slot; 2 = every 2 slots; etc. 
onRampEveryXSlots = 1;

/*[Performance]*/
// Resolution for circles and curves (higher values are smoother but slower to render) 
circleResolution = 256; // [50:50:1000]

/*[Hidden]*/
// Query BOSL2 screw database
screwSpec = screw_info(boltSize, "hex");

// Base values extracted from BOSL2 for main body holes (Wider with higher boltFitSlop)
autoDiameter = (screwSpec.diameter != undef) ? (screwSpec.diameter + boltFitSlop) : (6.35 + boltFitSlop);
autoFlat     = (screwSpec.hex_flat != undef) ? (screwSpec.hex_flat + boltFitSlop + 0.20) : (11.11 + boltFitSlop + 0.20);
autoDepth    = (screwSpec.head_height != undef) ? screwSpec.head_height : 4.0;

// Resolve values: Use override IF greater than 0, OTHERWISE fall back to auto/default
boltDiameter  = (boltDiameterOverride  != undef && boltDiameterOverride  > 0) ? boltDiameterOverride  : autoDiameter;
hexFlatToFlat = (hexFlatToFlatOverride != undef && hexFlatToFlatOverride > 0) ? hexFlatToFlatOverride : autoFlat;
hexDepth      = (hexDepthOverride      != undef && hexDepthOverride      > 0) ? hexDepthOverride      : autoDepth;

// Log values to OpenSCAD Console
echo("========================================");
echo(str("Selected Bolt Size: ", boltSize));
echo(str("Rendered Hole Diameter: ", boltDiameter, " mm"));
echo(str("Rendered Hex Flat-to-Flat: ", hexFlatToFlat, " mm"));
echo(str("Rendered Hex Depth: ", hexDepth, " mm"));
echo(str("Active Fit Slop: ", boltFitSlop, " mm"));
echo(str("Active Star Peg Slop: ", starPegSlop, " mm"));
echo("========================================");

totalWidth = slotsWide * distanceBetweenSlots;
totalHeight = slotsHigh * distanceBetweenSlots;
cornerFillet = 4; // Radius corners 
bottomChamfer = 2; // Chamfer depth for bottom face 

$fn = $preview ? 32 : 128;

// Master Assembly Render Execution
if (itemToRender == "Main Body") {
  renderMainAssembly();
} else if (itemToRender == "Bolt Cap") {
  single_bolt_cap();
} else if (itemToRender == "Marker") {
  marker_front_insert();
} else if (itemToRender == "All Assembly") {
  renderMainAssembly();
  translate([0, thickness + capBaseRadius * 2 + 10, 0]) single_bolt_cap();
  translate([30, thickness + capBaseRadius * 2 + 10, 0]) marker_front_insert();
}

module renderMainAssembly() {
  difference() {
    mainBody();
    bolt_openings();
    
    // Remove the slots for multiconnect 
    translate(v=[-(slotsWide * distanceBetweenSlots) / 2, 6.5, 0]) {
      createMulticonnectSlots(backWidth=totalWidth, backHeight=totalHeight, distanceBetweenSlots=distanceBetweenSlots, circleResolution=circleResolution);
    }
  }
}

module mainBody() {
  circleRes = $preview ? min(32, circleResolution) : 128;

  // Shift and rotate the finished 3D block
  translate([0, thickness/2, 0])
  {
      // Extrude 2D profile along local Z-axis
      // bottom = front face (filleted), top = bottom face (chamfered)
      convex_offset_extrude(
        h=totalHeight,
        bottom=os_chamfer(height=bottomChamfer),
        top=os_circle(r=cornerFillet),
        steps=16
      ) {
        // Core 2D Shape (XZ profile)
        rect([totalWidth, thickness], rounding=cornerFillet, $fn=circleRes);
    }
  }
}

// Single bolt opening with point-up hex counterbore & top print overhang relief
module bolt_hole() {
  holeResolution = $preview ? min(32, circleResolution) : 128;
  passThroughLength = thickness - multiconnectRailDepth - hexDepth + 0.2;
  r = boltDiameter / 2;

  // 1. Point-up Hex head counterbore starting at multiconnect rail offset
  translate([0, multiconnectRailDepth - 0.105, 0]) {
    rotate([-90, 0, 0]) {
      rotate([0, 0, 30]) { // 30-degree rotation places point directly at top (+Z)
        cylinder(d=hexFlatToFlat / cos(30), h=hexDepth + 0.105, $fn=6);
      }
    }
  }

  // 2. Shaft clearance hole extending from hex pocket through front face
  translate([0, multiconnectRailDepth + hexDepth - 0.1, 0]) {
    rotate([-90, 0, 0]) {
      cylinder(d=boltDiameter, h=passThroughLength, $fn=holeResolution);
      
      // 3. Print relief slot (1mm wide x 2mm tall total, tapering last 1mm) pointing UP (+Z world space)
      linear_extrude(height=passThroughLength) {
        polygon(points=[
          [-0.5, -(r - 0.1)],
          [0.5,  -(r - 0.1)],
          [0.5,  -(r + 0)],
          [0.0,  -(r + 1.0)],
          [-0.5, -(r + 0)]
        ]);
      }
    }
  }
}

// Generate centered openings at each column and row center
module bolt_openings() {
  startX = -totalWidth / 2 + distanceBetweenSlots / 2;
  startZ = distanceBetweenSlots / 2;

  for (ix = [0 : slotsWide - 1]) {
    for (iz = [0 : floor(slotsHigh) - 1]) {
      translate([startX + ix * distanceBetweenSlots, 0, startZ + iz * distanceBetweenSlots]) {
        bolt_hole();
      }
    }
  }
}

// Single upright bolt cap module
module single_bolt_cap() {
  capHeight = exposedBoltLength + capWallThickness;
  bodyRadius = (boltDiameter / 2) + capWallThickness;
  topRidgeHeight = 6;
  baseCylinderHeight = 5;
  r_fillet = min(filletRadius, 0.8);
  
  deltaR = max(0, capBaseRadius - bodyRadius);
  taperEndHeight = baseCylinderHeight + taperHeight;
  straightBodyHeight = max(taperEndHeight, capHeight - topRidgeHeight);
  
  steps = $preview ? 16 : 32;

  // Solid Base Footing
  basePoints = [
    [0, 0],
    [capBaseRadius - 1, 0],                            // 1mm chamfer start on bottom face
    [capBaseRadius, 1],                                // 1mm chamfer top
    [capBaseRadius, baseCylinderHeight],               // Top outer corner of 5mm base cylinder
    [0, baseCylinderHeight]                            // Center axis top point
  ];

  // Upper Cap Outer Profile
  sineTaperPoints = [
    for (i = [0 : steps]) let (
      t = i / steps,
      z = baseCylinderHeight + t * taperHeight,
      curRadius = bodyRadius + deltaR * (1 + cos(t * 180)) / 2
    ) [curRadius, z]
  ];

  topPoints = [
    [bodyRadius, straightBodyHeight],
    [bodyRadius + 2, straightBodyHeight + 2],
    [bodyRadius + 2, straightBodyHeight + 4],
    [bodyRadius, straightBodyHeight + 6],
    [0, capHeight]
  ];

  rawUpperPoints = concat(sineTaperPoints, topPoints);

  topRadii = [r_fillet, r_fillet, r_fillet, r_fillet, 0];
  sineRadii = [for (i = [0 : len(sineTaperPoints)-1]) 0];
  upperRadii = concat(sineRadii, topRadii);

  upperProfile = round_corners(rawUpperPoints, r=upperRadii);
  upperClosedPath = concat([[0, baseCylinderHeight]], upperProfile, [[0, capHeight]]);

  difference() {
    // Solid Outer Shell
    union() {
      rotate_extrude($fn=circleResolution) polygon(points=basePoints);
      rotate_extrude($fn=circleResolution) polygon(points=upperClosedPath);
    }

    // 1. Threaded Cavity
    translate([0, 0, threadsStart]) {
      screw_hole(
        spec = boltSize,
        length = max(1, exposedBoltLength - threadsStart + 0.1),
        thread = true,
        counterbore = 0,
        bevel = false,
        $slop = capThreadSlop,
        orient = UP,
        anchor = BOTTOM,
        $fn = $preview ? 32 : 64
      );
    }

    // 2. Unthreaded Clearance Hole
    translate([0, 0, -0.01]) {
      screw_hole(
        spec = boltSize,
        length = threadsStart + 0.02,
        thread = false,
        counterbore = 0,
        bevel = true,
        $slop = boltFitSlop,
        orient = UP,
        anchor = BOTTOM,
        $fn = $preview ? 32 : 64
      );
    }
  }
}

// Unified Front-Inserting Marker Module
module marker_front_insert() {
  h = markerHeadHeight;
  r = markerRadius;
  c = markerChamfer;

  // Max hole pass-through depth
  passThroughLength = thickness - multiconnectRailDepth - hexDepth;
  
  // Peg inserts 10mm (or less if total available hole depth is smaller)
  pegLength = min(targetInsertionDepth, max(3, passThroughLength));
  
  // Span width calibrated for a snug press-fit against the bolt hole ID
  barSpan = boltDiameter + 0.10 - starPegSlop;
  barThick = max(1.0, min(1.5, boltDiameter * 0.20));

  // Double chamfer profile for marker head collar (Chamfer on both front & back faces)
  headProfile = [
    [0, 0],
    [r - c, 0],                                        // Start front 1mm chamfer
    [r, c],                                            // End front chamfer
    [r, h - c],                                        // Start back 1mm chamfer
    [r - c, h],                                        // End back chamfer
    [0, h]                                             // Center axis top point
  ];

  union() {
    // 1. Double-Chamfered Marker Head Collar (Prints flat face down at Z=0)
    rotate_extrude($fn=circleResolution) {
      polygon(points=headProfile);
    }

    // 2. 3 Intersecting BOSL2 Cuboids at 0°, 60°, and 120° with 2mm Tip Chamfers
    translate([0, 0, h]) {
      for (a = [0, 60, 120]) {
        rotate([0, 0, a]) {
          // BOSL2 cuboid anchored at BOTTOM center (+Z direction)
          // Top outer edges (+X and -X at Z=pegLength) receive a 2mm chamfer
          cuboid(
            [barSpan, barThick, pegLength],
            anchor = BOTTOM,
            chamfer = 1.5,
            edges = [TOP + RIGHT, TOP + LEFT]
          );
        }
      }
    }
  }
}