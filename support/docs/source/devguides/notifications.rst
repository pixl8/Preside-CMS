Notifications
=============

.. contents:: :local:

Overview
########

PresideCMS comes with a system for raising notifications for the CMS admin users. These notifications may appear in a user's notification feed (see screenshot, below) and/or trigger notification emails. It is also possible to extend the notifications system so that you can have notifications raised in your team's IM tool of choice (Hipchat, Slack, etc.) or any other integration you can think of.

.. figure:: /images/notifications.png

    Screenshot showing various programatically raised user notifications.



Topics
######

Notifications are organised into *topics*. A topic might be something like 'Event booking cancelled', or 'User complaint'. In the screenshot above, you can see four notification topics, 'Bookings checked out', 'Invalid CRM contact data', 'Invoice paid' and 'New contact created'.

Creating a topic
----------------

The first step is to register the topic in your application's config file. This can be done by appending its unique id to the :code:`settings.notificationTopics` array. For example:

.. code-block:: java

    // /application/config/Config.cfc
    component extends="preside.system.config.Config" output=false {

        public void function configure() output=false {
            super.configure();

            // other settings...

            settings.notificationTopics.append( "customerComplaintFiled" );
        }
    }

In order for the topic to render in the notifications panel, it then needs its own i18n .properties file at :code:`/application/i18n/notifications/idOfTopic.properties`. This file needs to contain keys for :code:`title`, :code:`description` and :code:`iconClass`. For example:

.. code-block:: properties

    # /application/i18n/notifications/customerComplaintFiled.properties
    title=Customer complaint filed
    description=Notifications are raised when customers file complaints through the complaints procedure facility
    iconClass=fa-user

Raising a notification
######################

Notifications are raised using the :doc:`/reference/api/notificationservice` object's :ref:`notificationservice-createnotification` method. For example, in a ColdBox handler, you might have:

.. code-block:: java

    component {

        property name="notificationService" inject="notificationService";

        public void function someAction( event, rc, prc ) {
            // some code
            // ...

            notificationService.createNotification(
                  topic = "customerComplaintFiled"
                , type  = "ALERT"
                , data  = { complaintId=newlyCreatedComplaintId }
            );

            // some more code...
        }

    } 

Rendering notifications
#######################

Notifications can appear in various different *contexts* each of which requires its own renderer. These renderers are implemented as :doc:`viewlets` that take the convention of: :code:`renderers.notifications.{idOfNotification}.{context}`. The :code:`args` struct passed to the viewlet, will contain any data that was passed to the :ref:`notificationservice-createnotification` method.

At a bare minimum you must implement viewlets for the **full** and **datatable** contexts (see screenshots below). Additionally, if you want to use a non-default email notification, you can also supply viewlets for the **emailSubject**, **emailHtml** and **emailText** contexts.

.. figure:: /images/notification_datatable_context.png

    The 'datatable' context is shown in the notifications browser screen when showing many notifications in a table view.

.. figure:: /images/notification_full_context.png

    The 'full' context allows you to show full details of the notification within the admin interface. The contents of this view is entirely up to you.


Example renderers
-----------------

The following code provides an example for our 'customer complaint' notification using both a handler and view files for the various renderer viewlets:

.. code-block:: java

    // /application/handlers/renderers/notifications/CustomerComplaintFiled.cfc
    component {

        property name="customerComplaintsService" inject="customerComplaintsService";

        private string function datatable( event, rc, prc, args={} ) {
            var complaint    = customerComplaintsService.getComplaint( args.complaintId ?: "" );
            var customerName = complaint.customerName ?: "Unknown customer";

            return "A complaint was filed by " & HtmlEditFormat( customerName );
        }

        private string function full( event, rc, prc, args={} ) {
            args.complaint = customerComplaintsService.getComplaint( args.complaintId ?: "" );

            return renderView(
                  view = "/renderers/notifications/customerComplaintFiled/full"
                , args = args
            );
        }

        private string function emailSubject( event, rc, prc, args={} ) {
            return "A customer complaint was filed through the website";
        }

        private string function emailHtml( event, rc, prc, args={} ) {
            args.complaint = customerComplaintsService.getComplaint( args.complaintId ?: "" );

            return renderView(
                  view = "/renderers/notifications/customerComplaintFiled/emailHtml"
                , args = args
            );
        }

        private string function emailText( event, rc, prc, args={} ) {
            args.complaint = customerComplaintsService.getComplaint( args.complaintId ?: "" );

            return renderView(
                  view = "/renderers/notifications/customerComplaintFiled/emailText"
                , args = args
            );
        }

    } 


.. code-block:: html

    <!--- /views/renderers/notifications/customerComplaintFiled/full.cfm --->
    <cfparam name="args.complaint.customerName" type="string" /> 
    <cfparam name="args.complaint.complaint"    type="string" /> 
    <cfparam name="args.complaint.dateMade"     type="string" /> 

    <cfoutput>
        <div class="alert alert-danger">
            <h3><i class="fa fa-fw fa-user"></i> Customer complaint made by #args.complaint.customerName# on #args.complaint.dateMade#</h3>

            <p>#HtmlEditFormat( args.complaint.complaint )#</p>
        </div>
    </cfoutput>

.. code-block:: html

    <!--- /views/renderers/notifications/customerComplaintFiled/emailHtml.cfm --->
    <cfparam name="args.complaint.customerName" type="string" /> 
    <cfparam name="args.complaint.complaint"    type="string" /> 
    <cfparam name="args.complaint.dateMade"     type="string" /> 

    <cfoutput>
        <p><bold>Customer complaint made by #args.complaint.customerName# on #args.complaint.dateMade#</bold></p>

        <blockquote>#HtmlEditFormat( args.complaint.complaint )#</blockquote>
    </cfoutput>

.. code-block:: html

    <!--- /views/renderers/notifications/customerComplaintFiled/emailText.cfm --->
    <cfparam name="args.complaint.customerName" type="string" /> 
    <cfparam name="args.complaint.complaint"    type="string" /> 
    <cfparam name="args.complaint.dateMade"     type="string" /> 

    <cfoutput>
    Customer complaint made by #args.complaint.customerName# on #args.complaint.dateMade#:

    -----

    #args.complaint.complaint#
    </cfoutput>

Creating notification extensions
################################

TODO. If you have a requirement to do this, please get in touch.