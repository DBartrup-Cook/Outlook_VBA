Attribute VB_Name = "mdl_ResolveDisplayNameToSMTP"
Option Explicit

'----------------------------------------------------------------------------------
' Procedure : ResolveDisplayNameToSMTP
' Author    : Sue Mosher - updated by D.Bartrup-Cook to work in Excel late binding.
'-----------------------------------------------------------------------------------
Public Function ResolveDisplayNameToSMTP(sFromName, OLApp As Object) As String


    Select Case Val(OLApp.Version)
        Case 11 'Outlook 2003
        
            Dim oSess As Object
            Dim oCon As Object
            Dim sKey As String
            Dim sRet As String
            
            Set oCon = OLApp.CreateItem(2) 'olContactItem

            Set oSess = OLApp.GetNameSpace("MAPI")
            oSess.Logon "", "", False, False
            oCon.Email1Address = sFromName
            sKey = "_" & Replace(Rnd * 100000 & Format(Now, "DDMMYYYYHmmss"), ".", "")
            oCon.FullName = sKey
            oCon.Save

            sRet = Trim(Replace(Replace(Replace(oCon.email1displayname, "(", ""), ")", ""), sKey, ""))
            oCon.Delete
            Set oCon = Nothing

            Set oCon = oSess.GetDefaultFolder(3).Items.Find("[Subject]=" & sKey) '3 = 'olFolderDeletedItems
            If Not oCon Is Nothing Then oCon.Delete

            ResolveDisplayNameToSMTP = sRet
        
        Case 14 'Outlook 2010

            Dim oRecip As Object 'Outlook.Recipient
            Dim oEU As Object 'Outlook.ExchangeUser
            Dim oEDL As Object 'Outlook.ExchangeDistributionList
        
            Set oRecip = OLApp.Session.CreateRecipient(sFromName)
            oRecip.Resolve
            If oRecip.Resolved Then
                Select Case oRecip.AddressEntry.AddressEntryUserType
                    Case 0, 5 'olExchangeUserAddressEntry & olExchangeRemoteUserAddressEntry
                        Set oEU = oRecip.AddressEntry.GetExchangeUser
                        If Not (oEU Is Nothing) Then
                            ResolveDisplayNameToSMTP = oEU.PrimarySmtpAddress
                        End If
                    Case 10, 30 'olOutlookContactAddressEntry & 'olSmtpAddressEntry
                            ResolveDisplayNameToSMTP = oRecip.AddressEntry.Address
                End Select
            End If
        Case Else
            'Name not resolved so return sFromName.
            ResolveDisplayNameToSMTP = sFromName
    End Select
End Function
