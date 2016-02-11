component output="false" {
	property name="resourceBundleService"  inject="resourceBundleService";
	property name="i18n"                   inject="coldbox:plugin:i18n";

	public string function index( event, rc, prc, args={} ) output=false {
		var args.values = [];
		var locales = listtoarray(Server.Coldfusion.SupportedLocales);
		for ( locale in locales ){
  			if(!findnocase('##',locale)){
  				var oldlocale = SetLocale(locale);
  				var currency = LSCurrencyFormat( 10, "local" );
  				args.values.append(locale&'-'&currency);
			}
		}
		return renderView( view="formcontrols/select/index", args=args );
	}
}
