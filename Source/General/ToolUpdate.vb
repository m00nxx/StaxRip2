
Imports System.Net.Http
Imports System.Text.RegularExpressions
Imports System.Threading.Tasks

Imports Microsoft.VisualBasic
Imports StaxRip.UI

Public Class ToolUpdate
    Private Const ExtractTimeoutMilliseconds As Integer = 10 * 60 * 1000

    Property Package As Package
    Property DownloadFile As String
    Property ExtractDir As String
    Property TargetDir As String
    Property UseCurl As Boolean

    Private HttpClient As New HttpClient
    Private UpdateUI As IUpdateUI

    Sub New(pack As Package, updateUI As IUpdateUI)
        Package = pack
        TargetDir = pack.Directory
        Me.UpdateUI = updateUI
    End Sub

    Async Sub Update()
        Await UpdateAsync()
    End Sub

    Async Function UpdateAsync() As Task
        Try
            Dim content = Await HttpClient.GetStringAsync(Package.DownloadURL)
            Dim matches = Regex.Matches(content, "(?i)(?:href=(""|')(?<url>[^""']+\.(?:7z|zip|exe)(?:\?[^""']*)?)(?:\1)|(?<url>https?://[^\s""'<>]+?\.(?:7z|zip|exe)(?:\?[^\s""'<>]*)?))")
            Dim baseUri As Uri = Nothing
            Uri.TryCreate(Package.DownloadURL, UriKind.Absolute, baseUri)
            Dim foundDownload = False

            For Each match As Match In matches
                Dim url = match.Groups("url").Value

                If String.IsNullOrWhiteSpace(url) Then Continue For
                If Ignore(url) Then Continue For
                If Package.Include <> "" AndAlso Not url.Contains(Package.Include) Then Continue For

                Dim downloadUri As Uri = Nothing
                If Not Uri.TryCreate(url, UriKind.Absolute, downloadUri) Then
                    If baseUri Is Nothing OrElse Not Uri.TryCreate(baseUri, url, downloadUri) Then
                        Continue For
                    End If
                End If

                Dim fileName = IO.Path.GetFileName(downloadUri.LocalPath)
                If String.IsNullOrWhiteSpace(fileName) Then Continue For

                DownloadFile = IO.Path.Combine(Folder.Desktop, fileName)
                foundDownload = True
                Download(downloadUri.ToString())
                Exit For
            Next

            If Not foundDownload Then
                UpdatePackageDialog()
                MsgInfo("No downloadable update asset was found." + BR2 + Package.DownloadURL)
            End If
        Catch ex As Exception
            UpdatePackageDialog()
            MsgError("Tool update failed." + BR2 + ex.Message)
        End Try
    End Function

    Sub Download(url As String)
        'TaskDialog trims URLs
        If MessageBox.Show("Download the file shown below?" + BR2 + url,
            Application.ProductName, MessageBoxButtons.OKCancel,
            MessageBoxIcon.Question) = DialogResult.OK Then

            Using form As New DownloadForm(url, DownloadFile)
                If form.ShowDialog() = DialogResult.OK AndAlso DownloadFile.FileExists Then
                    If DownloadFile.FileExists Then
                        Extract()
                    Else
                        MsgError("Downloaded file is missing.")
                    End If
                Else
                    FileHelp.Delete(DownloadFile)
                    MsgInfo("Download was canceled or failed.")
                End If
            End Using
        End If
    End Sub

    Sub Extract()
        If DownloadFile.Ext <> "7z" AndAlso DownloadFile.Ext <> "zip" Then
            Exit Sub
        End If

        ExtractDir = Path.Combine(DownloadFile.Dir, DownloadFile.Base)

        Using pr As New Process
            pr.StartInfo.FileName = Package.SevenZip.Path
            pr.StartInfo.Arguments = "x -y " + DownloadFile.Escape + " -o""" + ExtractDir + """"
            pr.StartInfo.UseShellExecute = False
            pr.StartInfo.CreateNoWindow = True
            pr.Start()

            If Not pr.WaitForExit(ExtractTimeoutMilliseconds) Then
                Try
                    pr.Kill()
                Catch
                End Try

                UpdatePackageDialog()
                MsgError("Extraction timed out.")
                Exit Sub
            End If

            If pr.ExitCode <> 0 Then
                UpdatePackageDialog()
                MsgError("Extraction failed with error exit code " & pr.ExitCode)
                Exit Sub
            End If
        End Using

        If Not File.Exists(Path.Combine(ExtractDir, Package.Filename)) Then
            Dim subDirs As New List(Of String)

            For Each subDir In Directory.GetDirectories(ExtractDir, "*", SearchOption.AllDirectories)
                If (Path.Combine(subDir, Package.Filename)).FileExists AndAlso Not Ignore(subDir) Then
                    subDirs.Add(subDir)
                End If
            Next

            If subDirs.Count > 1 Then
                UpdatePackageDialog()

                Using td As New TaskDialog(Of String)
                    td.Title = "Choose subfolder to extract."

                    For Each subDir In subDirs
                        Dim name = subDir.Replace(ExtractDir, "").TrimEnd(Path.DirectorySeparatorChar)
                        td.AddCommand(name, subDir)
                    Next

                    If td.Show.DirExists Then
                        ExtractDir = td.SelectedValue
                    End If
                End Using
            ElseIf subDirs.Count = 1 Then
                ExtractDir = subDirs(0)
            End If
        End If

        If Not (Path.Combine(ExtractDir, Package.Filename)).FileExists Then
            UpdatePackageDialog()
            MsgError("File missing after extraction.")
            Exit Sub
        End If

        DeleteOldFiles()
    End Sub

    Sub DeleteOldFiles()
        Dim entries = Directory.GetFileSystemEntries(TargetDir)
        entries = entries.Where(Function(item) Not item.FileName.EqualsAny(Package.Keep)).ToArray
        Dim names = entries.Select(Function(item) item.FileName)
        Dim list = String.Join(BR, names)
        UpdatePackageDialog()

        If MsgQuestion("Delete current files?",
            "Delete current files in:" + BR2 + TargetDir + BR2 + list) = DialogResult.OK Then

            For Each file In Directory.GetFiles(TargetDir)
                If file.FileName.EqualsAny(Package.Keep) Then
                    Continue For
                End If

                FileHelp.Delete(file, FileIO.RecycleOption.SendToRecycleBin)
            Next

            For Each folder In Directory.GetDirectories(TargetDir)
                If folder.FileName.EqualsAny(Package.Keep) Then
                    Continue For
                End If

                FolderHelp.Delete(folder, FileIO.RecycleOption.SendToRecycleBin)
            Next
        Else
            UpdatePackageDialog()
            MsgInfo("Update was canceled.")
            Exit Sub
        End If

        CopyFiles()
    End Sub

    Sub CopyFiles()
        Dim entries = Directory.GetFileSystemEntries(ExtractDir)
        Dim names = entries.Select(Function(item) item.FileName)
        Dim list = String.Join(BR, names)
        UpdatePackageDialog()

        If MsgQuestion("Copy new files?",
            "Copy new files from:" + BR2 + ExtractDir + BR2 + "to:" + BR2 +
            TargetDir + BR2 + list) = DialogResult.OK Then

            For Each file In Directory.GetFiles(ExtractDir)
                FileHelp.Copy(file, Path.Combine(TargetDir, file.FileName))
            Next

            For Each folder In Directory.GetDirectories(ExtractDir)
                FolderHelp.Copy(folder, Path.Combine(TargetDir, folder.FileName))
            Next
        Else
            UpdatePackageDialog()
            MsgInfo("Update was canceled.")
            Exit Sub
        End If

        FolderHelp.Delete(ExtractDir, FileIO.RecycleOption.SendToRecycleBin)
        EditVersion()
    End Sub

    Sub EditVersion()
        Dim msg = "What's the name of the new version?" + BR2 + DownloadFile.FileName

        UpdatePackageDialog()
        Dim input = InputBox.Show(msg, DownloadFile.Base)

        If input <> "" Then
            Package.SetVersion(input.Replace(";", "_").Trim)
            UpdatePackageDialog()
            g.DefaultCommands.Test()
        End If
    End Sub

    Function Ignore(value As String) As Boolean
        If value.ContainsAny(Package.Exclude) Then
            Return True
        End If

        Dim x86 = {"_win32", "\x86", "-x86", "32-bit", "-win32"}

        If Environment.Is64BitProcess AndAlso value.ToLowerInvariant.ContainsAny(x86) Then
            Return True
        End If
    End Function

    Sub UpdatePackageDialog()
        UpdateUI.UpdateUI()
    End Sub
End Class
