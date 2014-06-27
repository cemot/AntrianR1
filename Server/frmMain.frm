VERSION 5.00
Object = "{248DD890-BB45-11CF-9ABC-0080C7E7B78D}#1.0#0"; "MSWINSCK.OCX"
Begin VB.Form frmMain 
   Caption         =   "Server"
   ClientHeight    =   3690
   ClientLeft      =   120
   ClientTop       =   450
   ClientWidth     =   3675
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   3690
   ScaleWidth      =   3675
   StartUpPosition =   2  'CenterScreen
   Begin VB.Frame Frame1 
      Caption         =   " [ No Antrian Terakhir ] "
      Height          =   2655
      Left            =   120
      TabIndex        =   3
      Top             =   120
      Width           =   3375
      Begin VB.Label lblNoUrut 
         Alignment       =   2  'Center
         Caption         =   "0"
         Height          =   195
         Index           =   3
         Left            =   240
         TabIndex        =   9
         Top             =   2280
         Width           =   480
      End
      Begin VB.Label lblNoUrut 
         Alignment       =   2  'Center
         Caption         =   "0"
         Height          =   195
         Index           =   2
         Left            =   240
         TabIndex        =   8
         Top             =   1950
         Width           =   480
      End
      Begin VB.Label lblNoUrut 
         Alignment       =   2  'Center
         Caption         =   "0"
         Height          =   195
         Index           =   1
         Left            =   240
         TabIndex        =   7
         Top             =   1635
         Width           =   480
      End
      Begin VB.Label lblNoUrut 
         Alignment       =   2  'Center
         Caption         =   "0"
         Height          =   195
         Index           =   0
         Left            =   240
         TabIndex        =   6
         Top             =   1320
         Width           =   480
      End
      Begin VB.Label Label1 
         Alignment       =   1  'Right Justify
         Caption         =   "No. Urut"
         Height          =   195
         Left            =   240
         TabIndex        =   5
         Top             =   1080
         Width           =   600
      End
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
         Top             =   480
         Width           =   3135
      End
   End
   Begin VB.CommandButton cmdStart 
      Caption         =   "Start Server"
      Height          =   375
      Left            =   1200
      TabIndex        =   1
      Top             =   3180
      Width           =   1095
   End
   Begin VB.CommandButton cmdStop 
      Caption         =   "Stop Server"
      Height          =   375
      Left            =   2400
      TabIndex        =   0
      Top             =   3180
      Width           =   1095
   End
   Begin MSWinsockLib.Winsock wckServer 
      Index           =   0
      Left            =   120
      Top             =   2880
      _ExtentX        =   741
      _ExtentY        =   741
      _Version        =   393216
   End
   Begin VB.Label lblStatusService 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Label1"
      Height          =   255
      Left            =   360
      TabIndex        =   2
      Top             =   2895
      Width           =   3135
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Const LOCAL_PORT    As Long = 1234
Private noAntrian           As Integer

Private Function startListening(ByVal localPort As Long) As Boolean
    On Error GoTo errHandle
    
    If localPort > 0 Then
        'If the socket is already listening, and it's listening on the same port, don't bother restarting it.
        If (wckServer(0).State <> sckListening) Or (wckServer(0).localPort <> localPort) Then
            With wckServer(0)
                Call .Close
                .localPort = localPort
                Call .Listen
            End With
        End If
        
        'Return true, since the server is now listening for clients.
        startListening = True
   End If
   
   Exit Function
errHandle:
   startListening = False
End Function

Private Sub startServer()
    If startListening(LOCAL_PORT) Then
        lblStatusService.Caption = "Status Server : On"
        cmdStart.Enabled = False
        
        cmdStop.Enabled = True
    Else
        lblStatusService.Caption = "Status Server : Off"
        cmdStart.Enabled = True
        
        cmdStop.Enabled = False
    End If
End Sub

Private Sub send(ByVal lngIndex As Long, ByVal strData As String)
    If (wckServer(lngIndex).State = sckConnected) Then
        Call wckServer(lngIndex).SendData(strData): DoEvents
    Else
        Exit Sub
    End If
End Sub

Private Sub shutDown()
    Dim i    As Long
    
    Call wckServer(0).Close
   
    ' Now loop through all the clients, close the active ones and
    ' unload them all to clear the array from memory.
    For i = 1 To wckServer.UBound
        If (wckServer(i).State <> sckClosed) Then wckServer(i).Close
        Call Unload(wckServer(i))
    Next i
End Sub

Private Sub cmdStart_Click()
    Call startServer
End Sub

Private Sub cmdStop_Click()
    Call shutDown

    lblStatusService.Caption = "Status Server : Off"
    cmdStart.Enabled = True
    
    cmdStop.Enabled = False
End Sub

Private Sub Form_Load()
    Call startServer
    noAntrian = 1
End Sub

Private Sub wckServer_Close(Index As Integer)
    ' Close the socket and raise the event to the parent.
    Call wckServer(Index).Close
End Sub

Private Sub wckServer_ConnectionRequest(Index As Integer, ByVal requestID As Long)
    Dim i          As Long
    Dim j          As Long
    Dim blnLoaded  As Boolean
       
    On Error GoTo errHandle
    
    ' We shouldn't get ConnectionRequests on any other socket than the listener
    ' (index 0), but check anyway. Also check that we're not going to exceed
    ' the MaxClients property.
    If (Index = 0) Then
        ' Check to see if we've got any sockets that are free.
        For i = 1 To wckServer.UBound
            If (wckServer(i).State = sckClosed) Then
                j = i
                Exit For
            End If
        Next i
      
        ' If we don't have any free sockets, load another on the array.
        If (j = 0) Then
            blnLoaded = True
            Call Load(wckServer(wckServer.UBound + 1))
            j = wckServer.Count - 1
        End If
        
        ' With the selected socket, reset it and accept the new connection.
        With wckServer(j)
            Call .Close
            Call .Accept(requestID)
        End With
        
    End If
    
    Exit Sub
    '
errHandle:
    ' Close the Winsock that caused the error.
    Call wckServer(0).Close
End Sub

Private Sub wckServer_DataArrival(Index As Integer, ByVal bytesTotal As Long)
    Dim cmd     As String
    Dim i       As Integer
    Dim noUrut  As Integer
    
    On Error GoTo errHandle
    
    ' Grab the data from the specified Winsock object, and pass it to the parent.
    Call wckServer(Index).GetData(cmd)
    
    Select Case cmd
        Case "get_no_antrian"
            Call send(Index, CStr(noAntrian))
            
            lblNoAntrian.Caption = noAntrian
            noUrut = noAntrian
            
            noAntrian = noAntrian + 1 ' naikkan counter nomor antrian
                        
            ' tampilkan no urut antrian
            For i = 0 To lblNoUrut.Count
                If noUrut > 0 Then
                    lblNoUrut(i).Caption = noUrut
                Else
                    lblNoUrut(i).Caption = ""
                End If
                
                noUrut = noUrut - 1
            Next i
    
        Case Else
            Call send(Index, "perintah tidak dikenal")
    End Select
    
    Exit Sub
errHandle:
   Call wckServer(Index).Close
End Sub

Private Sub wckServer_Error(Index As Integer, ByVal Number As Integer, Description As String, ByVal Scode As Long, ByVal Source As String, ByVal HelpFile As String, ByVal HelpContext As Long, CancelDisplay As Boolean)
    Call wckServer(Index).Close
End Sub
