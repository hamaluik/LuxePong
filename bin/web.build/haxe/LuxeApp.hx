import Main;

import luxe.Core;
import luxe.AppConfig;

import snow.Snow;
import snow.types.Types;

class LuxeApp {

    public static var _game : Main;
    public static var _core : Core;
    public static var _snow : Snow;
    public static var _conf : AppConfig;

    public static function main () {

        //Start with sane defaults

        _conf = {
            window: {
                width: 960,
                height: 640,
                fullscreen: false,
                resizable: true,
                borderless: false,
                title: 'luxe app'
            }
        } //_conf

        #if mobile
            _conf.window.fullscreen = true;
            _conf.window.borderless = true;
        #end //mobile

        

            //Create the runtime
        _snow = new Snow();
            //Create the app class, give it to the bootstrapper
        _game = new Main();
            //Create the core luxe runtime
        _core = new Core( _game, _conf );

        var _snow_config : SnowConfig = {
            has_loop : true,
            config_custom_assets : false,
            config_custom_runtime : false,
            config_runtime_path : 'config.json',
            config_assets_path : 'manifest',
            app_package : 'com.blazingmammothgames.luxe'
        };

            //Start up, giving luxe as the host
        _snow.init( _snow_config, _core );

    } //main

} //LuxeApp