<cffunction name="renderWebflow" access="public" returntype="any" output="false">
	<cfargument name="webflowId"   type="string"  required="true" />
	<cfargument name="instanceRef" type="string"  required="false" default="" />
	<cfargument name="layout"      type="string"  required="false" default="" />

	<cfreturn renderViewlet( event="webflow.Default.render", args=arguments ) />
</cffunction>

<cffunction name="setWebflowErrorMessage" access="public" returntype="any" output="false">
	<cfargument name="message" type="string" required="true" />

	<cfscript>
		getController().getRequestService().getFlashScope().putAll(
			  map     = { webflowErrorMessage=arguments.message }
			, saveNow = true
		);
	</cfscript>
</cffunction>

<cffunction name="setWebflowSuccessMessage" access="public" returntype="any" output="false">
	<cfargument name="message" type="string" required="true" />

	<cfscript>
		getController().getRequestService().getFlashScope().putAll(
			  map     = { webflowSuccessMessage=arguments.message }
			, saveNow = true
		);
	</cfscript>
</cffunction>

<cffunction name="setWebflowWarningMessage" access="public" returntype="any" output="false">
	<cfargument name="message" type="string" required="true" />

	<cfscript>
		getController().getRequestService().getFlashScope().putAll(
			  map     = { webflowWarningMessage=arguments.message }
			, saveNow = true
		);
	</cfscript>
</cffunction>

<cffunction name="encryptWebflowArgs" access="public" returntype="string" output="false">
	<cfargument name="webflowId"    type="string" required="true"  />
	<cfargument name="instanceRef"  type="string" required="true"  />
	<cfargument name="subReference" type="string" required="true"  />
	<cfargument name="stepId"       type="string" required="true" />
	<cfscript>
		var source = "webflowId=#arguments.webflowId#&instanceRef=#arguments.instanceRef#&stepId=#arguments.stepId#&subReference=#arguments.subReference#";

		return UrlEncode( ToBase64( source ) );
	</cfscript>
</cffunction>

<cffunction name="decryptWebflowArgs" access="public" returntype="struct" output="false">
	<cfscript>
		var rc   = getRequestContext().getCollection();
		var args = { valid=true };

		try {
			var source = ToString( ToBinary( UrlDecode( rc._wid ?: "" ) ) );
			var parts  = ListToArray( source, "&" );

			for( var part in parts ) {
				args[ ListFirst( part, "=" ) ] = ListRest( part, "=" );
			}
		} catch ( e ) {
			logError( e );
			args.valid = false;
		}

		args.valid = args.valid && Len( Trim( args.webflowId ?: "" ) ) && Len( Trim( args.stepId ?: "" ) );

		return args;
	</cfscript>
</cffunction>

<cffunction name="buildWebflowSubmitLink" access="public" returntype="string" output="false">
	<cfargument name="wfInstance" type="any" required="true"  />
	<cfargument name="queryString"  type="string" required="false" default="" />

	<cfscript>
		var instanceArgs     = arguments.wfInstance.getInstanceArgs();
		var webflowId        = instanceArgs.reference ?: "";
		var instanceRef      = instanceArgs.subReference ?: "";
		var subReference     = instanceArgs.subSubReference ?: "";
		var stepId           = arguments.wfInstance.getActiveStep();
		var event            = getRequestContext();
		var returnUrl        = stringToHex( getWebflowReturnUrl() );

		var obfuscatedFields = encryptWebflowArgs(
			  webflowId    = webflowId
			, instanceRef  = instanceRef
			, subReference = subReference
			, stepId       = stepId
		);
		var isLazyLoaded = IsTrue( instanceArgs.lazyLoad ?: "" );
		var qs = "_wid=#obfuscatedFields#&_rurl=#returnUrl#";

		if ( Len( Trim( arguments.queryString ) ) ) {
			qs &= "&" & arguments.queryString;
		}
		if ( !isLazyLoaded ) {
			qs &= "&csrfToken=#event.getCsrfToken()#";
		}

		if ( event.isAdminRequest() ) {
			return event.buildAdminLink( linkto="webflow.submitAction", queryString=qs );
		}
		return event.buildLink( linkto="webflow.default.submitAction", queryString=qs );
	</cfscript>


</cffunction>

<cffunction name="getWebflowReturnUrl" access="public" returntype="any" output="false">
	<cfscript>
		var event = getRequestContext();
		var rUrl  = ReReplace( event.getCurrentUrl(), "([\?&])_ws=.*?(&|$)(.*)", "\1\3" );

		return ReReplace( rUrl, "[\?&]$", "" );
	</cfscript>
</cffunction>

<cffunction name="isHex" access="public" returntype="boolean" output="false">
	<cfargument name="stringValue"  type="string" required="true" default="" />
	<cfscript>
		return isValid( "regex", stringValue, "[0-9a-fA-F]*");
	</cfscript>
</cffunction>

<cffunction name="hexToString" access="public" returntype="string" output="false">
	<cfargument name="hexValue"      type="string" required="true" default="" />
	<cfargument name="failIfNotHex"  type="string" required="true" default="false" />
	<cfscript>
		if ( !isHex( hexValue ) && !failIfNotHex ) {
			return hexValue;
		}
		return ToString( BinaryDecode( hexValue, "hex" ) );
	</cfscript>
</cffunction>

<cffunction name="stringToHex" access="public" returntype="string" output="false">
	<cfargument name="stringValue"  type="string" required="true" default="" />
	<cfscript>
		return BinaryEncode( StringToBinary( stringValue ), "hex" );
	</cfscript>
</cffunction>

<cffunction name="stringToBinary" access="public" returntype="string" output="false">
	<cfargument name="stringValue"  type="string" required="true" default="" />
	<cfscript>
		return ToBinary( toBase64( stringValue ) );
	</cfscript>
</cffunction>