<cfcomponent extends="coldbox.system.Plugin" output="false" singleton="true">

<!--- constructor --->
	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="controller" type="any" required="true">

		<cfscript>
			super.init( arguments.controller );

			setpluginName("CfStatic for Coldbox");
			setpluginVersion("1.0");
			setpluginDescription("Provides an interface into CfStatic for our preside coldbox applications.");
			setPluginAuthor("Pixl8 Interactive");
			setPluginAuthorURL("www.pixl8.co.uk");

			_initAll();

			return this;
		</cfscript>
	</cffunction>

<!--- public methods --->
	<cffunction name="include" access="public" returntype="any" output="false">
		<cfargument name="resource"       type="string"  required="true"                    />
		<cfargument name="bundle"         type="string"  required="false" default="website" />
		<cfargument name="throwOnMissing" type="boolean" required="false"                   />

		<cfscript>
			announceInterception( "onCfStaticInclude", arguments );

			_getCfStatic( arguments.bundle ).include( argumentCollection = arguments );

			announceInterception( "afterCfStaticInclude", arguments );
		</cfscript>
		<cfreturn  />
	</cffunction>

	<cffunction name="includeData" access="public" returntype="any" output="false">
		<cfargument name="data"   type="struct" required="true" />
		<cfargument name="bundle" type="string" required="false" default="website" />

		<cfscript>
			announceInterception( "onCfStaticIncludeData", arguments );

			_getCfStatic( arguments.bundle ).includeData( argumentCollection = arguments );

			announceInterception( "postCfStaticIncludeData", arguments );
		</cfscript>
	</cffunction>

	<cffunction name="renderIncludes" access="public" returntype="string" output="false">
		<cfargument name="type"      type="string"  required="false" />
		<cfargument name="bundle"    type="string"  required="false" default="website" />
		<cfargument name="debugMode" type="boolean" required="false" />

		<cfscript>
			var rendered = "";

			announceInterception( "onCfStaticRenderIncludes", arguments );

			rendered = _getCfStatic( arguments.bundle ).renderIncludes( argumentCollection = arguments );

			announceInterception( "postCfStaticRenderIncludes", arguments );

			return rendered;
		</cfscript>
	</cffunction>

	<cffunction name="getIncludeUrl" access="public" returntype="string" output="false">
		<cfargument name="type"           type="string"  required="true" />
		<cfargument name="resource"       type="string"  required="true" />
		<cfargument name="bundle"         type="string"  required="false" default="website" />
		<cfargument name="throwOnMissing" type="boolean" required="false" />
		<cfargument name="debugMode"      type="boolean" required="false" />
		
		<cfreturn _getCfStatic( arguments.bundle ).getIncludeUrl( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="reload" access="public" returntype="void" output="false">
		<cfargument name="bundle" type="string" required="false" default="website" />

		<cfscript>
			_initCfStatic( arguments.bundle );
		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="_initAll" access="private" returntype="void" output="false">
		<cfscript>
			var appSettings = super.getController().getSettingStructure();

			( appSettings.static.bundles ?: {} ).each( function( bundleName ){
				_initCfStatic( bundleName );
			} );
		</cfscript>
	</cffunction>

	<cffunction name="_initCfStatic" access="private" returntype="void" output="false">
		<cfargument name="bundle" type="string" required="true" />

		<cfscript>
			var settings = _getSettings( arguments.bundle );

			announceInterception( "onCfStaticInit", { settings = settings, bundle=arguments.bundle } );

			var cfstatic = CreateObject( "component", "org.cfstatic.CfStatic" ).init(
				argumentCollection = settings
			);
			_setCfstatic( arguments.bundle, cfstatic );

			announceInterception( "postCfStaticInit" );
		</cfscript>
	</cffunction>

	<cffunction name="_getSettings" access="private" returntype="struct" output="false">
		<cfargument name="bundle" type="string" required="true" />

		<cfscript>
			var appSettings  = super.getController().getSettingStructure();
			var generatedDir = ( appSettings.static.outputDirectory ?: "/_assets" ) & "/" & LCase( arguments.bundle );
			var generatedUrl = ( appSettings.static.outputUrl       ?: "/_assets" ) & "/" & LCase( arguments.bundle );
			var defaultSettings = {
				  staticDirectory     = generatedDir
				, staticUrl           = generatedUrl
				, checkForUpdates     = false
				, jsDependencyFile    = generatedDir & "/js/dependencies.info"
				, cssDependencyFile   = generatedDir & "/css/dependencies.info"
				, lessGlobals         = generatedDir & "/css/lessglobals/global.less"
				, excludePattern      = "lessglobals"
				, includeAllByDefault = false
				, merge               = "once"
			};
			var mergedSettings = defaultSettings;
			
			mergedSettings.append( appSettings.static.bundles[ arguments.bundle ] ?: {} );

			return mergedSettings;
		</cfscript>
	</cffunction>

<!--- accessors --->
	<cffunction name="_getCfStatic" access="private" returntype="any" output="false">
		<cfargument name="bundle" type="string" required="true" />

		<cfreturn _cfStatic[ arguments.bundle ]>
	</cffunction>
	<cffunction name="_setCfStatic" access="private" returntype="void" output="false">
		<cfargument name="bundle" type="string" required="true" />
		<cfargument name="cfStatic" type="any" required="true" />

		<cfscript>
			_cfStatic = _cfStatic ?: {};
			_cfStatic[ arguments.bundle ] = arguments.cfStatic;
		</cfscript>
	</cffunction>

</cfcomponent>