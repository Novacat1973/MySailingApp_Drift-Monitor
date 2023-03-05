using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;


class MySailingAppAppDelegate extends Ui.BehaviorDelegate {

    private var _view as MySailingAppView;

    public function initialize(view as MySailingAppView) {
        BehaviorDelegate.initialize();
        _view = view;
    } 	
 
    public function onKeyPressed(evt) {
        var key = evt.getKey();
        if (Toybox has :ActivityRecording && key == 4) { // on Start button
            if (!_view.isSessionRecording()) {
                _view.startRecording();
                System.println("Recording started");
            } else {
                _view.stopRecording();
                System.println("Recording stopped");

            }
        }	
        return true;
    }   
}
