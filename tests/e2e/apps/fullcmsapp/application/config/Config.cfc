component extends="preside.system.config.Config" {

	// TIP: There is a LOT that is configurable here and we have
	// provided some examples, below, and a basic setup. Open up
	// /preside/system/config/Config.cfc to see all the core configuration
	// that can be modified and extended

// CORE COLDBOX CONFIGURE METHOD(S)
	public void function configure() {
		super.configure(); // must come FIRST to load core preside config

		_setupCommonSettings();
		_setupRicheditor();
		_setupAssetManager();
		_setupAssetDerivatives();
		_setupFeatures();
		_setupLauncher();
		_setupCustomAdminNavigation();
		_setupInterceptors();
		_setupLogboxLoggers();
	}

	public void function local() {
		super.local();

		coldbox.handlersIndexAutoReload = settings.env.handlersIndexAutoReload ?: true;
		coldbox.handlerCaching          = settings.env.handlerCaching          ?: false;
		settings.autoSyncDb             = settings.env.autoSyncDb              ?: true;
		settings.showerrors             = settings.env.showErrors              ?: true;

		/*
			Put your local environment overrides, here.
			See Coldbox environment docs:
		    	https://coldbox.ortusbooks.com/getting-started/configuration/coldbox.cfc/configuration-directives/environments

			Preside core attempts to autodetect a 'local'
			environment for URLs matching patterns: 127.0.0.1, localhost, mysite.local, local.mysite.

			You can change this by setting environments.local = [ "somethingelse" ]; in your Configure method.
		*/
	}

// HELPERS
	private void function _setupCommonSettings() {
		settings.preside_admin_path = "admin";
		settings.system_users       = "sysadmin";
		settings.default_locale     = "en";
		settings.default_log_name   = "End to End test site";
		settings.default_log_level  = "information";
		settings.sql_log_name       = "End to End test site";
		settings.sql_log_level      = "information";
	}

	private void function _setupRicheditor() {
		settings.ckeditor.defaults.stylesheets.append( "css-bootstrap" );
		settings.ckeditor.defaults.stylesheets.append( "css-layout" );

		// see: https://docs.preside.org/devguides/workingwiththericheditor.html
		// for much more configurability
	}

	private void function _setupAssetManager() {
		/* e.g.
			// see: https://docs.preside.org/devguides/assetmanager.html

			// limit size of images that will be resized automatically
			// default behaviour is not to limit which can lead to
			// intensive CPU if large images are uploaded
			settings.assetManager.derivativeLimits = {
				  maxHeight=2000
				, maxWidth=2000
				, maxResolution=1500*1500
				, tooBigPlaceholder="/preside/system/assets/images/placeholders/largeimage.jpg"
			};

			// setup storage paths for asset manager
			settings.assetManager.storage = {
				  public    = ( settings.env[ "assetmanager.storage.public"    ] ?: settings.uploads_directory & "/assets" )
				, private   = ( settings.env[ "assetmanager.storage.private"   ] ?: settings.uploads_directory & "/privateassets" )
				, trash     = ( settings.env[ "assetmanager.storage.trash"     ] ?: settings.uploads_directory & "/.trash" )
				, publicUrl = ( settings.env[ "assetmanager.storage.publicUrl" ] ?: "" )
			};

			// setup additional extensions that are allowed
			// to be uploaded (these are fictional examples)
			settings.assetManager.types.document.xdoc = { serveAsAttachment=true, mimetype="application/vnd.new.fancy.doc.format" }
			settings.assetManager.types.image.pic = { serveAsAttachment=false, mimetype="image/pic" }
			settings.assetManager.allowedExtensions = super._typesToExtensions( settings.assetManager.types );
		*/

	}

	private void function _setupAssetDerivatives() {
		/* e.g.
			// see https://docs.preside.org/devguides/assetmanager.html#derivatives

			settings.assetManager.derivatives = settings.assetManager.derivatives ?: {};

			settings.assetManager.derivatives.promoImage = {
				  permissions     = "inherit"
				, inEditor        = true // means users will be able to choose when inserting an image in richeditor
				, autoQueue       = [ "image" ] // auto queue this derivative for these asset types
				, transformations = [ { method="shrinkToFit", args={ width=248, height=248 } } ]
			};

		*/
	}

	private void function _setupFeatures() {
		settings.features.formbuilder.enabled         = true;
		settings.features.formbuilder2.enabled        = true;
		settings.features.websiteUsers.enabled        = true;
		settings.features.websiteBenefits.enabled     = false; // you really never want this, was a terrible mistake
		settings.features.multilingual.enabled        = false;
		settings.features.dataexport.enabled          = true;
		settings.features.apiManager.enabled          = true;
		settings.features.restTokenAuth.enabled       = true;
		settings.features.fullPageCaching.enabled     = false;
		settings.features.assetQueue.enabled          = true;
		settings.features.queryCachePerObject.enabled = true;
	}

	private void function _setupLauncher() {
		/* We have installed preside-ext-launcher for you and you may want to configure it.

		   See here for a guide: https://github.com/pixl8/preside-ext-launcher
		*/
	}

	private void function _setupCustomAdminNavigation() {
		/* e.g.
			we have installed preside-ext-alt-admin-theme that makes
			use of Preside Navigation system for the top menu (among other things).

			See the following for help with configuring the top nav for your admin:

				* https://github.com/pixl8/preside-ext-alt-admin-theme, and
				* https://docs.preside.org/devguides/adminMenuItems.html

			e.g.

			ArrayAppend( settings.admin.topNav, "myNavItem" );
			// etc.
		*/
	}

	private void function _setupInterceptors() {
		/*
			e.g.

			interceptors = interceptors ?: [];
			ArrayAppend( interceptors, {
				  class      = "app.interceptors.MyApplicationInterceptor"
				, properties = {}
			} );

			interceptorSettings.customInterceptionPoints = interceptorSettings.customInterceptionPoints ?: [];
			interceptorSettings.customInterceptionPoints.append( "myCustomInterceptionPoint" );
		*/
	}

	private void function _setupLogboxLoggers() {
		/*
			e.g.

			logbox.appenders = logbox.appenders ?: {};

			logbox.appenders.myAppender = {
				  class      = 'coldbox.system.logging.appenders.RollingFileAppender'
				, properties = { filePath=settings.logsMapping, filename="mylog.log", async=true }
			};

			logbox.root = { appenders='defaultLogAppender', levelMin='FATAL', levelMax='WARN' },
			logbox.categories = logbox.categories ?: {};
			logbox.categories.mylbcategory = { appenders='myAppender', levelMin='FATAL', levelMax='INFO' }

			// etc.
		*/
	}
}
