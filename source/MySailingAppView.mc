import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.Timer;
import Toybox.Time;
import Toybox.Math;
import Toybox.ActivityRecording;
using Toybox.FitContributor as Fit;


class MySailingAppView extends WatchUi.View {

    // Field ids
    private enum FieldId {
        HDG_FIELD_ID,
        COG_FIELD_ID,
        SOG_FIELD_ID
    }

    // Declare all variables here
    private var _hdg as Numeric;
    private var _cog as Numeric;
    private var _sog as Numeric;

    private var _gpsColor = Graphics.COLOR_WHITE;
    private var _recColor = Graphics.COLOR_GREEN;

    private var _dataTimer as Timer.Timer?;
    private var _session as Session?;

    const _BUFFER_SIZE = 25;

    var hdg_buffer = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    var cog_buffer = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    var sog_buffer = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];

    var hdg_buffer_idx = 0;
    var cog_buffer_idx = 0;
    var sog_buffer_idx = 0;

    private var _hdgField;
    private var _cogField;
    private var _sogField;

    const scale_mps_2_kn = 1.94384;


    //! Constructor
    public function initialize() {
        View.initialize();

        // Initialize our members
        _hdg = 0;
        _cog = 0;
        _sog = 0;
        
    }


    //! Start recording a session
    public function startRecording() as Void {
        _session = ActivityRecording.createSession({:name=>"MySailing", :sport=>ActivityRecording.SPORT_SAILING});
        _session.start();

        // Create some custom FIT data fields to be recorded
        _hdgField = _session.createField("HDG", HDG_FIELD_ID, Fit.DATA_TYPE_FLOAT, {:mesgType=>Fit.MESG_TYPE_RECORD, :units=>"°"});
        _cogField = _session.createField("COG", COG_FIELD_ID, Fit.DATA_TYPE_FLOAT, {:mesgType=>Fit.MESG_TYPE_RECORD, :units=>"°"});
        _sogField = _session.createField("SOG", SOG_FIELD_ID, Fit.DATA_TYPE_FLOAT, {:mesgType=>Fit.MESG_TYPE_RECORD, :units=>"kn"});

        _hdgField.setData(0);
        _cogField.setData(0);
        _sogField.setData(0);

        _recColor = Graphics.COLOR_RED;
        WatchUi.requestUpdate();
    }

    
    
    //! Stop the recording if necessary
    public function stopRecording() as Void {
        var session = _session;
        if (isSessionRecording() && (session != null)) {
            session.stop();
            session.save();
            _session = null;

            _recColor = Graphics.COLOR_GREEN;
            WatchUi.requestUpdate();
        }
    }


    //! Get whether a session is currently recording
    //! @return true if there is a session currently recording, false otherwise
    public function isSessionRecording() as Boolean {
        if (_session != null) {
            return _session.isRecording();
        }
        return false;
    }


    // Load your resources here
    public function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));

        _dataTimer = new Timer.Timer();
        _dataTimer.start(method(:timerCallback), 200, true);
    }


    // Updating the GPS qualiy info by coloring the text "GPS"
    function updateGpsQuality(p_info) as Void {
        var quality = p_info.accuracy;
        if (quality == Position.QUALITY_GOOD) {
            _gpsColor = Graphics.COLOR_GREEN;
        } else if (quality == Position.QUALITY_USABLE) {
            _gpsColor = Graphics.COLOR_YELLOW;
        } else if (quality == Position.QUALITY_POOR) {
            _gpsColor = Graphics.COLOR_ORANGE;
        } else if (quality == Position.QUALITY_LAST_KNOWN) {
            _gpsColor = Graphics.COLOR_RED;
        } else if (quality == Position.QUALITY_NOT_AVAILABLE) {
            _gpsColor = Graphics.COLOR_WHITE;
            return;
        }

        WatchUi.requestUpdate();
    }


    //! On a timer interval, read the accelerometer
    //! and update the ball position
    public function timerCallback() as Void {
        var s_info = Sensor.getInfo();
        var p_info = Position.getInfo();
        var value = 0;
        var results;

        // Update the magnetic heading
        if (s_info has :heading && s_info.heading != null) {
            value = s_info.heading * 180 / Math.PI;
            if (value < 0){
                value = 360 + value;
            }

            results = moving_average(hdg_buffer, hdg_buffer_idx, value);
            hdg_buffer = results[0];
            hdg_buffer_idx = results[1];
            _hdg = results[2];
            
            System.println("HDG: " + value);
            System.println("HDG_avg: " + _hdg);
        }


        // Update the GPS Course over Ground (heading)
        if (p_info has :heading && p_info.heading != null) {
            value = p_info.heading * 180 / Math.PI;
            if (value < 0){
                value = 360 + value;
            }

            results = moving_average(cog_buffer, cog_buffer_idx, value);
            cog_buffer = results[0];
            cog_buffer_idx = results[1];
            _cog = results[2];

            System.println("COG: " + value);
            System.println("COG_avg: " + _cog);
        }

        // Update the GPS Speed over Ground
        if (p_info has :speed && p_info.speed != null) {
            value = p_info.speed * scale_mps_2_kn;

            results = moving_average(sog_buffer, sog_buffer_idx, value);
            sog_buffer = results[0];
            sog_buffer_idx = results[1];
            _sog = results[2];

            System.println("SOG: " + value.format("%04.1f"));
            System.println("SOG_avg: " + _sog.format("%04.1f"));
        }

        // Update the watch screen
        WatchUi.requestUpdate();
    }


    public function moving_average(buffer, buffer_idx, value) {  
        var sum = 0;
        var i;
        buffer[buffer_idx] = value;
        buffer_idx = (buffer_idx + 1) % _BUFFER_SIZE;
        for (i = 0; i < _BUFFER_SIZE; i++) {
            sum += buffer[i];
        }
        value = sum / _BUFFER_SIZE;
        return [buffer, buffer_idx, value];
    }


    public function compute() {
        // Log values in the custom FIT fields
        _hdgField.setData(_hdg);
        _cogField.setData(_cog);
        _sogField.setData(_sog);
    }


    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    public function onShow() as Void {
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    public function onHide() as Void {
    }

    // Update the view
    public function onUpdate(dc as Dc) as Void {        

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        // Draw red separation lines
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);

        // Horizontal line - long
        dc.drawLine(0, 120, 240, 120);

        // Horizontal line - short
        dc.drawLine(0, 210, 240, 210);

        // Vertical line
        dc.drawLine(120, 120, 120, 210);   

        // Draw a circle for the GPS signal quality
        dc.setColor(_gpsColor, Graphics.COLOR_BLACK);
        dc.fillCircle(120, 240, 18);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillCircle(120, 240, 15);

        // Draw a circle for the activity tracking state
        dc.setColor(_recColor, Graphics.COLOR_BLACK);
        dc.fillCircle(120, 240, 10);

        var hdgText = View.findDrawableById("hdg") as Text;  
        var cogText = View.findDrawableById("cog") as Text; 
        var sogText = View.findDrawableById("sog") as Text; 

        hdgText.setText(_hdg.format("%03d"));
        cogText.setText(_cog.format("%03d"));
        sogText.setText(_sog.format("%04.1f"));

    }    
}
