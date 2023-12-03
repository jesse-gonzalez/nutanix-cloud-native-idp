$dns_host = "@@{dns_name}@@"
$dns_zone = "@@{domain_name}@@"
$dns_server = "@@{dns_server}@@"
$dns_ipaddr = "@@{dns_ip_address}@@"

$dns_ptr_ip = "@@{ip_number}@@"
$dns_ptr_zone = "@@{reversed_ip}@@.in-addr.arpa"
$dns_host_fqdn = "@@{dns_name}@@.@@{domain_name}@@"

## Updating DNS Server A Record
$oldobj = Get-DnsServerResourceRecord -Name $dns_host -ZoneName $dns_zone -RRType "A" -ComputerName $dns_server -ErrorAction SilentlyContinue

If ($oldobj -eq $null)
{ 
    #Clear out Error Object completely
    $error.Clear()
    
    #Object does not exist in DNS, creating new one
    Write-Output ("Adding DNS Host Record IP: " + $dns_ipaddr + " for Hostname: " + $dns_host_fqdn + ". Updating Now")
    $newobj = Add-DnsServerResourceRecordA -CreatePtr -Name $dns_host -ZoneName $dns_zone -IPv4Address $dns_ipaddr -ComputerName $dns_server -PassThru -Verbose -ErrorAction SilentlyContinue
    Write-Output($newobj)
}
Else
{ 

    $newobj = $oldobj.Clone()
    $newobj.RecordData.ipv4address = [System.Net.IPAddress]::parse($dns_ipaddr)
    If (($newobj.RecordData.ipv4address -ine $oldobj.RecordData.ipv4address))
    { 
        Write-Output ("New IP: " + $newobj.RecordData.ipv4address + " is not equal to Old IP: " + $oldobj.RecordData.ipv4address + " for Hostname: " + $dns_host_fqdn + ". Updating Now")
        Set-DnsServerResourceRecord -newinputobject $newobj -oldinputobject $oldobj -ZoneName $dns_zone -PassThru -ComputerName $dns_server -Verbose -ErrorAction Stop
        
        #Just Easier to Remove Ptr and Add
        #Remove-DnsServerResourceRecord -Name $dns_ptr_ip -ZoneName $dns_ptr_zone -RRType Ptr -ComputerName $dns_server -Force -ErrorAction SilentlyContinue
        Add-DnsServerResourceRecordPtr -Name $dns_ptr_ip -ZoneName $dns_ptr_zone -PtrDomainName $dns_host_fqdn -ComputerName $dns_server -Verbose -ErrorAction Stop
    }
    Else {
        Write-Output("Nothing to Change.")
    }
}
$oldobj = $null
$newobj = $null
