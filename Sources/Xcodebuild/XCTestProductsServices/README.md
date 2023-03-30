## About built XCTest products

### `.xctestrun`

It's a plist xml file. 

We can find paths to all built `.xctest` packages inside a `.xctestrun` file.

Location example:
```
<DerivedDataPath>/Build/Products/<SchemeName>_<TestPlanName>_<BuildDestination>.xctestrun
```

### `.xctest`

It's a folder built for concrete test target (e.g. `SMRunTests.xctest`).

Each `.xctest` contains:

* **`<TargetName>` executable binary **
* **`.xctestplan` files **
* `_CodeSignature` folder
* `Frameworks` folder
* `Info.plist`

Location example: 
```
<DerivedDataPath>/Build/Products/Debug-iphonesimulator/<SchemeName>-Runner.app/PlugIns/<TargetName>.xctest
```

### `.xctestplan`

It's a json file describing test plan configuration (including skipped of selected tests).

Location example: 
```
<DerivedDataPath>/Build/Products/Debug-iphonesimulator/<SchemeName>-Runner.app/PlugIns/<TargetName>.xctest/BaseTestPlan.xctestplan
```

