<cfscript>
	inputName          = args.name               ?: "";
	inputId            = args.id                 ?: "";
	inputClass         = args.class              ?: "";
	placeholder        = args.placeholder        ?: "";
	defaultValue       = args.defaultValue       ?: "";
	extraClasses       = args.extraClasses       ?: "";
	stylesheets        = args.stylesheets        ?: "";
	widgetCategories   = args.widgetCategories   ?: ( rc.widgetCategories ?: "" );
	linkPickerCategory = args.linkPickerCategory ?: ( rc.linkPickerCategory ?: "" );
	maxLength     = Val( args.maxLength ?: 0 );

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );
</cfscript>

<cfoutput>
	<textarea id          = "#inputId#"
	          placeholder = "#placeholder#"
	          name        = "#inputName#"
	          class       = "#inputClass# richeditor #extraClasses#"
	          tabindex="#getNextTabIndex()#"
	          <cfif Len( Trim( args.toolbar ?: "" ) )>
	               data-toolbar = "#Trim( args.toolbar )#"
	          </cfif>
	          <cfif Len( Trim( args.customConfig ?: "" ) )>
	              data-custom-config="#Trim( args.customConfig )#"
	          </cfif>
	          <cfif Len( Trim( args.autoParagraph ?: "" ) )>
	              data-auto-paragraph="#isTrue( args.autoParagraph )#"
	          </cfif>
	          <cfif Len( Trim( args.enterMode ?: "" ) )>
	              data-enter-mode="#Trim( args.enterMode )#"
	          </cfif>
	          <cfif Len( Trim( args.stylesheets ?: "" ) )>
	              data-stylesheets="#Trim( args.stylesheets )#"
	          </cfif>
	          <cfif Val( args.width ?: "" )>
	              data-width="#Val( args.width )#"
	          </cfif>
	          <cfif Val( args.minHeight ?: "" )>
	              data-min-height="#Val( args.minHeight )#"
	          </cfif>
	          <cfif Val( args.maxHeight ?: "" )>
	              data-max-height="#Val( args.maxHeight )#"
	          </cfif>
	          <cfif Len( Trim( widgetCategories ) )>
	              data-widget-categories="#Trim( widgetCategories )#"
	          </cfif>
	          <cfif Len( Trim( linkPickerCategory ) )>
	              data-link-picker-category="#Trim( linkPickerCategory )#"
	          </cfif>

	>#value#</textarea>
</cfoutput>