The Readme.md details how to run the scripts that generate jsons and populates the NoSQL database.

## Workflow Overview
This page documents the entire photo publishing Workflow.
* [Backup mongodb](#backup-the-mongodb)
* [Run the viewer_photo script](#run-the-script)
* [Import to Viewer](#continuing-on-to-the-drupal-hosts)
* [Run handles](#handle-updates)
* [ASpace DO Update](#aspace-do-update): **Contact ACM before doing this**

These links are for your convenience, but please read the details below.

It involves traversal of a few hosts.
Starting your voyage now.... :sailboat:


The user publishing the images does the following.

##### Backup the mongodb database before import - this is on the host that contain the mongodb hosts.

### On the host which has the viewer_photo script
* Once a ticket is assigned to the user, they get a list of SEs from the JIRA ticket. The user  creates a directory with the jira ticket as its name. For ex: DLTSIMAGES-226 on the host where the viewer_photo scripts are run.
* In that directory(**DLTSIMAGES-226**), the user creates 3 files:
    * **se_list**: containing the list of SEs to be published
    * **wip_path**: contains just one line: the path to the wip
    * **collection_url**: one line: the path to the collection url file
* ##### Run the script
The user `cd`s to the directory containing the publishing scripts and runs either the [wrapper](./README.md#workflow-setup) script or calls it [directly](./README.md#calling-the-script-directly).
* Once the user has ensured that the script ran correctly, they create a tarball of the json files generated and copy it to the `*sites` host where the jsons will populate the viewer database
### Continuing on to the drupal hosts
* Untar the tar ball in a directory.
* Create a list of jsons to be imported
* `drush cc all` in the `sites/default` directory of the Viewer site
* Backup the drupal database before the import
* in the `sites/default` directory, run the import-photo module with parameters of the directory where the tar ball was opened and the list of json files
    * `drush import-photo /dir/containing/jsons --file=/path/to/file/containing/list/of/jsons`
    * So, for example, in a directory called json that is stored in the user's home directory and a list of those jsons called list_json.txt, the call would be this:
    *  `drush import-photo ~/json --file=/home/user/list_json.txt`
* It's done with a list instead of sending the whole directory because there are sometimes thousands of json files and the process runs out of memory.
### Returning back to the host containing the viewer_photo script

 It's now time for updating handles and/or updating the Archives Space record with a digital object containing the handle value

 #### Handle updates
 * For images, handles need to be updated one of two ways depending on how the images are to be viewed.
     * for thumbnail views, cd  to where the handle scripts live. Run the handle update script like so:
         * `$ ruby set_handle_viewer_photo_set.rb /path/to/WIPs /file/containing/listOfSeS/ [what host - dev/stage/prod] tn`
        * For ex:
        `$ ruby set_handle_viewer_photo_set.rb /path/to/WIPs /file/containing/listOfSeS/ dev tn`
  * This directs the handle to the first image of the image set: http://drupalhost/photos/wipname/1
  * For the "click to view" functionality, run the handle script like so:
      * `$ ruby set_handle_viewer_photo_set.rb /path/to/WIPs /file/containing/listOfSeS/ [what host - dev/stage/prod] all`
      * For ex:
      `$ ruby set_handle_viewer_photo_set.rb /path/to/WIPs /file/containing/listOfSeS/ dev all`

 #### ASpace DO update
 * This step is for collections from Archives Space. The wrapper script calls a pre-existing script which does the heavy lifting of updating a digital object with a handle value. **Please notify ACM when doing this step.**
     * `ruby ruby run_aspace_do.rb ~/DLTSAUDIO-33-se-list.txt 'audio-service' /path/to/wip/`
     * where *~/DLTSAUDIO-33-se-list.txt*: file containing SEs
     * *'audio-service'* is the type of service to be expected by the finding aid renderer
     * */path/to/wip* is the wip path

Your trip is complete.
