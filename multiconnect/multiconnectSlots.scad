/* 

Credits:
    Credit to @David D on Printables and Jonathan at Keep Making for Multiconnect and Multiboard, respectively
    @Dontic on GitHub for Multiconnect v2 code

Licensed Creative Commons 4.0 Non-Commercial Sharable with Attribution (CC BY-NC-SA 4.0)

*/

//BEGIN MODULES 
//Slotted back Module 
module createMulticonnectSlots(backWidth, backHeight, distanceBetweenSlots, circleResolution = 100) {
  let (backWidth = max(backWidth, distanceBetweenSlots), backHeight = max(backHeight, distanceBetweenSlots), slotCount = floor(backWidth / distanceBetweenSlots), backThickness = 6.5) {
    for (slotNum = [0:1:slotCount - 1]) {
        translate(v=[distanceBetweenSlots / 2 + (backWidth / distanceBetweenSlots - slotCount) * distanceBetweenSlots / 2 + slotNum * distanceBetweenSlots, -2.35 + slotDepthMicroadjustment, backHeight - 13]) {
          slotTool(backHeight);
        }
    }
  }

  module slotTool(totalHeight) {
    scale(v=slotTolerance)
    let (slotProfile = [[0, 0], [10.15, 0], [10.15, 1.2121], [7.65, 3.712], [7.65, 5], [0, 5]])
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
}