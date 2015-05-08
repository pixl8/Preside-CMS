multilingual_language
=====================

Overview
--------

The multilingual language object stores
languages that can be available to the Presides core
multilingual content system

**Object name:**
    multilingual_language

**Table name:**
    psys_multilingual_language

**Path:**
    /preside-objects/i18n/multilingual_language.cfc

Properties
----------

.. code-block:: java

    property name="name"          type="string"  dbtype="varchar" maxlength=200 required=true uniqueindexes="language_name" control="textinput";
    property name="iso_code"      type="string"  dbtype="varchar" maxlength=2   required=true uniqueindexes="iso_code";
    property name="native_name"   type="string"  dbtype="varchar" maxlength=200 required=true control="textinput";
    property name="right_to_left" type="boolean" dbtype="boolean"               required=false default=false;