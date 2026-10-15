/* Created by Tim Tucker

Parametric 4-Corner Item Holder for Multiconnect

Note that the defaults for Multiconnect slot tolerance are set smaller than 1.0 to more tightly grab onto each corner.

Credits:
    Credit to @David D on Printables and Jonathan at Keep Making for Multiconnect and Multiboard, respectively
    @Dontic on GitHub for Multiconnect v2 code
    @AndyLevesque on GitHub for item holder designs as inspiration / initial basis

Licensed Creative Commons 4.0 Non-Commercial Sharable with Attribution (CC BY-NC-SA 4.0)

*/
include <BOSL2/std.scad>

/*[Item Dimensions]*/
// Width of the target item to hold (X axis)
itemWidth = 75.0; // [20:1:500]
// Height of the target item to hold (Z axis)
itemHeight = 75.0; // [55:1:500]
// Depth (thickness) of the target item (Y axis)
itemDepth = 25.0; // [10:1:200]

/*[Support Geometry]*/
// Minimum wall thickness for structural support (default 6mm)
minWallThickness = 6.0; // [1:0.5:10]
// Thickness of the support in front of the pocket (default 3mm)
frontSupportThickness = 3.0; // [1:0.5:10]
// Extension of front retention lip overlapping the item corner (default 8mm)
extension = 8.0; // [1:1:100]
// Clearance/gap between the back mount plate and the item rear face (default 5mm)
standoffDistance = 5.0; // [0:1:50]
// Extra fit clearance around the item bounds inside the pocket
itemClearance = 0.5; // [0:0.1:2]

/*[Support Tabs]*/
// Enable diagonal corner support tabs
enableSupportTabs = true;
// Extension length of support tabs beyond the corner meeting point
tabLength = 10.0; // [5:1:100]
// Width of support tabs (default 10mm)
tabWidth = 10.0; // [5:1:100]

/*[Multiconnect Settings]*/
// Force horizontal slot count (0 = Auto-calculate based on item size & walls)
userSlotsWide = 0; // [0:1:4]
// Force vertical slot count (0 = Auto-calculate based on item size & walls)
userSlotsHigh = 0; // [0:1:4]
// Multiconnect slot spacing (25mm = MultiBoard, 28mm = openGrid)
distanceBetweenSlots = 28.0;
// Version of multiconnect slot cutouts
multiConnectVersion = "v2"; // [v1, v2]
// QuickRelease removes slot locking indents
slotQuickRelease = false;
// Dimple scale tweaks size for printer tolerance
dimpleScale = 1.0; // [0.5:0.05:1.5]
// Scale of slots for fit tolerance
slotTolerance = 0.985; // [0.925:0.005:1.075]
// Slot depth offset
slotDepthMicroadjustment = 0.0; // [-0.5:0.05:0.5]
// Enable a slot on-ramp for easy mounting
onRampEnabled = true;
// Frequency of slots for on-ramp
onRampEveryXSlots = 1;

/*[Display Controls]*/

// Enable preview mode (disable when rendering to print)
previewMode = true;

// Show the item preview in the render
itemPreview = true;

/*[Performance]*/
circleResolution = 128; // [32:32:256]

/*[Hidden]*/
$fn = $preview ? 32 : circleResolution;

// Backing plate depth reserved for Multiconnect slots
multiconnectBackThickness = 6.5;

// Half slot reference
halfSlot = distanceBetweenSlots / 2.0;

// Pocket edge positions from assembly center
pocketXEdge = (itemWidth / 2.0) + itemClearance;
pocketZEdge = (itemHeight / 2.0) + itemClearance;

// Calculate grid slot count based purely on item dimensions
rawGridUnitsX = max(1, round(itemWidth / distanceBetweenSlots));
rawGridUnitsZ = max(1, round(itemHeight / distanceBetweenSlots));

// Grid offsets for bracket placement
gridXOffset = (floor(rawGridUnitsX / 2.0) * distanceBetweenSlots) + halfSlot;
gridZOffset = (floor(rawGridUnitsZ / 2.0) * distanceBetweenSlots) + halfSlot;

// Physical vertical span from grid anchor to the inner retention lip edge
physicalVerticalSpan = abs(pocketZEdge - gridZOffset) + minWallThickness;
requiredHorizontalSpan = extension + minWallThickness + itemClearance;

