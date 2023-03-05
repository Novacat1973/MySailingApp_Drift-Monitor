import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;
import Toybox.WatchUi;

class MySailingAppApp extends Application.AppBase {

    private var _mysailingView as MySailingAppView;

    //! Constructor
    public function initialize() {
        AppBase.initialize();
        _mysailingView = new $.MySailingAppView();
    }

    //! Handle app startup and enable location events to make sure GPS is on
    //! @param state Startup arguments
    public function onStart(state as Dictionary?) as Void {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    //! Handle app shutdown
    //! @param state Shutdown arguments
    public function onStop(state as Dictionary?) as Void {
        if (_mysailingView != null){
            _mysailingView.stopRecording();
        }
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    //! Update the current position
    //! @param info Position information
    public function onPosition(p_info as Info) as Void {
        _mysailingView.updateGpsQuality(p_info);
    }

    //! Return the initial view for the app
    //! @return Array [View]
    public function getInitialView() as Array<Views or InputDelegates>? {
        return [_mysailingView, new $.MySailingAppAppDelegate(_mysailingView)] as Array<Views or InputDelegates>;
    }

}
