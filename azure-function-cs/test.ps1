$headers = @{
    "aeg-event-type" = "Notification"
    "x-functions-key" = "some-key"
}

$body = @"
[{
    "id": "{{$guid}}",
    "subject": "pay/transaction/{{transactionId}}",
    "data": {
        "message": "bla!"
    },
    "eventType": "PaymentStateEvent",
    "eventTime": "2020-04-02T10:38:24.196Z",
    "dataVersion": "1.0",
    "metadataVersion": "1",
    "topic": "/subscriptions/9cf3c545-2f8f-4714-9ed6-b31d710a8cee/resourceGroups/test-generic-rg/providers/Microsoft.EventGrid/domains/test-egd/topics/pay"
  }]
"@

$response = Invoke-RestMethod 'http://localhost:7071/runtime/webhooks/eventgrid?functionName=EventHandler' -Method 'POST' -Headers $headers -Body $body
$response | ConvertTo-Json