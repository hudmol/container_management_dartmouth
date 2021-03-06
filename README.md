Container Management
====================

ArchivesSpace plugin to add a new container type to ArchivesSpace.
More information on these at
http://campuspress.yale.edu/yalearchivesspace/2014/11/20/managing-content-managing-containers-managing-access/.

This plugin is a fork of https://github.com/hudmol/container_management
It is compatible with ArchivesSpace v1.3


## Installing it

To install, just activate the plugin in your config/config.rb file by
including an entry such as:

     # If you have other plugins loaded, just add 'container_management' to
     # the list
     AppConfig[:plugins] = ['local', 'other_plugins', 'container_management']

And then clone the `container_management` repository into your
ArchivesSpace plugins directory.  For example:

     cd /path/to/your/archivesspace/plugins
     git clone https://github.com/hudmol/container_management.git container_management


## Upgrading from a previous release

Each release of this plugin comes with some database schema changes
that need to be applied.  To upgrade from a previous release:

  1. Replace your `/path/to/archivesspace/plugins/container_management`
     directory with the new release version

  2. Run the database setup script to update all tables to the latest
     version:

          cd /path/to/archivesspace
          scripts/setup-database.sh


## Migrating your existing ArchivesSpace installation

This plugin provides a mechanism to perform a bulk conversion of your
existing ArchivesSpace database to the new container model.  If you
are applying this plugin to an existing ArchivesSpace installation
(with pre-existing container data) you should apply these steps.

Please be aware that your ArchivesSpace installation must be *stopped*
while the conversion is running, so this migration will require some
scheduled downtime.  It's a good idea to run the migration on a copy
of your database first: this will give you an idea of how long the
migration will take, and will also give you a chance to fix any
underlying data issues reported by the migration process.  As a rough
estimate, a database with 350,000 Archival Object records (and MySQL
running on the same machine) was migrated in around 2.5 hours.

To perform the migration:

  * Follow the installation steps above.

  * Start your ArchivesSpace instance and verify that everything loads
