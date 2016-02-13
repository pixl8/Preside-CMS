<cfscript>
	inputName    				  = args.name         ?: "";
	inputId      				  = args.id           ?: "";
	inputClass   				  = args.class        ?: "";
	placeholder  				  = args.placeholder  ?: "";
	defaultValue 				  = args.defaultValue ?: "";
	minDate 	 				  = args.minDate 	  ?: "";
	maxDate 	 				  = args.maxDate 	  ?: "";
	startDate					  = "";
	endDate					  	  = "";
	greaterThanCurrentDate 		  = args.greaterThanCurrentDate 		?: "";
	greaterThanDateEnteredInField = args.greaterThanDateEnteredInField  ?: "";
	lessThanDateEnteredInField    = args.lessThanDateEnteredInField 	?: "";

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
	if ( IsDate( value ) ) {
		value = DateFormat( value, "yyyy-mm-dd" );
	}
</cfscript>

<cfoutput>
	<span class="block input-icon input-icon-right">
		<input name="#inputName#" placeholder="#placeholder#" class="#inputClass# form-control date-picker datetime" id="#inputId#" type="text" data-date-format="yyyy-mm-dd" value="#HtmlEditFormat( value )#" tabindex="#getNextTabIndex()#" />
		<i class="fa fa-calendar"></i>

		<cfif val( greaterThanCurrentDate )>
			<cfset startDate = dateFormat( now() ,"yyyy-mm-dd" )>
			<cfset endDate   = 0>
		<cfelseif isDate( minDate ) and isDate( maxDate )>
			<cfset startDate = dateFormat( minDate ,"yyyy-mm-dd" )>
			<cfset endDate   = dateFormat( maxDate ,"yyyy-mm-dd" )>
		<cfelseif !isDate( minDate ) and !isDate( maxDate ) AND greaterThanCurrentDate eq "">
			<cfset startDate = 0>
			<cfset endDate   = dateFormat( now() ,"yyyy-mm-dd" )>
		</cfif>

		<input type="hidden" name="startDate" id="startDate_#inputId#" class="startDate" value="#startDate#">
		<input type="hidden" name="endDate" id="endDate_#inputId#" class="endDate" value="#endDate#">
	</span>
</cfoutput>