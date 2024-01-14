# English strings
ConvertFrom-StringData @'
    FoundMofFilesMessage                 = Found {0} MOF files in path '{1}'.
    GenerateHelpDocumentMessage          = Generating help document for '{0}'.
    OutputHelpDocumentMessage            = Outputting help document to '{0}'.
    GenerateWikiPageMessage              = Generating wiki page for '{0}'.
    OutputWikiPageMessage                = Outputting wiki page to '{0}'.
    NoDescriptionFileFoundWarning        = No README.md description file found for '{0}', skipping.
    MultipleDescriptionFileFoundWarning  = {1} README.md description files found for '{0}', skipping.
    NoExampleFileFoundWarning            = No Example files found.
    CreateTempDirMessage                 = Creating a temporary working directory.
    ConfigGlobalGitMessage               = Configuring global Git settings.
    ConfigLocalGitMessage                = Configuring local Git settings.
    CloneWikiGitRepoMessage              = Cloning the Wiki Git Repository '{0}'.
    AddWikiContentToGitRepoMessage       = Adding the Wiki Content to the Git Repository.
    CommitAndTagRepoChangesMessage       = Committing the changes to the Repository and adding build tag '{0}'.
    PushUpdatedRepoMessage               = Pushing the updated Repository to the Git Wiki.
    PublishWikiContentCompleteMessage    = Publish Wiki Content complete.
    UpdateWikiCommitMessage              = Updating Wiki with the content for module version '{0}'.
    NewTempFolderCreationError           = Unable to create a temporary working folder in '{0}'.
    InvokingGitMessage                   = Invoking Git using arguments '{0}'.
    GenerateWikiSidebarMessage           = Generating Wiki Sidebar '{0}'.
    GenerateWikiFooterMessage            = Generating Wiki Footer '{0}'.
    CopyWikiFoldersMessage               = Copying Wiki files from '{0}'.
    CopyFileMessage                      = Copying file '{0}' to the Wiki.
    AddFileToSideBar                     = Adding file '{0}' to the Wiki Sidebar.
    NothingToCommitToWiki                = There are no changes to the documentation to commit and push to the Wiki.
    FoundClassBasedMessage               = Found {0} class-based resources in the built module '{1}'.
    FoundClassResourcePropertyMessage    = Found property '{0}' in the resource '{1}'.
    CommentBasedHelpMessage              = Reading comment-based help from source file '{0}'.
    FoundResourceExamplesMessage         = Found {0} examples.
    IgnoreAstParseErrorMessage           = Errors was found during parsing of comment-based help. These errors were ignored: {0}
    WikiGitCloneFailMessage              = Failed to clone wiki. Ensure the feature is enabled and the first page has been created.
    InvokeGitStandardOutputMessage       = git standard output: '{0}'
    InvokeGitStandardErrorMessage        = git standard error: '{0}'
    InvokeGitExitCodeMessage             = git exit code: '{0}'
    FoundCompositeFilesMessage           = Found {0} composite schema files in path '{1}'.
    CommentBasedHelpBlockNotFound        = A comment-based help block in source file '{0}' could not be found at the top of the script file. Assuming comment-based help is part of the function-block.
    CommentBasedHelpBlockNotAtTopMessage = A comment-based help block in source file '{0}' was found, but does not start at the first line of the script file. Assuming it is the correct comment-based help block.
    CompositeResourceMultiConfigError    = {1} composite resources were found in the source file '{0}'. This is not currently supported. Please separate these into different scripts.
    MacOSNotSupportedError               = NotImplemented: MacOS is not supported for this operation because DSC can not be installed onto it. Please use an OS that DSC can be installed onto.
    InvokeGitCommandDebug                = Command: git {0}
    InvokeGitWorkingDirectoryDebug       = git Working Directory: '{0}'
    ParsingOutCommentBasedHelpBlock      = Parsing out only the comment-based help block from the source file.

    ## Remove-MarkdownMetadataBlock
    RemoveMarkdownMetadataBlock_ShouldProcessVerboseDescription = Removing markdown metadata from markdown file '{0}'.
    RemoveMarkdownMetadataBlock_ShouldProcessVerboseWarning = Are you sure you want to removing markdown metadata from markdown file '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    RemoveMarkdownMetadataBlock_ShouldProcessCaption = Remove markdown metadata from file

    ## New-GitHubWikiSidebar
    NewGitHubWikiSidebar_ShouldProcessVerboseDescription = Creating GitHub Wiki Sidebar '{0}'.
    NewGitHubWikiSidebar_ShouldProcessVerboseWarning = Are you sure you want to create a GitHub Wiki Sidebar '{0}' based on the markdown files in '{1}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    NewGitHubWikiSidebar_ShouldProcessCaption = Create GitHub Wiki Sidebar
'@
