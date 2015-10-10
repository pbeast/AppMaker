#import "SnapshotHelper.js"

var target = UIATarget.localTarget();
var app = target.frontMostApp();
var window = app.mainWindow();

target.frontMostApp().mainWindow().buttons()["Button"].tap();
target.frontMostApp().mainWindow().staticTexts()["Label"].tapWithOptions({tapOffset:{x:0.51, y:0.29}});

target.delay(3)
captureLocalizedScreenshot("0-LandingScreen")