/**
 * @versioned false
 *
 */
component {
	property name="label" generate="always" generator="method:generateLabel";
	property name="title";
	property name="firstname";
	property name="lastname";
	property name="sometimestamp"     generate="always" generator="timestamp";
	property name="hashed_firstname"  generate="insert" generator="hash" generateFrom="firstname";

	function generateLabel( required struct data ) {
		return "#data.title# #data.firstname# #data.lastname#";
	}
}