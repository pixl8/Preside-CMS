/**
 * @tablePrefix psys_
 *
 */
component {
	property name="label" uniqueindexes="redirectUrlLabel";

	property name="source_url_pattern" type="string"  dbtype="varchar" maxlength=200 required=true uniqueindexes="sourceurl";
	property name="redirect_type"      type="string"  dbtype="varchar" maxlength=3   required=true format="regex:(301|302)";
	property name="exact_match_only"   type="boolean" dbtype="boolean"               required=false default=false;

	property name="redirect_to_link" relationship="many-to-one" relatedto="link" required=true;
}