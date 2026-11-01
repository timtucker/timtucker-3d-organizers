/*Created by Tim Tucker Low profile guide for wires 
Credits: Credit to @David D on Printables and Jonathan at Keep Making for Multiconnect and Multiboard, respectively 
@Dontic on GitHub for Multiconnect v2 code 
Andy Levesque (original scripts for rounded item holder from https://github.com/AndyLevesque/QuackWorks) 
Licensed Creative Commons 4.0 Attribution Non-Commercial Sharable with Attribution 

Change Log: 
- 2026-08-22 - Created 
- 2026-08-24 - Updated to use cutoutWidth and cutoutLength with dynamic stadium slot shape logic
*/
include <BOSL2/std.scad>

/*[Parameters]*/
// The horizontal opening width of the cutout
cutoutWidth = 5.0; // [1:0.5:30] 
// The vertical opening length of the cutout 
cutoutLength = 5.0; // [1:0.5:30] 

// How thick the guide itself is (should be larger than the cutout parameters) 
thickness = 10; // [6.5:0.5:30] 
// How many cable cutouts to create 
cutoutQuantity = 3;

/*[Multiconnect]*/
// Number of horizontal slots for the attachment (needs at least 3 to have space in between for cutouts) 
slotsWide = 4; // [3:1:20] 
// Number of vertical slots for the attachment (recommended to have at least 1/4 the item diameter) 
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
slotTolerance = 0.985; // [0.925:0.005:1.075] 
// Move the slot in (positive) or out (negative) 
slotDepthMicroadjustment = 0; // [-0.5:0.05:0.5] 
// Enable a slot on-ramp for easy mounting of tall items 
onRampEnabled = true;
// Frequency of slots for on-ramp. 1 = every slot; 2 = every 2 slots; etc. 
onRampEveryXSlots = 1;

/*[Performance]*/
// Resolution for circles and curves (higher values are smoother but slower to render) 
circleResolution = 256; // [50:50:1000]

/*[Hidden]*/
totalWidth = slotsWide * distanceBetweenSlots;
// Shortcuts for reference measurements and positions 
totalHeight = slotsHigh * distanceBetweenSlots;
cornerFillet = 4; // Radius corners 
frontChamfer = 2; // Center calculation helpers 
w_center = totalWidth / 2;
h_center = totalHeight / 2;

$fn = $preview ? 32 : 128;

module mainBody() {
  circleRes = $preview ? min(32, circleResolution) : 128;

  // Shift and rotate the finished 3D block
  translate([0, thickness, totalHeight/2])
  {
    rotate([90, 0, 0]) {
      // Rotate 90 degrees to push the Z-extrusion forward into the Y axis
      // Extrude the 2D rounded profile along the local Z-axis
      convex_offset_extrude(
        h=thickness,
        bottom=os_chamfer(height=frontChamfer), // Symmetrical linear chamfer on front
        steps=1, // 1 step is all a straight chamfer needs
      ) {
        // Core 2D Shape (The XZ front profile)
        rect([totalWidth, totalHeight], rounding=cornerFillet, $fn=circleRes);
      }
    }
  }
}

module cable_cutout(w, l) {
  cutoutCircleResolution = $preview ? min(32, circleResolution) : 128;

  let (
    shortSide = min(w, l),
    longSide = max(w, l),
    r = shortSide / 2,

    // 1. Generate the rounded slot path (list of [x,y] points)
    slot_path = rect([w, l]),

    // 2. Generate the front clearance box path
    box_path = rect([w, longSide], rounding=r, anchor=FRONT),

    // 3. Union them mathematically as paths into a single point list
    combined_path = union(slot_path, box_path)
  ) {
    translate([0, 0, -0.1]) {
      // offset_sweep takes the raw path points directly!
      offset_sweep(
        combined_path,
        height=totalHeight + 0.2,
        bottom=os_circle(r=-r), // Flares outward
        top=os_circle(r=-r), // Flares outward
        steps=15,
        $fn=cutoutCircleResolution,
        anchor=BOTTOM
      );
    }
  }
}

module cutouts() {
  usableWidth = totalWidth - distanceBetweenSlots * 2 - 5;
  // Spacing calculation adapts strictly to the width dimension profile
  cutoutSpacing = (usableWidth / (cutoutQuantity - 1)) - (cutoutWidth + min(cutoutWidth, cutoutLength) / 2);

