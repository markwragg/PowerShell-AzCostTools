function Get-ResourceGroupNameFromInstanceId ($InstanceId) {

    if ($InstanceId) {
        $Segments = $InstanceId -split '/'

        if ($Segments.Count -ge 5) {
            $Segments[4]
        }
    }
}
