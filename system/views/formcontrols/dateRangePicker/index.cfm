<cfscript>
	fromDate       = args.name      		?: "";
	toDate  	   = args.toDate  			?: "";
	inputId        = args.id           		?: "";
	inputClass     = args.class        		?: "";
	placeholder    = args.placeholder  		?: "";
	defaultValue   = args.defaultValue 		?: "";
	from  = event.getValue( name=fromDate, defaultValue=defaultValue );
	if ( not IsSimpleValue( from ) ) {
		from = "";
	}

	if ( IsDate( from ) ) {
		from = DateFormat( from, "yyyy-mm-dd" );
	}

	to  = event.getValue( name=toDate, defaultValue=defaultValue );
	if ( not IsSimpleValue( to ) ) {
		to = "";
	}

	if ( IsDate( to ) ) {
		to = DateFormat( to, "yyyy-mm-dd" );
	}
</cfscript>

<cfoutput>
	<div class="row">
	<div class="input-group col-xs-6">
		<span class="input-group-addon">#translateResource( uri="cms:formbuilder.from", data=[ urlEncodedFormat( args.label ) ] )#</span>
	    <input name="#fromDate#" type="text" class="#inputClass# form-control date-picker" value="#HtmlEditFormat( from )#" data-date-format="yyyy-mm-dd" tabindex="#getNextTabIndex()#">
	</div>
	<div class="input-group col-xs-6">
	    <span class="input-group-addon">#translateResource( uri="cms:formbuilder.to", data=[ urlEncodedFormat( args.label ) ] )#</span>
	    <input name="#toDate#" type="text" class="#inputClass# form-control date-picker" value="#HtmlEditFormat( to )#" data-date-format="yyyy-mm-dd" tabindex="#getNextTabIndex()#">
	</div>
	</div>

</cfoutput>

