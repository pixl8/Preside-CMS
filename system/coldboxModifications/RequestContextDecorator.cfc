<!---
	Helper methods and standard event method overrides that are specific to Preside
	live here.
--->

<cfcomponent extends="coldbox.system.web.context.RequestContextDecorator" output="false">

<!--- URL related --->
	<cffunction name="buildLink" access="public" returntype="string" output="false">
		<cfscript>
			var prc = getRequestContext().getCollection( private=true );

			_announceInterception(
				  state         = "onBuildLink"
				, interceptData = arguments
			);

			var link = prc._builtLink ?: "";
			StructDelete( prc, "_builtLink" );

			if ( not Len( Trim( link ) ) and Len( Trim( arguments.linkTo ?: "" ) ) ) {
				link = getRequestContext().buildLink( argumentCollection = arguments );
			}

			return link;
		</cfscript>
	</cffunction>

	<cffunction name="getProtocol" access="public" returntype="string" output="false">
		<cfreturn cgi.server_protocol contains "https" ? "https" : "http" />
	</cffunction>

	<cffunction name="getServerName" access="public" returntype="string" output="false">
		<cfreturn cgi.server_name />
	</cffunction>

	<cffunction name="getBaseUrl" access="public" returntype="string" output="false">
		<cfreturn getProtocol() & "://" & getServerName() />
	</cffunction>

	<cffunction name="getCollectionWithoutSystemVars" access="public" returntype="struct" output="false">
		<cfscript>
			var collection = Duplicate( getRequestContext().getCollection() );

			StructDelete( collection, "csrfToken"   );
			StructDelete( collection, "action"      );
			StructDelete( collection, "event"       );
			StructDelete( collection, "handler"     );
			StructDelete( collection, "module"      );
			StructDelete( collection, "fieldnames"  );

			return collection;
		</cfscript>
	</cffunction>

	<cffunction name="getCollectionForForm" access="public" returntype="struct" output="false">
		<cfargument name="formName" type="string" required="true" />

		<cfscript>
			var formFields = getModel( "formsService" ).listFields( arguments.formName );
			var collection = {};
			var rc         = getRequestContext().getCollection();

			for( var field in formFields ){
				collection[ field ] = ( rc[ field ] ?: "" );
			}

			return collection;
		</cfscript>
	</cffunction>

<!--- Admin specific --->
	<cffunction name="buildAdminLink" access="public" returntype="string" output="false">
		<cfargument name="linkTo"      type="string" required="false" default="" />
		<cfargument name="queryString" type="string" required="false" default="" />

		<cfscript>
			arguments.linkTo = ListAppend( "admin", arguments.linkTo, "." );

			if ( isActionRequest( arguments.linkTo ) ) {
				arguments.queryString = ListAppend( arguments.queryString, "csrfToken=" & this.getCsrfToken(), "&" );
			}

			return buildLink( argumentCollection = arguments );
		</cfscript>
	</cffunction>

	<cffunction name="getCurrentAdminUrl" access="public" returntype="string" output="false">
		<cfscript>
			var currentEvent = getRequestContext().getCurrentEvent();

			return getBaseUrl() & buildAdminLink(
				  linkTo      = ListRest( currentEvent, "." )
				, queryString = _structToQueryString( getCollectionWithoutSystemVars() )
			);
		</cfscript>
	</cffunction>

	<cffunction name="isAdminUser" access="public" returntype="boolean" output="false">
		<cfscript>
			var securitySvc = getModel( "AdminSecurityService" );

			return securitySvc.isLoggedIn();
		</cfscript>
	</cffunction>

	<cffunction name="getAdminUserDetails" access="public" returntype="struct" output="false">
		<cfscript>
			var securitySvc = getModel( "AdminSecurityService" );

			return securitySvc.getLoggedInUserDetails();
		</cfscript>
	</cffunction>

	<cffunction name="getAdminUserId" access="public" returntype="string" output="false">
		<cfscript>
			return getAdminUserDetails().userId;
		</cfscript>
	</cffunction>

	<cffunction name="hasAdminPermission" access="public" returntype="boolean" output="false">
		<cfscript>
			var securitySvc = getModel( "AdminSecurityService" );

			return securitySvc.hasPermission( argumentCollection = arguments );
		</cfscript>
	</cffunction>

	<cffunction name="adminAccessDenied" access="public" returntype="void" output="false">
		<cfscript>
			// todo, something much better here!
			getRequestContext().renderData( data="<h1>Access denied</h1>", statusCode=401 );
		</cfscript>
	</cffunction>

	<cffunction name="audit" access="public" returntype="void" output="false">
		<cfscript>
			arguments.userId = getAdminUserDetails().userId;

			return getModel( "AuditService" ).log( argumentCollection = arguments );
		</cfscript>
	</cffunction>

	<cffunction name="addAdminBreadCrumb" access="public" returntype="void" output="false">
		<cfargument name="title" type="string" required="true" />
		<cfargument name="link"  type="string" required="true" />

		<cfscript>
			var event  = getRequestContext();
			var crumbs = event.getValue( name="_adminBreadCrumbs", defaultValue=[], private=true );

			ArrayAppend( crumbs, { title=arguments.title, link=arguments.link } );

			event.setValue( name="_adminBreadCrumbs", value=crumbs, private=true );
		</cfscript>
	</cffunction>

	<cffunction name="getAdminBreadCrumbs" access="public" returntype="array" output="false">
		<cfreturn getRequestContext().getValue( name="_adminBreadCrumbs", defaultValue=[], private=true ) />
	</cffunction>

