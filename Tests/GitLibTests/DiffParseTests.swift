import XCTest
@testable import GitLib

final class DiffParseTests: XCTestCase {
    let git = Git(path: "")
    
    func testParseDiff() {
        let diff = git.diff.parse(diffOne)
        let files = diff.files.map { $0.source }.sorted()
        let expected = [
            "adm-web/actions/TrafficRegistrationStationsActionCreator.ts",
            "adm-web/components/map/styling.ts",
            "adm-web/lib/icon.ts",
            "adm-web/lib/mapFilters.ts"
        ].sorted()
        XCTAssertEqual(expected, files)
    }
    
    static var allTests = [
        ("parseDiff", testParseDiff),
    ]
}

let diffOne = """
diff --git a/adm-web/actions/TrafficRegistrationStationsActionCreator.ts b/adm-web/actions/TrafficRegistrationStationsActionCreator.ts
index c6f00a1..88521a5 100644
--- a/adm-web/actions/TrafficRegistrationStationsActionCreator.ts
+++ b/adm-web/actions/TrafficRegistrationStationsActionCreator.ts
@@ -117,6 +117,7 @@ function toStation(e) {
     coordinateNorth: extract(e, "location", "coordinates", "utm33", "north"),
     operationalStatus: extract(e, "operationalStatus"),
     isOperationalInDatainn: extract(e, "operationalStatus") === "OPERATIONAL",
+    isRetiredInDatainn: extract(e, "operationalStatus") === "RETIRED" ||extract(e, "operationalStatus") === "PERMANENTLY_RETIRED",
     location: extract(e, "location"),
     trafficType: extract(e, "trafficType"),
     stationType: extract(e, "stationType"),
diff --git a/adm-web/components/map/styling.ts b/adm-web/components/map/styling.ts
index 81504de..a145119 100755
--- a/adm-web/components/map/styling.ts
+++ b/adm-web/components/map/styling.ts
@@ -1,7 +1,8 @@
 import filters from "../../lib/mapFilters"
 import icon from "../../lib/icon"
 
-const isOldStation = filters.and(filters.notClustered, filters.oldStation)
+const isOldStation = filters.and(filters.notClustered, filters.oldStation, filters.not(filters.retiredStation))
+const isRetiredStation = filters.and(filters.notClustered, filters.retiredStation)
 const isAlarm = filters.and(filters.notClustered, filters.alarm)
 const isPrepared = filters.and(
   filters.notClustered,
@@ -51,6 +52,10 @@ const oldStationSettings = Object.assign({}, settings, {
   externalGraphic: icon.old,
   graphicZIndex: 1,
 })
+const retiredStationSettings = Object.assign({}, settings, {
+  externalGraphic: icon.retired,
+  graphicZIndex: 1
+})
 const alarmSettings = Object.assign({}, settings, {
   graphicWidth: 15,
   graphicHeight: 15,
@@ -107,6 +112,11 @@ export default [
     symbolizer: oldStationSettings,
   }),
 
+  new OpenLayers.Rule({
+    filter: isRetiredStation,
+    symbolizer: retiredStationSettings
+  }),
+
   new OpenLayers.Rule({
     filter: isAlarm,
     symbolizer: alarmSettings,
diff --git a/adm-web/lib/icon.ts b/adm-web/lib/icon.ts
index a15bfd6..07f47ff 100755
--- a/adm-web/lib/icon.ts
+++ b/adm-web/lib/icon.ts
@@ -13,6 +13,7 @@ const exported = {
   nonOperationalTrp: "images/trp-nonoperational.svg",
   mtrp: "images/mtrp.svg",
   old: "images/old.svg",
+  retired: "images/retired.svg",
 
   forStation: function (station, alarms) {
     if (alarms && alarms.length > 0) {
@@ -33,6 +34,12 @@ const exported = {
         text: "Klargjort",
       }
     }
+    if (station.isRetiredInDatainn) {
+      return {
+        img: this.retired,
+        text: "Historisk"
+      }
+    }
 
     return {
       img: this.old,
@@ -55,6 +62,13 @@ const exported = {
       }
     }
 
+    if (trs.isRetiredInDatainn) {
+      return {
+        img: this.retired,
+        text: "Historisk"
+      }
+    }
+
     return {
       img: this.old,
       text: "Inaktiv",
diff --git a/adm-web/lib/mapFilters.ts b/adm-web/lib/mapFilters.ts
index 9f3f39c..5f8d9d8 100755
--- a/adm-web/lib/mapFilters.ts
+++ b/adm-web/lib/mapFilters.ts
@@ -53,6 +53,16 @@ Filter.OldStation = OpenLayers.Class(OpenLayers.Filter, {
     const isOperationalInDatainn = context.station?.isOperationalInDatainn ?? false
     return !isPreparedInDatainn && !isOperationalInDatainn
   },
+}),
+
+Filter.RetiredStation = OpenLayers.Class(OpenLayers.Filter, {
+  initialize: function(options) {
+    OpenLayers.Filter.prototype.initialize.apply(this, [options])
+  },
+
+  evaluate: function(context) {
+    return context.station?.isRetiredInDatainn ?? false
+  }
 })
 
 Filter.Alarm = OpenLayers.Class(OpenLayers.Filter, {
@@ -103,6 +113,7 @@ const notClustered = new Filter.Clustered({ isClustered: false })
 const prepared = new Filter.PreparedInDatainn()
 const operational = new Filter.OperationalInDatainn()
 const oldStation = new Filter.OldStation()
+const retiredStation = new Filter.RetiredStation()
 const alarm = new Filter.Alarm()
 const trafficRegistrationPoint = new Filter.TrafficRegistrationPoint()
 const manualTrafficRegistrationPoint = new Filter.ManualTrafficRegistrationPoint()
@@ -119,6 +130,7 @@ const exported = {
   prepared,
   operational,
   oldStation,
+  retiredStation,
   manualTrafficRegistrationPoint,
   trafficRegistrationPoint,
   nonOperationalTrafficRegistrationPoint,

"""
