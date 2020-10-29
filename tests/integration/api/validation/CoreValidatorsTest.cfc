component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// TESTS
	function test01_required_shouldReturnFalse_whenFieldDoesNotExistInPassedData(){
		super.assertFalse( _getValidators().required(
			  fieldName = "test"
			, value     = ""
			, data      = { any="thing", but="test" }
		) );
	}

	function test02_required_shouldReturnFalse_whenFieldIsAnEmptyString(){
		super.assertFalse( _getValidators().required(
			  fieldName = "test"
			, value     = ""
			, data      = { any="thing", but="test", test="" }
		) );
	}

	function test03_required_shouldReturnTrue_whenFieldIsPresentAndNotEmpty(){
		super.assert( _getValidators().required(
			  fieldName = "test"
			, value     = "a value, doesn't really matter what"
			, data      = { any="thing", but="test", test="a value, doesn't really matter what" }
		) );
	}

	function test04_slug_shouldReturnTrue_whenValueIsEmpty(){
		super.assert( _getValidators().slug( fieldName="slug", value="" ) );
	}

	function test05_slug_shouldReturnFalse_whenValueIsNotAValidSlug(){
		super.assertFalse( _getValidators().slug( fieldName="slug", value="Slug should b3 lowerc@se And only consist of numbers, letters and dashes" ) );
	}

	function test06_slug_shouldReturnTrue_whenValueIsAValidSlug(){
		super.assert( _getValidators().slug( fieldName="slug", value="this-is-a--valid-slug-" ) );
	}

	function test07_minLength_shouldReturnTrue_whenValueIsEmptyString(){
		super.assert( _getValidators().minLength( fieldname="blah", value="", length=10 ) );
	}

	function test08_minLength_shouldReturnFalse_whenValueIsAStringWithLessCharactersThanSuppliedMinLength(){
		super.assertFalse( _getValidators().minLength( fieldname="blah", value="some", length=5 ) );
	}

	function test09_minLength_shouldReturnTrue_whenPassedStringHasCharacterCountEqualToSuppliedMinLength(){
		super.assert( _getValidators().minLength( fieldname="blah", value="this is a test", length=14 ) );
	}

	function test10_minLength_shouldReturnTrue_whenPassedStringHasCharacterCountGreaterToSuppliedMinLength(){
		super.assert( _getValidators().minLength( fieldname="blah", value="Another test", length=3 ) );
	}

	function test11_minLength_shouldReturnFalse_whenSuppliedValueIsCommaSeparatedListWithLessItemsThanMinLength_andListIsTrue(){
		super.assertFalse( _getValidators().minLength( fieldname="blah", value="Another test,Yes,really its a test", length=4, list=true ) );
	}

	function test12_maxLength_shouldReturnTrue_whenValueIsEmptyString(){
		super.assert( _getValidators().maxLength( fieldname="blah", value="", length=10 ) );
	}

	function test13_maxLength_shouldReturnTrue_whenValueIsAStringWithLessCharactersThanSuppliedMaxLength(){
		super.assert( _getValidators().maxLength( fieldname="blah", value="some", length=5 ) );
	}

	function test14_maxLength_shouldReturnTrue_whenPassedStringHasCharacterCountEqualToSuppliedMaxLength(){
		super.assert( _getValidators().maxLength( fieldname="blah", value="this is a test", length=14 ) );
	}

	function test15_maxLength_shouldReturnFalse_whenPassedStringHasCharacterCountGreaterToSuppliedMaxLength(){
		super.assertFalse( _getValidators().maxLength( fieldname="blah", value="Another test", length=3 ) );
	}

	function test16_maxLength_shouldReturnTrue_whenSuppliedValueIsCommaSeparatedListWithLessItemsThanMaxLength_andListIsTrue(){
		super.assert( _getValidators().maxLength( fieldname="blah", value="Another test,Yes,really its a test", length=4, list=true ) );
	}

	function test17_rangeLength_shouldReturnTrue_whenSuppliedValueIsEmpty(){
		super.assert( _getValidators().rangeLength( fieldname="blah", value="", minlength=4, maxLength=10 ) );
	}

	function test18_rangeLength_shouldReturnFalse_whenSuppliedValueHasALengthLessThanSuppliedMinLength(){
		super.assertFalse( _getValidators().rangeLength( fieldname="blah", value="ace", minlength=4, maxLength=10 ) );
	}

	function test19_rangeLength_shouldReturnFalse_whenSuppliedValueHasALengthGreaterThanSuppliedMaxLength(){
		super.assertFalse( _getValidators().rangeLength( fieldname="blah", value="ace rocks", minlength=2, maxLength=5 ) );
	}

	function test20_rangeLength_shouldReturnTrue_whenSuppliedValueHasALengthEqualToSuppliedMaxLength(){
		super.assert( _getValidators().rangeLength( fieldname="blah", value="acers", minlength=2, maxLength=5 ) );
	}

	function test21_rangeLength_shouldReturnTrue_whenSuppliedValueHasALengthEqualToSuppliedMinength(){
		super.assert( _getValidators().rangeLength( fieldname="blah", value="nice", minlength=4, maxLength=20 ) );
	}

	function test22_min_shouldReturnTrue_whenValueIsEmptyString(){
		super.assert( _getValidators().min( fieldname="blah", value="", min=10 ) );
	}

	function test23_min_shouldReturnFalse_whenValueIsLessThanMinValue(){
		super.assertFalse( _getValidators().min( fieldname="blah", value=4.99, min=5 ) );
	}

	function test24_min_shouldReturnTrue_whenValueIsEqualToSuppliedMinValue(){
		super.assert( _getValidators().min( fieldname="blah", value=14.0, min=14 ) );
	}

	function test25_min_shouldReturnTrue_whenValueIsGreaterThanSuppliedMinValue(){
		super.assert( _getValidators().min( fieldname="blah", value=3.0001, min=3 ) );
	}

	function test26_max_shouldReturnTrue_whenValueIsEmptyString(){
		super.assert( _getValidators().max( fieldname="blah", value="", max=10 ) );
	}

	function test27_max_shouldReturnFalse_whenValueIsGreaterThanMaxValue(){
		super.assertFalse( _getValidators().max( fieldname="blah", value=5.01, max=5 ) );
	}

	function test28_max_shouldReturnTrue_whenValueIsEqualToSuppliedMaxValue(){
		super.assert( _getValidators().max( fieldname="blah", value=14.0, max=14 ) );
	}

	function test29_max_shouldReturnTrue_whenValueIsLessThanSuppliedMaxValue(){
		super.assert( _getValidators().max( fieldname="blah", value=2, max=3 ) );
	}

	function test30_range_shouldReturnTrue_whenSuppliedValueIsEmpty(){
		super.assert( _getValidators().range( fieldname="blah", value="", min=4, max=10 ) );
	}

	function test31_range_shouldReturnFalse_whenSuppliedValueHasIsLessThanSuppliedMin(){
		super.assertFalse( _getValidators().range( fieldname="blah", value=3, min=4, max=10 ) );
	}

	function test32_range_shouldReturnFalse_whenSuppliedValueIsGreaterThanMax(){
		super.assertFalse( _getValidators().range( fieldname="blah", value=6, min=2, max=5 ) );
	}

	function test33_range_shouldReturnTrue_whenSuppliedValueIsEqualToMax(){
		super.assert( _getValidators().range( fieldname="blah", value=5, min=2, max=5 ) );
	}

	function test34_range_shouldReturnTrue_whenSuppliedValueIsEqualToMin(){
		super.assert( _getValidators().range( fieldname="blah", value=4, min=4, max=20 ) );
	}

	function test35_range_shouldReturnTrue_whenSuppliedValueIsBetweenMinAndMax(){
		super.assert( _getValidators().range( fieldname="blah", value=6, min=4, max=20 ) );
	}

	function test36_match_shouldReturnTrue_whenSuppliedValueIsEmptyString(){
		super.assert( _getValidators().match( fieldname="whatever", value="", regex="test" ) );
	}

	function test37_match_shouldReturnFalse_whenSuppliedValueDoesNotMatchTheRegex(){
		super.assertFalse( _getValidators().match( fieldname="whatever", value="meh", regex="^M[0-9]{8}$" ) );
	}

	function test38_match_shouldReturnTrue_whenSuppliedValueMatchesTheRegext(){
		super.assert( _getValidators().match( fieldname="whatever", value="M94364938", regex="^M[0-9]{8}$" ) );
	}

	function test39_number_shouldReturnTrue_whenSuppliedValueIsBlank(){
		super.assert( _getValidators().number( fieldname="meh", value="" ) );
	}

	function test40_number_shouldReturnFalse_whenSuppliedValueIsNotANumber(){
		super.assertFalse( _getValidators().number( value="not.a03,4number" ) );
	}

	function test41_number_shouldReturnTrue_whenSuppliedValueIsANumber(){
		super.assert( _getValidators().number( value="4242343.003" ) );
	}

	function test42_digits_shouldReturnTrue_whenSuppliedValueIsBlank(){
		super.assert( _getValidators().digits( value="" ) );
	}

	function test43_digits_shouldReturnFalse_whenSuppliedValueContainsNonDigits(){
		super.assertFalse( _getValidators().digits( value="24324.00" ) );
	}

	function test44_digits_shouldReturnTrue_whenSuppliedValueOnlyContainsDigits(){
		super.assert( _getValidators().digits( value="123450673829" ) );
	}

	function test45_date_shouldReturnTrue_whenSuppliedValueIsEmptyString(){
		super.assert( _getValidators().date( value="" ) );
	}

	function test46_date_shouldReturnFalse_whenSuppliedValueIsNotADate(){
		super.assertFalse( _getValidators().date( value="Not a date" ) );
	}

	function test47_date_shouldReturnTrue_whenSuppliedValueIsADate(){
		super.assert( _getValidators().date( value="2013-11-23 00:34:34" ) );
	}



// PRIVATE HELPERS
	private function _getValidators() ouptut=false {
		return new preside.system.services.validation.CoreValidators();
	}


}