<!--- cfstatic --->
	<cffunction name="include" access="public" returntype="any" output="false">
		<cfreturn _getCfStaticPlugin().include( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="includeData" access="public" returntype="any" output="false">
		<cfreturn _getCfStaticPlugin().includeData( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="renderIncludes" access="public" returntype="string" output="false">
		<cfargument name="type" type="string" required="false" />
		<cfscript>
			var rendered      = _getCfStaticPlugin().renderIncludes( argumentCollection = arguments );
			var inlineJsArray = "";

			if ( not StructKeyExists( arguments, "type" ) or arguments.type eq "js" ) {
				var inlineJsArray = getRequestContext().getValue( name="__presideInlineJsArray", defaultValue=[], private=true );
				rendered &= ArrayToList( inlineJsArray, Chr(10) );
				getRequestContext().setValue( name="__presideInlineJsArray", value=[], private=true );
			}

			return rendered;
		</cfscript>
	</cffunction>

	<cffunction name="includeInlineJs" access="public" returntype="void" output="false">
		<cfargument name="js" type="string" required="true" />
		<cfscript>
			var inlineJsArray = getRequestContext().getValue( name="__presideInlineJsArray", defaultValue=[], private=true );

			ArrayAppend( inlineJsArray, "<script type=""text/javascript"">" & Chr(10) & arguments.js & Chr(10) & "</script>" );

			getRequestContext().setValue( name="__presideInlineJsArray", value=inlineJsArray, private=true );
		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="_getCfStaticPlugin" access="private" returntype="any" output="false">
		<cfreturn getController().getPlugin(
			  plugin       = "CfStaticForPreside"
			, customPlugin = true
		) />
	</cffunction>

	<cffunction name="getModel" access="private" returntype="any" output="false">
		<cfargument name="beanName" type="string" required="true" />

		<cfreturn getController().getWireBox().getInstance( arguments.beanName ) />
	</cffunction>

<!--- security helpers --->
	<cffunction name="getCsrfToken" access="public" returntype="string" output="false">
		<cfreturn getModel( "csrfProtectionService" ).generateToken( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="validateCsrfToken" access="public" returntype="string" output="false">
		<cfreturn getModel( "csrfProtectionService" ).validateToken( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="isActionRequest" access="public" returntype="boolean" output="false">
		<cfargument name="ev" type="string" required="false" default="#getRequestContext().getCurrentEvent()#" />
		<cfscript>
			var currentEvent = LCase( arguments.ev );

			if ( ReFind( "^admin\.ajaxProxy\..*?", currentEvent ) ) {
				currentEvent = "admin." & LCase( event.getValue( "action", "" ) );
			}

			return ReFind( "^admin\..*?action$", currentEvent );
		</cfscript>
	</cffunction>

<!--- FRONT END, dealing with current page --->
	<cffunction name="initializePresideSiteteePage" access="public" returntype="void" output="false">
		<cfargument name="slug"      type="string" required="false"  />
		<cfargument name="pageId"    type="string" required="false"  />
		<cfargument name="subaction" type="string" required="false" />

		<cfscript>
			var sitetreeSvc = getModel( "sitetreeService" );
			var rc          = getRequestContext().getCollection();
			var prc         = getRequestContext().getCollection( private = true );
			var page        = "";
			var parentPages = "";
			var getPageArgs = {};
			var isActive    = function( required boolean active, required string embargo_date, required string expiry_date ) {
				return arguments.active && ( !IsDate( arguments.embargo_date ) || Now() >= arguments.embargo_date ) && ( !IsDate( arguments.expiry_date ) || Now() <= arguments.expiry_date );
			}

			if ( ( arguments.slug ?: "/" ) == "/" && !Len( Trim( arguments.pageId ?: "" ) ) ) {
				page = sitetreeSvc.getSiteHomepage();
				parentPages = QueryNew( page.columnlist );
			} else {
				if ( Len( Trim( arguments.pageId ?: "" ) ) ) {
					getPageArgs.id = arguments.pageId;
				} else {
					getPageArgs.slug = arguments.slug;
				}
				page = sitetreeSvc.getPage( argumentCollection = getPageArgs );
			}

			if ( not page.recordCount ) {
				return;
			}

			for( p in page ){ page = p; break; } // quick query row to struct hack

			StructAppend( page, sitetreeSvc.getExtendedPageProperties( page.id, page.page_type ) );
			var ancestors = sitetreeSvc.getAncestors( id = page.id );
			page.ancestors = [];

			page.ancestorList = ancestors.recordCount ? ValueList( ancestors.id ) : "";
			for( var ancestor in ancestors ) {
				page.ancestors.append( ancestor );
			}

			page.isInDateAndActive = isActive( argumentCollection = page );
			if ( page.isInDateAndActive ) {
				for( var ancestor in page.ancestors ) {
					page.isInDateAndActive = isActive( argumentCollection = ancestor );
					if ( !page.isInDateAndActive ) {
						break;
					}
				}
			}

			p[ "slug" ] = p._hierarchy_slug;
			StructDelete( p, "_hierarchy_slug" );

			prc.presidePage = page;
		</cfscript>
	</cffunction>

	<cffunction name="getPageProperty" access="public" returntype="any" output="false">
		<cfargument name="propertyName"  type="string"  required="true" />
		<cfargument name="defaultValue"  type="any"     required="false" default="" />
		<cfargument name="cascading"     type="boolean" required="false" default="false" />
		<cfargument name="cascadeMethod" type="string"  required="false" default="closest" hint="closest|collect" />

		<cfscript>
			var page = getRequestContext().getValue( name="presidePage", defaultValue=StructNew(), private=true );

			if ( StructIsEmpty( page ) ) {
				return arguments.defaultValue;
			}

			return getModel( "sitetreeService" ).getPageProperty(
				  propertyName  = arguments.propertyName
				, page          = page
				, ancestors     = page.ancestors ?: []
				, defaultValue  = arguments.defaultValue
				, cascading     = arguments.cascading
				, cascadeMethod = arguments.cascadeMethod
			);
		</cfscript>
	</cffunction>

	<cffunction name="setPageAttribute" access="public" returntype="void" output="false">
		<cfargument name="attributeName"  type="string" required="true" />
		<cfargument name="attributeValue" type="any"    required="true" />

		<cfscript>
			var prc  = getRequestContext().getCollection( private = true );

			prc.presidePage = prc.presidePage ?: {};
			prc.presidePage[ arguments.attributeName ] = arguments.attributeValue;
		</cfscript>
	</cffunction>

	<cffunction name="setPageAttributes" access="public" returntype="void" output="false">
		<cfscript>
			var arg = "";

			for ( arg in arguments ) {
				setPageattribute( attributeName = arg, attributeValue = arguments[ arg ] );
			}
		</cfscript>
	</cffunction>

	<cffunction name="getCurrentPageType" access="public" returntype="string" output="false">
		<cfreturn getPageProperty( 'page_type' ) />
	</cffunction>

	<cffunction name="getCurrentTemplate" access="public" returntype="string" output="false">
		<cfreturn getPageProperty( 'page_template' ) />
	</cffunction>

	<cffunction name="getCurrentPageId" access="public" returntype="string" output="false">
		<cfreturn getPageProperty( 'id' ) />
	</cffunction>

	<cffunction name="isCurrentPageActive" access="public" returntype="boolean" output="false">
		<cfreturn getPageProperty( 'isInDateAndActive', false ) />
	</cffunction>

<!--- private helpers --->
	<cffunction name="_announceInterception" access="private" returntype="any" hint="Announce an interception to the system. If you use the asynchronous facilities, you will get a thread structure report as a result." output="true" >
		<cfargument name="state" 			required="true"  type="any" hint="The interception state to execute">
		<cfargument name="interceptData" 	required="false" type="any" hint="A data structure used to pass intercepted information.">
		<cfargument name="async" 			required="false" type="boolean" default="false" hint="If true, the entire interception chain will be ran in a separate thread."/>
		<cfargument name="asyncAll" 		required="false" type="boolean" default="false" hint="If true, each interceptor in the interception chain will be ran in a separate thread and then joined together at the end."/>
		<cfargument name="asyncAllJoin"		required="false" type="boolean" default="true" hint="If true, each interceptor in the interception chain will be ran in a separate thread and joined together at the end by default.  If you set this flag to false then there will be no joining and waiting for the threads to finalize."/>
		<cfargument name="asyncPriority" 	required="false" type="string"	default="NORMAL" hint="The thread priority to be used. Either LOW, NORMAL or HIGH. The default value is NORMAL"/>
		<cfargument name="asyncJoinTimeout"	required="false" type="numeric"	default="0" hint="The timeout in milliseconds for the join thread to wait for interceptor threads to finish.  By default there is no timeout."/>

		<cfreturn getController().getInterceptorService().processState(argumentCollection=arguments)>
	</cffunction>


	<cffunction name="_structToQueryString" access="public" returntype="string" output="false">
		<cfargument name="inputStruct" type="struct" required="true" />

		<cfscript>
			var qs    = "";
			var delim = "";

			for( var key in inputStruct ){
				if ( IsSimpleValue( inputStruct[ key ] ) ) {
					qs &= delim & key & "=" & inputStruct[ key ];
					delim = "&";
				}
			}

			return qs;
		</cfscript>
	</cffunction>
</cfcomponent>