// Automatic slot counts per bracket
autoSlotsWide = max(1, ceil(requiredHorizontalSpan / distanceBetweenSlots));
autoSlotsHigh = max(1, ceil(physicalVerticalSpan / distanceBetweenSlots));

slotsWide = (userSlotsWide > 0) ? userSlotsWide : autoSlotsWide;
slotsHigh = (userSlotsHigh > 0) ? userSlotsHigh : autoSlotsHigh;

// Dynamic bracket backing dimensions
mountPlateW = slotsWide * distanceBetweenSlots;
mountPlateH = slotsHigh * distanceBetweenSlots;

totalFrontDepth = itemDepth + frontSupportThickness + standoffDistance + itemClearance;
totalBracketDepth = multiconnectBackThickness + totalFrontDepth;

// Grid size bounds (+1 extra cell around the perimeter)
gridSlotsX = (ceil(gridXOffset / distanceBetweenSlots) * 2) + slotsWide + 1;
gridSlotsZ = (ceil(gridZOffset / distanceBetweenSlots) * 2) + slotsHigh + 1;

// --- Multiconnect Slot Tool ---
module slotTool(totalHeight) {
  scale(v=slotTolerance) let (slotProfile = [[0, 0], [10.15, 0], [10.15, 1.2121], [7.65, 3.712], [7.65, 5], [0, 5]])
  difference() {
    union() {
      rotate(a=[90, 0, 0]) {
        rotate_extrude($fn=circleResolution) {
          polygon(points=slotProfile);
        }
      }
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
      if (onRampEnabled)
        for (y = [1:onRampEveryXSlots:totalHeight / distanceBetweenSlots]) {
          translate(v=[0, -5, -y * distanceBetweenSlots]) {
            rotate(a=[-90, 0, 0]) {
              cylinder(h=5, r1=12, r2=10.15);
            }
          }
        }
    }
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

// Multi-slot subtraction generator with directional positioning
module multiconnectSlotsBack(backWidth, backHeight, isTopCorner = false) {
  for (sX = [0:slotsWide - 1]) {
    for (sZ = [0:slotsHigh - 1]) {
      xPos =
        (slotsWide == 1) ? 0
        : -(backWidth / 2) + (distanceBetweenSlots / 2) + (sX * distanceBetweenSlots);

      zPos =
        isTopCorner ? -(backHeight / 2) + (distanceBetweenSlots / 2) + (sZ * distanceBetweenSlots)
        : (backHeight / 2) - (distanceBetweenSlots / 2) - (sZ * distanceBetweenSlots);

      translate([xPos, -2.35 + slotDepthMicroadjustment, zPos])
        slotTool(totalHeight=distanceBetweenSlots);
    }
  }
}

// --- Corner Bracket Module ---

module cornerBracket(isTopCorner = false, isRightCorner = false) {
  outerAnchorX = isRightCorner ? RIGHT : LEFT;
  outerAnchorZ = isTopCorner ? TOP : BOTTOM;
  outerAnchor = outerAnchorX + outerAnchorZ;

  bracketCenterX = isRightCorner ? gridXOffset : -gridXOffset;
  bracketCenterZ = isTopCorner ? gridZOffset : -gridZOffset;

  globalPocketEdgeX = (isRightCorner ? 1 : -1) * pocketXEdge;
  globalPocketEdgeZ = (isTopCorner ? 1 : -1) * pocketZEdge;

  localPocketEdgeX = globalPocketEdgeX - bracketCenterX;
  localPocketEdgeZ = globalPocketEdgeZ - bracketCenterZ;

  supportWidth = extension + minWallThickness + itemClearance;
  supportOuterX = localPocketEdgeX + (isRightCorner ? minWallThickness : -minWallThickness);
  supportInnerX = supportOuterX + (isRightCorner ? -supportWidth : supportWidth);

  plateCenterZOffset = isTopCorner ? (mountPlateH / 2 - halfSlot) : -(mountPlateH / 2 - halfSlot);
  
  // Dynamic outer support boundary
  requiredOuterZ = localPocketEdgeZ + (isTopCorner ? minWallThickness : -minWallThickness);
  supportOuterZ = isTopCorner ? max(halfSlot, requiredOuterZ) : min(-halfSlot, requiredOuterZ);

  innerLipZ = localPocketEdgeZ - (isTopCorner ? extension : -extension);
  supportHeight = abs(supportOuterZ - innerLipZ);

  pocketD = itemDepth + itemClearance;
  pocketY = standoffDistance + (pocketD / 2);

  // Dynamic X-axis backing plate boundaries
  outerBoundX = isRightCorner ? max(mountPlateW / 2.0, supportOuterX) : min(-mountPlateW / 2.0, supportOuterX);
  innerBoundX = isRightCorner ? min(-mountPlateW / 2.0, supportInnerX) : max(mountPlateW / 2.0, supportInnerX);

  backerWidth = abs(outerBoundX - innerBoundX);
  backerXOffset = (outerBoundX + innerBoundX) / 2.0;

  // Dynamic Z-axis backing plate boundaries
  slotPlateTopZ = plateCenterZOffset + (mountPlateH / 2.0);
  slotPlateBottomZ = plateCenterZOffset - (mountPlateH / 2.0);

  outerBoundZ = max(slotPlateTopZ, supportOuterZ, innerLipZ);
  innerBoundZ = min(slotPlateBottomZ, supportOuterZ, innerLipZ);

  backerHeight = abs(outerBoundZ - innerBoundZ);
  backerZOffset = (outerBoundZ + innerBoundZ) / 2.0;

  // Fillets relative to actual backing plate edges
  outerEdgeGap = abs(outerBoundX - supportOuterX);
  innerEdgeGap = abs(innerBoundX - supportInnerX);
  calculatedOuterFillet = min(standoffDistance, outerEdgeGap, 10);
  calculatedInnerFillet = min(standoffDistance, innerEdgeGap, 10);

  alignSide = isRightCorner ? RIGHT : LEFT;
  outerFilletSpin = isRightCorner ? 0 : 90;
  innerFilletSpin = isRightCorner ? 90 : 0;

  dirX = isRightCorner ? -1 : 1;
  dirZ = isTopCorner ? -1 : 1;

  tabCenterY = (totalFrontDepth / 2) - (multiconnectBackThickness / 2);
  tabAngleY = isTopCorner ? (isRightCorner ? 45 : -45) : (isRightCorner ? -45 : 45);

  difference() {
    union() {
      // 1. Dynamic Backing Plate
      translate([backerXOffset, -multiconnectBackThickness / 2, backerZOffset])
        cuboid([backerWidth, multiconnectBackThickness, backerHeight], anchor=CENTER);

      // 2. Front Support Extension
      translate([supportOuterX, (totalFrontDepth / 2), supportOuterZ]) {
        cuboid([supportWidth, totalFrontDepth, supportHeight], anchor=outerAnchor) {

          if (calculatedOuterFillet > 0.05) {
            position(alignSide + FRONT)
              fillet(
                l=supportHeight,
                r=calculatedOuterFillet,
                spin=outerFilletSpin,
                orient=UP
              );
          }

          if (calculatedInnerFillet > 0.05) {
            position(-alignSide + FRONT)
              fillet(
                l=supportHeight,
                r=calculatedInnerFillet,
                spin=innerFilletSpin,
                orient=UP
              );
          }
        }
      }

      // 3. Support Tab with Buried Inward Axis-Aligned Clipping
      if (enableSupportTabs) {
        // Distance from outer wall to inner lip corner along 45-deg diagonal
        supportToLipDiag = (minWallThickness + extension) * sqrt(2);

        // Total span: Outer support wall -> across extension lip -> tabLength inward
        totalTabLength = supportToLipDiag + tabLength;

        // Outer wall anchor
        outerWallStartX = localPocketEdgeX - (dirX * minWallThickness);
        outerWallStartZ = localPocketEdgeZ - (dirZ * minWallThickness);

        // Center position along diagonal moving inward
        tabCenterX = outerWallStartX + (dirX * (totalTabLength / 2.0) * cos(45));
        tabCenterZ = outerWallStartZ + (dirZ * (totalTabLength / 2.0) * sin(45));

        innerEdgesToRound = isTopCorner ? [BOTTOM + RIGHT, BOTTOM + LEFT] : [TOP + RIGHT, TOP + LEFT];

        clipBoxSize = totalTabLength * 3;
        inwardShift = minWallThickness / 2.0;

        // Clip boundaries explicitly shifted INWARD toward the item pocket
        clipBoundX = isRightCorner ? (supportOuterX - inwardShift) : (supportOuterX + inwardShift);
        clipBoundZ = isTopCorner   ? (supportOuterZ - inwardShift) : (supportOuterZ + inwardShift);

        difference() {
          // Main tab with 1/3 tabWidth inner edge rounding
          translate([tabCenterX, tabCenterY, tabCenterZ]) {
            rotate([0, tabAngleY, 0]) {
              cuboid(
                [tabWidth, totalFrontDepth + multiconnectBackThickness, totalTabLength], 
                anchor = CENTER, 
                rounding = tabWidth / 3, 
                edges = innerEdgesToRound
              );
            }
          }

          // Cut everything past clipBoundX outward in X
          translate([
            clipBoundX + (isRightCorner ? clipBoxSize / 2 : -clipBoxSize / 2),
            tabCenterY,
            tabCenterZ
          ])
            cuboid([clipBoxSize, totalFrontDepth + multiconnectBackThickness + 5, clipBoxSize], anchor = CENTER);

          // Cut everything past clipBoundZ outward in Z
          translate([
            tabCenterX,
            tabCenterY,
            clipBoundZ + (isTopCorner ? clipBoxSize / 2 : -clipBoxSize / 2)
          ])
            cuboid([clipBoxSize, totalFrontDepth + multiconnectBackThickness + 5, clipBoxSize], anchor = CENTER);
        }
      }
    }

    // Subtractions
    translate([0, 0, plateCenterZOffset])
      multiconnectSlotsBack(backWidth=mountPlateW, backHeight=mountPlateH, isTopCorner=isTopCorner);

    translate([localPocketEdgeX, pocketY, localPocketEdgeZ])
      cuboid([mountPlateW * 4, pocketD, mountPlateH * 4], anchor=outerAnchor);
  }
}

// Ghost preview box for reference item
module ghostItem() {
  if (itemPreview) {
    itemCenterY = standoffDistance + (itemDepth / 2);
    color("grey", 0.5) {
      translate([0, itemCenterY, 0])
        if ($preview) {
          %cube([itemWidth, itemDepth, itemHeight], center=true);
        }
        // Fallback because Makerworld preview doesn't support transparent objects
        else {
          cube([itemWidth, itemDepth, itemHeight], center=true);
        }
    }
  }
}

// Background Grid Overlay
module backgroundGrid() {
  gridW = gridSlotsX * distanceBetweenSlots;
  gridH = gridSlotsZ * distanceBetweenSlots;
  lineThick = 0.8;

  translate([0, -6.5, 0]) {
    color("red", 0.6) {
      for (x = [-gridSlotsX / 2:1:gridSlotsX / 2]) {
        translate([(x * distanceBetweenSlots), 0, 0])
          cube([lineThick, lineThick, gridH], center=true);
      }
      for (z = [-gridSlotsZ / 2:1:gridSlotsZ / 2]) {
        translate([0, 0, (z * distanceBetweenSlots)])
          cube([gridW, lineThick, lineThick], center=true);
      }
    }
  }
}

// --- Main Assembly ---

module fullAssembly() {
  if (previewMode) {
    backgroundGrid();
    ghostItem();

    // Bottom Left
    translate([-gridXOffset, 0, -gridZOffset])
      cornerBracket(isTopCorner=false, isRightCorner=false);

    // Bottom Right
    translate([gridXOffset, 0, -gridZOffset])
      cornerBracket(isTopCorner=false, isRightCorner=true);

    // Top Left
    translate([-gridXOffset, 0, gridZOffset])
      cornerBracket(isTopCorner=true, isRightCorner=false);

    // Top Right
    translate([gridXOffset, 0, gridZOffset])
      cornerBracket(isTopCorner=true, isRightCorner=true);
  } else {
    // --- Print Bed Layout ---
    spacingZ = 15.0;
    printYOffset = (totalBracketDepth * 2) + spacingZ;

    // Bottom Left
    translate([-gridXOffset, 0, 0])
      cornerBracket(isTopCorner=false, isRightCorner=false);

    // Bottom Right
    translate([gridXOffset, 0, 0])
      cornerBracket(isTopCorner=false, isRightCorner=true);

    // Top Left
    translate([-gridXOffset, printYOffset, 0])
      rotate([180, 0, 0])
        cornerBracket(isTopCorner=true, isRightCorner=false);

    // Top Right
    translate([gridXOffset, printYOffset, 0])
      rotate([180, 0, 0])
        cornerBracket(isTopCorner=true, isRightCorner=true);
  }
}

fullAssembly();
