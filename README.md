# carrolls-stripe-3DS

### This is the remote repo for Barbizon's Heroku App for Authorize

# Rules for properly using the Git/Github workflow

## General Guidelines and Warnings

1. We will be using the GitFlow paradigm as integrated with GitKraken.
    * There are two main branches: Master (production) and Dev.
    * Each feature change (minor or major) will be done in a feature branch off 
    of the Dev branch.
    * Feature branches will be merged into the Dev branch once finished (feature   branch is deleted but not rebased).
    * Once the Dev branch is ready to be made live, a release branch is created and any final updates are done there. It is then merged into both the Master and Dev branches.
    * Any quick updates or emergency fixes to the Master branch is made as a Hotfix branch and is merged immediately into both the Master and Dev branches.
    * Releases should only be done after communicating with the whole team to make sure that all the local updates have been merged into the Github repo.

2. The remote origin will be either on Github or Bitbucket (Github only for now). 
    * The Dev branch should be updated every time a merge occurs onto it and it has passed the proper tests.
    * The Master branch should be updated every time a merge occurs onto it and it has passed the proper tests.

3. The server(s) hosting the Live (Master branch) code and the Test (Dev branch) will also be remote Git repositories.
    * IMPORTANT! When initializing these remote repos, you MUST use the option 'git init --bare'
    * IMPORTANT! No changes should be made directly to these remote repos. The changes will be overwritten anytime the code is updated in the workflow.
    * IMPORTANT! You MUST be careful to update the .gitignore file to include any files are folders that should not be overwritten on code updates. Examples would be error_log files and upload folders where users would upload images/PDF etc.

## Workflow Description

1. When a minor/major change is to be made
    * Get/Have a local copy of the repo as your 'workspace'
        * If a copy exists on your machine, do a Pull from Github to make sure it is up-to-date on both the Dev and Master branches (use GitKraken).
        * If a copy does not exist, Clone the repo from Github (use GitKraken).
    * If GitFlow is not enabled already in GitKraken for that repo
        * Open the repo and go to menu->preferences->GitFlow and make sure that Master=>master and Develop=>dev.
        * Exit preferences.
    * Use the GitFlow panel and click on the green arrow and then click Start Feature.
    * Make all your changes as necessary, committing at each reasonably definable change.
    * When you are finished with your changes and you want to merge them with the Dev branch, use the GitFlow panel and click on the green arrow and then click Finish Feature.
    * After you are satisfied with your updates to your local Dev branch, you may Push the local Dev branch up to Github (Pull first if the Github version is ahead of yours). 

2. When a quick fix to the Live code is to be made
    * Get/Have a local copy of the repo as your 'workspace'
        * If a copy exists on your machine, do a Pull from Github to make sure it is up-to-date on both the Dev and Master branches (use GitKraken).
        * If a copy does not exist, Clone the repo from Github (use GitKraken).
    * If GitFlow is not enabled already in GitKraken for that repo
        * Open the repo and go to menu->preferences->GitFlow and make sure that Master=>master and Develop=>dev.
        * Exit preferences.
    * Use the GitFlow panel and click on the green arrow and then click Start Hotfix.
    * Make all your changes as necessary, committing at each reasonably definable change.
    * When you are finished with your changes and you want to merge them with the Master and Dev branches, use the GitFlow panel and click on the green arrow and then click Finish Hotfix.
    * After you are satisfied with your updates, you may Push the local Dev and Master branch up to Github (Pull first if the Github version is ahead of yours). 
    * Prompt the Project Manager to push the Dev/Live changes to the remote repos. (step 4).

### Warning! The below steps should only be done when directed by the Project Manager. 

3. When the Dev branch is ready to be merge with the Master branch
    * Pull the latest version of the Master and Dev branches to your local machine.
    * Use the GitFlow panel and click on the green arrow and then click Start Release.
    * Make any necessary changes and commits.
    * Use the GitFlow panel and click on the green arrow and then click Finish Release (note that this will automatically merge the Release branch into both the Master and the Dev branches).

4. When the changes are ready to be made live for either the Dev or Master branches
    * Ensure required testing is complete.
    * Pull the latest version of that branch to your local machine.
    * Push those branches to the Live remote repos.
    