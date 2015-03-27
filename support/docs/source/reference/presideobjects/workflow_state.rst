workflow_state
==============

Overview
--------

The workflow_state object saves the state and status of a single workflow item

**Object name:**
    workflow_state

**Table name:**
    psys_workflow_state

**Path:**
    /preside-objects/workflow/workflow_state.cfc

Properties
----------

.. code-block:: java

    property name="workflow"  type="string" dbtype="varchar" maxlength=50 required=true uniqueindexes="workflowstate|1";
    property name="reference" type="string" dbtype="varchar" maxlength=50 required=true uniqueindexes="workflowstate|2";
    property name="owner"     type="string" dbtype="varchar" maxlength=50 required=true uniqueindexes="workflowstate|3";
    property name="state"     type="string" dbtype="text";
    property name="status"    type="string" dbtype="varchar" maxlength=50 required=true;
    property name="expires"   type="date"   dbtype="datetime" required=false;
