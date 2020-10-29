<cfcomponent output="false" versioned="false">
	<cfproperty name="field1" dbtype="int" indexes="indexa|1,indexc|2" />
	<cfproperty name="field2" dbtype="int" indexes="indexa|2,indexd"     />
	<cfproperty name="field3" dbtype="int" indexes="indexb|1" uniqueindexes="uniq" />
	<cfproperty name="field4" dbtype="int" indexes="indexc|1" uniqueindexes="uniqueness" />
	<cfproperty name="field5" dbtype="int" indexes="indexa|3"/>
	<cfproperty name="field6" dbtype="int" indexes="indexb|2"/>
</cfcomponent>