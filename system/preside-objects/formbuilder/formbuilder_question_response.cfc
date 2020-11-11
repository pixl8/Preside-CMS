/**
 * @feature   formbuilder
 * @versioned false
 * @nolabel   true
 * @dataExportFields id,submission_type,submission_reference,submitted_by,datecreated,is_website_user,parent_name
 */
component displayname="Form builder: global question response" extends="preside.system.base.SystemPresideObject" {
	property name="question" relationship="many-to-one" relatedto="formbuilder_question" required=true ondelete="cascade";

	// submissions could be from multiple different
	// custom systems. These fields allow us to reference
	// an unknown source
	property name="submission_type"      type="string" dbtype="varchar" maxlength=20 required=true indexes="type";
	property name="submission_reference" type="string" dbtype="varchar" maxlength=50 required=true indexes="ref";

	// for some question types, dynamic sub-references are required for a response
	// e.g. the matrix type or an 'Address' question with multiple fields
	property name="question_subreference" type="string" dbtype="varchar" maxlength=100 required=false indexes="questionsubref" excludeDataExport=true;

	// 'response' will always be populated with the response. It will then potentially be
	//  duplicated in one of the indexed columns should the question data type be indexable
	property name="response"           type="string"  dbtype="text";
	property name="shorttext_response" type="string"  dbtype="varchar"  maxlength=200 indexes="shortresp" excludeDataExport=true;
	property name="date_response"      type="date"    dbtype="datetime"               indexes="dateresp"  excludeDataExport=true;
	property name="bool_response"      type="boolean" dbtype="boolean"                indexes="boolresp"  excludeDataExport=true;
	property name="int_response"       type="numeric" dbtype="int"                    indexes="intresp"   excludeDataExport=true;
	property name="float_response"     type="numeric" dbtype="float"                  indexes="floatresp" excludeDataExport=true;

	// if part of a multiple choice question, we may need a sort order
	property name="sort_order" type="numeric" dbtype="int" required=false indexes="order" excludeDataExport=true;

	// a plain text representation of the owner of this response (if we know who they are)
	property name="submitted_by" type="string"  dbtype="varchar" maxlength=100 renderer="FormUser";

	// response possibly related to these
	property name="submission"   relationship="many-to-one" relatedto="formbuilder_formsubmission" required=false excludeDataExport=true;
	property name="website_user" relationship="many-to-one" relatedto="website_user"               required=false excludeDataExport=true;
	property name="admin_user"   relationship="many-to-one" relatedto="security_user"              required=false excludeDataExport=true;

	property name="is_website_user" type="boolean" dbtype="boolean" formula="case when website_user is not null then 1 else 0 end";
	property name="is_admin_user"   type="boolean" dbtype="boolean" formula="case when admin_user is not null then 1 else 0 end";

	property name="parent_name"     type="string"  dbtype="varchar" formula="case when submission_type='formbuilder' then submission$form.name else '' end ";

}