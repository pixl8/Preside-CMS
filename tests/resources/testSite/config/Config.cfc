component extends="preside.system.config.Config" output=false {

	public void function configure() output=false {
		super.configure();

		settings.dsn            = "preside_test_suite";
		settings.system_users   = "sysadmin";
		settings.default_locale = "en";
	}
}