  // Create multiple cable cutouts based on the defined quantity and spacing, centered along the width 
  translate([-( (cutoutQuantity - 1) * (cutoutWidth + cutoutSpacing)) / 2, 0, 0]) {
    for (i = [0:cutoutQuantity - 1]) {
      translate([i * (cutoutWidth + cutoutSpacing), 0, 0]) {
        cable_cutout(w=cutoutWidth, l=cutoutLength);
      }
    }
  }
}

// Assembly with cutouts and multiconnect slots 
rotate([-90, 0, 180]) {
  difference() {
    mainBody();
    cutouts();
    // Remove the slots for multiconnect 
    translate(v=[-(slotsWide * distanceBetweenSlots) / 2, 6.5, 0]) {
      createMulticonnectSlots(backWidth=totalWidth, backHeight=totalHeight, distanceBetweenSlots=distanceBetweenSlots, circleResolution=circleResolution);
    }
  }
}

//BEGIN MODULES 
//Slotted back Module 
module createMulticonnectSlots(backWidth, backHeight, distanceBetweenSlots, circleResolution = 100) {
  //slot count calculates how many slots can fit on the back. Based on internal width for buffer. 
  //slot width needs to be at least the distance between slot for at least 1 slot to generate 
  let (backWidth = max(backWidth, distanceBetweenSlots), backHeight = max(backHeight, distanceBetweenSlots), slotCount = floor(backWidth / distanceBetweenSlots), backThickness = 6.5) {
    // Loop through slots 
    for (slotNum = [0:1:slotCount - 1]) {
      // Only put slot at the first and last positions
      if (slotNum == 0 || slotNum == slotCount - 1) {
        translate(v=[distanceBetweenSlots / 2 + (backWidth / distanceBetweenSlots - slotCount) * distanceBetweenSlots / 2 + slotNum * distanceBetweenSlots, -2.35 + slotDepthMicroadjustment, backHeight - 13]) {
          slotTool(backHeight);
        }
      }
    }
  }

  // Create Slot Tool 
  module slotTool(totalHeight) {
    scale(v=slotTolerance) // Slot minus optional dimple with optional on-ramp 
    let (slotProfile = [[0, 0], [10.15, 0], [10.15, 1.2121], [7.65, 3.712], [7.65, 5], [0, 5]])
    difference() {
      union() {
        // Round top 
        rotate(a=[90, 0, 0]) {
          rotate_extrude($fn=circleResolution) {
            polygon(points=slotProfile);
          }
        }
        // Long slot 
        translate(v=[0, 0, 0]) rotate(a=[180, 0, 0]) union() {
              difference() {
                // Main half slot 
                linear_extrude(height=totalHeight + 1) {
                  polygon(points=slotProfile);
                }
                // Snap cutout 
                if (slotQuickRelease == false && multiConnectVersion == "v2") {
                  translate(v=[10.15, 0, 0]) {
                    rotate(a=[-90, 0, 0]) {
                      linear_extrude(height=5) {
                        // match slot height (5mm) 
                        polygon(points=[[0, 0], [-0.4, 0], [0, -8]]); // triangle polygon with multiconnect v2 specs 
                      }
                    }
                  }
                }
              }
              mirror([1, 0, 0]) {
                difference() {
                  // Main half slot 
                  linear_extrude(height=totalHeight + 1) {
                    polygon(points=slotProfile);
                  }
                  // Snap cutout 
                  if (slotQuickRelease == false && multiConnectVersion == "v2") {
                    translate(v=[10.15, 0, 0]) {
                      rotate(a=[-90, 0, 0]) {
                        linear_extrude(height=5) {
                          // match slot height (5mm) 
                          polygon(points=[[0, 0], [-0.4, 0], [0, -8]]); // triangle polygon with multiconnect v2 spec 
                        }
                      }
                    }
                  }
                }
              }
            }
        // On-ramp 
        if (onRampEnabled)
          for (y = [1:onRampEveryXSlots:totalHeight / distanceBetweenSlots]) {
            translate(v=[0, -5, -y * distanceBetweenSlots]) {
              rotate(a=[-90, 0, 0]) {
                cylinder(h=5, r1=12, r2=10.15);
              }
            }
          }
      }
      // Dimple 
      if (slotQuickRelease == false && multiConnectVersion == "v1") {
        scale(v=dimpleScale) {
          rotate(a=[90, 0, 0]) {
            rotate_extrude($fn=circleResolution) {
              polygon(points=[[0, 0], [0, 1.5], [1.5, 0]]);
            }
          }
        }
      }
    }
  }
}
