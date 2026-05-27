Imports System.Net

Public Class UpdateForm
    Public WithEvents Progress As New WebClient
    Private Sub Update_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        Try
            Update()
        Catch ex As Exception
            MsgInfo(ex.Message)
            Close()
        End Try
    End Sub

    Private Sub Update()
        g.ShellExecute("https://github.com/m00nxx/StaxRip2/releases/latest")
        Close()
    End Sub

    Private Sub ScrappyProgressBar_Report(sender As Object, e As DownloadProgressChangedEventArgs) Handles Progress.DownloadProgressChanged
        Try
            ScrappyProgressBar.Value = e.ProgressPercentage
        Catch ex As Exception
        End Try
    End Sub
End Class
