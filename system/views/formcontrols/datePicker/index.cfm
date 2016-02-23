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
	lessThanCurrentDate 		  = args.lessThanCurrentDate 			?: "";
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
		<cfif val( greaterThanCurrentDate )>
			<cfset startDate = dateFormat( now() ,"yyyy-mm-dd" )>
			<cfset endDate   = 0>
		<cfelseif val( lessThanCurrentDate )>
			<cfset startDate = 0>
			<cfset endDate   = dateFormat( now() ,"yyyy-mm-dd" )>
		<cfelseif isDate( minDate ) and isDate( maxDate )>
			<cfset startDate = dateFormat( minDate ,"yyyy-mm-dd" )>
			<cfset endDate   = dateFormat( maxDate ,"yyyy-mm-dd" )>
		</cfif>
		<input name="#inputName#" placeholder="#placeholder#" class="#inputClass# form-control date-picker datetime" id="#inputId#" type="text" data-gt-entered-field= "#greaterThanDateEnteredInField#" data-lt-entered-field= "#lessThanDateEnteredInField#" data-date-format="yyyy-mm-dd" value="#HtmlEditFormat( value )#" tabindex="#getNextTabIndex()#" data-start-date="#startDate#" data-end-date="#endDate#"/>
		<i class="fa fa-calendar"></i>
	</span>
</cfoutput>