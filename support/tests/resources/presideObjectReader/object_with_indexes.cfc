<cfcomponent output="false">
	<cfproperty name="field1" indexes="1|1,3|2" uniqueindexes="uniqueness|2" />
	<cfproperty name="field2" indexes="1|2"     uniqueindexes="uniqueness|1" />
	<cfproperty name="field3" indexes="2|2"     uniqueindexes="uniq" />
	<cfproperty name="field4" indexes="3|1"/>
	<cfproperty name="field5" indexes="1|3"/>
	<cfproperty name="field6" indexes="2|1"/>
</cfcomponent>