correctly.  If you browse to the ArchivesSpace staff interface, you
should see an entry for "Manage container profiles" under the
"Plug-ins" dropdown menu.

  * Shut down ArchivesSpace

  * Add the following entry to your `config/config.rb` file:

         AppConfig[:migrate_to_container_management] = true

  * Start ArchivesSpace again.  You should see the migration log a
    large number of messages as it runs.

  * Once the migration finishes, shut down ArchivesSpace.

  * Search the ArchivesSpace log for any "ERROR" messages.  A common
    case is where two container records in ArchivesSpace claim to
    represent the same container, but have different metadata.  For
    example:

         [java] E, [2015-03-11T10:03:03.138000 #2315] ERROR -- : Thread-3438: A ValidationException was raised while the container migration took place.  Please investigate this, as it likely indicates data issues that will need to be resolved by hand
         [java] E, [2015-03-11T10:03:03.139000 #2315] ERROR -- :
         [java] #<:ValidationException: {:errors=>{"indicator_1"=>["Mismatch when mapping between indicator and indicator_1"]}, :object_context=>{:top_container=>#<TopContainer @values={:id=>31219, :repo_id=>2, :lock_version=>9, :json_schema_version=>1, :barcode=>"0118999880199157253", :restricted=>0, :indicator=>"32", :created_by=>"admin", :last_modified_by=>"admin", :create_time=>2015-03-10 23:02:50 UTC, :system_mtime=>2015-03-10 23:03:03 UTC, :user_mtime=>2015-03-10 23:02:50 UTC, :ils_holding_id=>nil, :ils_item_id=>nil, :exported_to_ils=>nil, :override_restricted=>0, :legacy_restricted=>0}>, :aspace_container=>{"lock_version"=>0, "indicator_1"=>"24", "barcode_1"=>"31142042186752", "indicator_2"=>"3b", "created_by"=>"admin", "last_modified_by"=>"admin", "create_time"=>"2013-12-04T02:29:18Z", "system_mtime"=>"2013-12-04T02:29:18Z", "user_mtime"=>"2013-12-04T02:29:18Z", "type_1"=>"box", "type_2"=>"folder", "jsonmodel_type"=>"container", "container_locations"=>[]}}}>

    This suggests that there are two container records in
    ArchivesSpace with the same barcode, but one with indicator_1 of
    "32" and another with "24".  The migration process will continue,
    but the value(s) from the `aspace_container` entry shown will be
    discarded in favor of the `top_container` values.  You may need to
    clean up the records by hand once the migration has completed.

  * Edit your `config/config.rb` and remove the entry for
    `:migrate_to_container_management` (or change it to `false`).

  * Restart ArchivesSpace and wait for reindexing to complete.

  * Verify that your container records have been migrated correctly.


## Configuring it

This plugin supports the following configuration options:

  * container_management_barcode_length
  * container_management_extent_calculator
  * map_to_aspace_container_class
  * map_to_managed_container_class

All configuration is optional. Default values will be used if none are specified. Add these entries to your config/config.rb file if you wish to override the defaults.

### container_management_barcode_length
This configuration option is used to specify allowed length ranges for barcodes by repository. For example:

      AppConfig[:container_management_barcode_length] = {
        :system_default => {:min => 5, :max => 10},
        'repo' => {:min => 9, :max => 12},
        'other_repo' => {:min => 9, :max => 9},
        'yet_another_repo' => {:min => 6}
      }

The :system_default entry sets minimum and maximum allowed barcode lengths for the whole system (all repositories). The other entries, keyed by repository code, override the system defaults for specific repositories. Note that it is not necessary to override both :min and :max. In the example above 'yet_another_repository' would inherit :max from :system_default and so would have an allowed range of 6-10. If :min or :max are not provided either in :system_default or in an entry for the current repository then the barcode length is not lower or upper bounded respectively.

### container_management_extent_calculator
This configuration option is used to customize the behavior of the extent calculator function. For example:

      AppConfig[:container_management_extent_calculator] = {
        :report_volume => true,
        :unit => :feet,
        :decimal_places => 3
      }

The extent calculator provides a report on the total extent of containers within an accession, resource, or resource component. It calculates the extent by totaling the dimensions of the containers attached to instances belonging to the object in question and all of its children. The dimensions of the containers are specified in container profile records.

The :report_volume option specifies whether the calculator should report a volume (cubic) measure or a length measure. The default is false (ie length). If a length measure is used then the calculator totals values in the field (width, height, depth) specified by extent_dimension of the container profiles it finds. If a volume measure is used the calculator multiples width, height and depth to determine a cubic measure for each container, and totals that value.


The :unit option specifies the unit to report. The default is whatever the dimension_units value is in the first container profile it encounters when performing the calculation. Supported values are: :feet, :inches, :meters, :centimeters.

The :decimal_places option specifies the number of decimal places to show for extent values in the report. The default is 2.

### map_to_aspace_container_class and map_to_managed_container_class

Use these options to specify the names of classes you provide to override the default compatibility mapping to and from the original ArchivesSpace container model.


## Temporary workaround for "Full head" errors

The top container linker passes a large amount of data to the frontend
in some cases, which causes errors like this to appear in the logs:

     2015-02-23 11:39:10.672:WARN:oejh.HttpParser:HttpParser Full for SCEP@3eec285c{l(/a.b.c.d:xxxxx)<->r(/l.m.n.o:yyyy),d=true,open=true,ishut=false,oshut=false,rb=false,wb=false,w=true,i=0r}-{AsyncHttpConnection@5401a48f,g=HttpGenerator{s=0,h=-1,b=-1,c=-1},p=HttpParser{s=-10,l=0,c=-3},r=0}

There's a pull request against the ArchivesSpace project to address
this issue:

  https://github.com/archivesspace/archivesspace/pull/136

but as a temporary workaround, you can increase Jetty's request buffer
size.  To do that, copy the file `launcher_rc.rb` from this directory
into your top-level archivesspace directory, and then restart
ArchivesSpace.  When the system starts up, you should see messages
like:

     Increasing buffer size for SelectChannelConnector@0.0.0.0:8080 to 32768

There's no harm in running with this option indefinitely (it will
increase the amount of memory used per-request, but not by an amount
that would matter), but it can be safely removed once the above pull
request has been merged and released in a future ArchivesSpace
version.


## Migrating user defined fields from the Archivist's Toolkit

This plugin comes with a migrator that can read information from
certain user defined fields attached to instances within the
Archivist's Toolkit.  To run this migration:

  * Shut down your ArchivesSpace instance

  * Set the `at_db_url` configuration property to point to your
    Archivist's Toolkit database.  For example:

         AppConfig[:at_db_url] = 'jdbc:mysql://localhost:3306/archivists_toolkit?useUnicode=true&characterEncoding=UTF-8&user=at&password=at123'

  * Set the `at_target_aspace_repo` configuration property to the repository
    code *within ArchivesSpace* what will be receiving the information
    from the Archivist's Toolkit database:

         AppConfig[:at_target_aspace_repo] = 'MSSA'

  * Set the following configuration properties to trigger the
    migration process to run on startup:

         # Run the migration process
         AppConfig[:user_defined_field_migrate] = true

         # If set to 'true', this will log updates without updating
         # your ArchivesSpace database.
         #
         # When you are ready to run a real migration, set this to
         # 'false'
         #
         AppConfig[:user_defined_field_migrate_dry_run] = true

  * Start your ArchivesSpace instance.  Once the migration is underway
    you will see log messages like:

         [java] I, [2015-03-30T11:27:24.601000 #5538]  INFO -- : Thread-3400: Processing top container 19000 of 125544

  * Once the process completes, ArchivesSpace will start as normal.
    At this point, remove the above configuration properties to avoid
    the migration running again when ArchivesSpace next starts up.
