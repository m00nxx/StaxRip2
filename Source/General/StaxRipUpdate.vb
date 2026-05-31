
Imports System.ComponentModel
Imports System.Net
Imports System.Net.Http
Imports System.Reflection
Imports System.Web.Script.Serialization
Imports System.Windows.Forms.VisualStyles.VisualStyleElement
Imports Microsoft.VisualBasic

Public Class StaxRipUpdate
    Shared HttpClient As New HttpClient

    Shared Sub SetFirstRunOnCurrentVersion()
        Dim key = g.DefaultCommands.GetApplicationDetails()
        If s.FirstRunOnVersion.Key <> key Then
            s.FirstRunOnVersion = New KeyValuePair(Of String, Date)(key, Date.Now)
        End If
    End Sub

    Shared Sub ShowUpdateQuestion()
        If Not g.IsDevelopmentPC AndAlso s.CheckForUpdatesQuestion Then
            Using td As New TaskDialog(Of String)()
                td.Title = "Check for updates"
                td.Icon = TaskIcon.Question
                td.Content = "Would you like StaxRip2 to check for updates periodically?" + BR +
                             "Each time it is checked, only these websites are queried:" + BR +
                             "'github.com' and " + BR +
                             "'githubusercontent.com'"

                td.AddCommand("Yes")
                td.AddCommand("No")
                td.AddCommand("Ask me later")

                Dim answer = td.Show
                s.CheckForUpdatesQuestion = Not answer.EqualsAny("Yes", "No")
                s.CheckForUpdates = answer = "Yes"
            End Using
        End If
    End Sub

    Shared Async Sub CheckForUpdateAsync(Optional force As Boolean = False, Optional x64 As Boolean = True)
        If g.IsSupporterRelease Then Exit Sub
        If Not s.CheckForUpdates AndAlso Not force Then Exit Sub

        SetFirstRunOnCurrentVersion()

        Dim hours = Conversion.Fix((DateTime.Now - s.FirstRunOnVersion.Value).TotalHours)
        Dim diffHoursToCheck = 24
        diffHoursToCheck = If(hours < 96, 12, diffHoursToCheck)
        diffHoursToCheck = If(hours < 72, 9, diffHoursToCheck)
        diffHoursToCheck = If(hours < 48, 6, diffHoursToCheck)
        diffHoursToCheck = If(hours < 24, 3, diffHoursToCheck)

        Dim proceed = False
        proceed = (Date.Now - s.CheckForUpdatesLastRequest).TotalHours >= diffHoursToCheck OrElse proceed

        If Not (proceed OrElse force) Then Exit Sub

        Try
            Const url = "https://api.github.com/repos/m00nxx/StaxRip2/releases?per_page=5"

            Dim currentVersion = Assembly.GetEntryAssembly().GetName().Version
            Dim assetPlatforms = If(x64, {"x64"}, If(Environment.Is64BitOperatingSystem, {"x86", "x64"}, {"x86"}))

            If Not HttpClient.DefaultRequestHeaders.UserAgent.ToString().Contains("Release-Checker") Then
                HttpClient.DefaultRequestHeaders.UserAgent.ParseAdd("Release-Checker")
            End If

            Dim response = Await HttpClient.GetAsync(url)
            response.EnsureSuccessStatusCode()
            Dim content = Await response.Content.ReadAsStringAsync()

            Dim latestVersions = New List(Of (Version As Version, ReleaseType As String, ReleaseUri As String, DownloadUri As String))
            Dim releases = TryCast(New JavaScriptSerializer().DeserializeObject(content), Object())

            If releases Is Nothing Then
                Throw New FormatException("GitHub releases response was not a JSON array.")
            End If

            For Each release In releases.OfType(Of Dictionary(Of String, Object))()
                Dim tag = ""
                Dim assets As Object() = Nothing

                If Not TryGetStringValue(release, "tag_name", tag) Then Continue For
                If Not TryGetObjectArrayValue(release, "assets", assets) Then Continue For

                For Each asset In assets.OfType(Of Dictionary(Of String, Object))()
                    Dim downloadUri = ""
                    Dim assetName = ""

                    If Not TryGetStringValue(asset, "browser_download_url", downloadUri) Then Continue For
                    If Not TryGetStringValue(asset, "name", assetName) Then Continue For

                    Dim assetMatch = Text.RegularExpressions.Regex.Match(assetName, "^StaxRip2-v?(?<version>\d+\.\d+\.\d+(?:\.\d+)?)-(?<platform>x64|x86)(?<type>-.+?)?\.7z$")

                    If Not assetMatch.Success Then Continue For
                    If Not assetPlatforms.Contains(assetMatch.Groups("platform").Value, StringComparer.OrdinalIgnoreCase) Then Continue For

                    Dim type = assetMatch.Groups("type").Value
                    Dim releaseType = If(type = "-UPDATE", "tool including update",
                                        If(type = "-EXE", "hotfix/update", "release"))
                    Dim onlineVersionString = assetMatch.Groups("version").Value
                    Dim onlineVersion As Version = Nothing

                    If Not Version.TryParse(onlineVersionString, onlineVersion) Then Continue For

                    Dim releaseUri = $"https://github.com/m00nxx/StaxRip2/releases/tag/{tag}"
                    Dim dismissedVersion As Version = Nothing
                    Dim isDismissed = Not String.IsNullOrWhiteSpace(s.CheckForUpdatesDismissed) AndAlso
                        Version.TryParse(s.CheckForUpdatesDismissed, dismissedVersion) AndAlso
                        dismissedVersion >= onlineVersion

                    If onlineVersion <= currentVersion OrElse isDismissed Then Continue For

                    latestVersions.Add((onlineVersion, releaseType, releaseUri, downloadUri))
                Next
            Next

            If latestVersions.Any() Then
                Dim sortedVersions = latestVersions.
                    GroupBy(Function(x) x.DownloadUri).
                    Select(Function(x) x.First()).
                    OrderByDescending(Function(x) x.Version).
                    ToList()
                Dim latestVersion = sortedVersions.First()

                Using td As New TaskDialog(Of String)
                    td.Title = "A new " + latestVersion.ReleaseType + " was found: v" + latestVersion.Version.ToString()
                    td.Icon = TaskIcon.Shield

                    td.AddCommand("Open release page", "open")
                    td.AddCommand("Dismiss v" & latestVersion.Version.ToString(), "dismiss")
                    td.AddCommand("Cancel", "cancel")

                    Select Case td.Show()
                        Case "open"
                            g.ShellExecute(latestVersion.ReleaseUri)
                        Case "dismiss"
                            s.CheckForUpdatesDismissed = latestVersion.Version.ToString()
                    End Select
                End Using
            ElseIf force Then
                MsgInfo("No update available.")
            End If

            s.CheckForUpdatesLastRequest = DateTime.Now
        Catch ex As Exception
            If force Then g.ShowException(ex)
        End Try
    End Sub

    Private Shared Function TryGetStringValue(values As Dictionary(Of String, Object), key As String, ByRef value As String) As Boolean
        value = ""

        If values Is Nothing Then Return False

        Dim rawValue As Object = Nothing

        If Not values.TryGetValue(key, rawValue) OrElse rawValue Is Nothing Then Return False

        value = TryCast(rawValue, String)
        Return Not String.IsNullOrWhiteSpace(value)
    End Function

    Private Shared Function TryGetObjectArrayValue(values As Dictionary(Of String, Object), key As String, ByRef value As Object()) As Boolean
        value = Nothing

        If values Is Nothing Then Return False

        Dim rawValue As Object = Nothing

        If Not values.TryGetValue(key, rawValue) OrElse rawValue Is Nothing Then Return False

        value = TryCast(rawValue, Object())
        Return value IsNot Nothing
    End Function
End Class
