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

			_initCfStatic();

			return this;
		</cfscript>
	</cffunction>

<!--- public methods --->
	<cffunction name="include" access="public" returntype="any" output="false">
		<cfscript>
			announceInterception( "onCfStaticInclude", arguments );

			_getCfStatic().include( argumentCollection = arguments );

			announceInterception( "afterCfStaticInclude", arguments );
		</cfscript>
		<cfreturn  />
	</cffunction>

	<cffunction name="includeData" access="public" returntype="any" output="false">
		<cfscript>
			announceInterception( "onCfStaticIncludeData", arguments );

			_getCfStatic().includeData( argumentCollection = arguments );

			announceInterception( "postCfStaticIncludeData", arguments );
		</cfscript>
	</cffunction>

	<cffunction name="renderIncludes" access="public" returntype="string" output="false">
		<cfargument name="type"                    type="string"  required="false"                 hint="Either 'js' or 'css'. the type of include to render. If I am not specified, the method will render both css and javascript (css first)" />
		<cfargument name="includeStandardIncludes" type="boolean" required="false" default="true"  hint="Whether or not to use Preside convention to include standard css and js." />

		<cfscript>
			var rendered = "";

			announceInterception( "onCfStaticRenderIncludes", arguments );

			if ( arguments.includeStandardIncludes ) {
				_includeByConvention();
			}
			rendered = _getCfStatic().renderIncludes( argumentCollection = arguments );

			announceInterception( "postCfStaticRenderIncludes", arguments );

			return rendered;
		</cfscript>
	</cffunction>

	<cffunction name="reload" access="public" returntype="void" output="false">
		<cfscript>
			_initCfStatic();
		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="_initCfStatic" access="private" returntype="void" output="false">
		<cfscript>
			announceInterception( "onCfStaticInit", { settings = _getSettings() } );

			var cfstatic = CreateObject( "component", "org.cfstatic.CfStatic" ).init(
				argumentCollection = _getSettings()
			);
			_setCfstatic( cfstatic );

			announceInterception( "postCfStaticInit" );
		</cfscript>
	</cffunction>

	<cffunction name="_getSettings" access="private" returntype="struct" output="false">
		<cfscript>
			var settings = super.getController().getSettingStructure();
			var generatedDir = settings.cfstatic_generated_directory   ?: "/_assets"

			return {
				  staticDirectory     = generatedDir
				, staticUrl           = settings.cfstatic_generated_url         ?: "/_assets"
				, checkForUpdates     = settings.cfstatic_check_for_updates     ?: ( settings.developerMode.reloadStatic ?: false )
				, jsDependencyFile    = settings.cfstatic_js_dependencies_file  ?: generatedDir & "/js/dependencies.info"
				, cssDependencyFile   = settings.cfstatic_css_dependencies_file ?: generatedDir & "/css/dependencies.info"
				, lessGlobals         = settings.cfstatic_less_globals_file     ?: generatedDir & "/css/lessglobals/global.less"
				, excludePattern      = ListAppend( ( settings.cfstatic_exclude_pattern ?: "lessglobals" ), "ckeditor", "|" )
				, includeAllByDefault = false
			};
		</cfscript>
	</cffunction>

	<cffunction name="_includeByConvention" access="private" returntype="void" output="false">
		<cfscript>
			// TODO, revisit
		</cfscript>
	</cffunction>

<!--- accessors --->
	<cffunction name="_getCfStatic" access="private" returntype="any" output="false">
		<cfreturn _cfStatic>
	</cffunction>
	<cffunction name="_setCfStatic" access="private" returntype="void" output="false">
		<cfargument name="cfStatic" type="any" required="true" />
		<cfset _cfStatic = arguments.cfStatic />
	</cffunction>

</cfcomponent>