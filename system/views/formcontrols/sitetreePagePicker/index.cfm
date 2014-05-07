<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	placeholder  = args.placeholder  ?: "";
	defaultValue = args.defaultValue ?: "";
	selectedPage = args.selectedPage ?: QueryNew('');

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	selectedPageTitle = selectedPage.recordCount ? selectedPage.label : "";
</cfscript>

<cfoutput>
	<input type="hidden" name="#inputName#" value="#value#" class="form-control sitetree-page-picker-control" data-page-title="#selectedPageTitle#" tabindex="#getNextTabIndex()#" />
</cfoutput>