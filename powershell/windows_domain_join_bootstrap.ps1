param(
  $Hostname,
  $S3Bucket,
  $S3JsonKey
)

function Main {

  # load AWS .NET SDK assemblies
  Add-Type -Path "C:\Program Files (x86)\AWS SDK for .NET\bin\Net45\AWSSDK.dll"

  # if $Hostname is not provided, assign to ec2 instance-id
  if (!$Hostname) {
    $WebClient = New-Object System.Net.WebClient

    $Hostname = $WebClient.DownloadString("http://169.254.169.254/latest/meta-data/instance-id")
  }

  # build S3 client object for authenticating to S3 bucket
  $S3Client = [Amazon.AWSClientFactory]::CreateAmazonS3Client([Amazon.RegionEndpoint]::USWest2)

  # stream S3 object content
  $obj = New-Object Amazon.S3.IO.S3FileInfo($S3Client, $S3Bucket, $S3JsonKey)

  #convert stream to json
  $json = $obj.OpenText().ReadToEnd() | ConvertFrom-Json

  # convert $json.Password to secure string
  $securepw = ConvertTo-SecureString -String $json.Password -AsPlainText -Force

  # create PSCredential
  $credential = New-Object System.Management.Automation.PSCredential -ArgumentList $json.username,$securepw

  # join computer to domain
  Add-Computer -Domain $json.Domain -NewName $Hostname -Credential $credential -OUPath $json.OUPath -Force

  # clear S3 client object from memory
  $S3Client.dispose()

  # restart computer so changes take effect
  Restart-Computer

}

. Main