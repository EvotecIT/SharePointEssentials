# The source bootstrapper initializes explicitly after every function is loaded.
# PowerForge merges this statement after the function definitions in artefacts.
if (-not $Script:SharePointEssentialsDeferPnPInitialization) {
    Initialize-SharePointPnPProvider
}
