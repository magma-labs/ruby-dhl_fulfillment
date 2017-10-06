# dhl_efulfillment

A gem to access the DHL eFulfillment API.

## Usage

Configure the gem with your DHL credentials.

```ruby
DHL::EFulfillment.configure do |config|
  config.urls = :sandbox # or :production for the real thing.
  config.client_id = ENV['DHL_CLIENT_ID']
  config.client_secret = ENV['DHL_CLIENT_SECRET']
  config.account_number = ENV['DHL_ACCOUNT_NUMBER']
end
```

Then, start calling `DHL::EFulfillment` methods.

```ruby
token = DHL::EFulfillment.access_token
DHL::EFulfillment.create_order(properties_hash, token)
DHL::EFulfillment.order_acknowledgement(options, token)
```
