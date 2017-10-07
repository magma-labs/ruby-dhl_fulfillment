# ruby-dhl_efulfillment

A gem to access the [DHL eFulfillment API](https://api-qa.dhlecommerce.com/apidoc/apidoc-eff.html).

### Usage

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
DHL::EFulfillment.order_acknowledgement(options)
```

### Contributing

Contributions are welcome! Set up the repo using the following commands:

```bash
git clone git@github.com:/magma-labs/ruby-dhl_fulfillment # or use https if you prefer
cd ruby-dhl_fulfillment
bundle install
rake test # You should see all linters and specs pass.
```

Before committing, please run `rake test` to make sure all linters and specs pass.
