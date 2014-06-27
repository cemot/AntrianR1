VERSION 5.00
Object = "{248DD890-BB45-11CF-9ABC-0080C7E7B78D}#1.0#0"; "MSWINSCK.OCX"
Begin VB.Form frmMain 
   Caption         =   "Klien"
   ClientHeight    =   2460
   ClientLeft      =   120
   ClientTop       =   450
   ClientWidth     =   3075
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   2460
   ScaleWidth      =   3075
   StartUpPosition =   2  'CenterScreen
   Begin VB.Frame Frame1 
      Caption         =   " [ No. Antrian ] "
      Height          =   1095
      Left            =   240
      TabIndex        =   3
      Top             =   600
      Width           =   2655
      Begin VB.Label lblNoAntrian 
         Alignment       =   2  'Center
         Caption         =   "0"
         BeginProperty Font 
            Name            =   "MS Sans Serif"
            Size            =   24
            Charset         =   0
            Weight          =   700
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   615
         Left            =   120
         TabIndex        =   4
         Top             =   360
         Width           =   2415
      End
   End
   Begin VB.TextBox txtNoKlien 
      Height          =   285
      Left            =   1080
      TabIndex        =   2
      Text            =   "01"
      Top             =   240
      Width           =   495
   End
   Begin VB.CommandButton cmdAmbilNoAntrian 
      Caption         =   "Ambil No Antrian"
      Height          =   495
      Left            =   240
      TabIndex        =   0
      Top             =   1815
      Width           =   2655
   End
   Begin MSWinsockLib.Winsock myClient 
      Left            =   3600
      Top             =   120
      _ExtentX        =   741
      _ExtentY        =   741
      _Version        =   393216
   End
   Begin VB.Label Label1 
      Caption         =   "No. Klien"
      Height          =   195
      Left            =   240
      TabIndex        =   1
      Top             =   240
      Width           =   645
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Const REMOTE_PORT   As Long = 1234
Private Const conTunggu As Long = 100000

Private Function isConnected(ByVal ipServer As String) As Boolean
    Static i As Long

    On Error Resume Next

    If myClient.State <> sckClosed Then myClient.Close ' close existing connection
    myClient.RemoteHost = ipServer
    myClient.RemotePort = REMOTE_PORT
    myClient.Connect

    With myClient
        Do Until .State = sckConnected
            DoEvents
            i = i + 1
            If i >= conTunggu Then
                i = 0
                Exit Function
            End If
        Loop
    End With

    isConnected = myClient.State = sckConnected
        
End Function

Private Sub cmdAmbilNoAntrian_Click()
    Dim ipServer    As String
    Dim cmd         As String
    
    ipServer = "127.0.0.1"
    cmd = "get_no_antrian"
    
    If isConnected(ipServer) Then
        myClient.SendData cmd
    End If
End Sub

Private Sub Form_Unload(Cancel As Integer)
    If Not myClient Is Nothing Then myClient.Close
End Sub

Private Sub myClient_DataArrival(ByVal bytesTotal As Long)
    Dim noAntrian As String
    
    On Error Resume Next
    
    myClient.GetData noAntrian
    lblNoAntrian.Caption = noAntrian
End Sub

