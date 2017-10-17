# ruby-dhl_fulfillment

A gem to access the [DHL Fulfillment API](https://api-qa.dhlecommerce.com/apidoc/apidoc-eff.html).

### Current working endpoints

- CreateSalesOrder
- SalesOrderStatus
- SalesOrderAcknowledgment
- ShipmentDetails

### Usage

Configure the gem with your DHL credentials.

```ruby
DHL::Fulfillment.configure do |config|
  config.urls = :sandbox # or :production for the real thing.
  config.client_id = ENV['DHL_CLIENT_ID']
  config.client_secret = ENV['DHL_CLIENT_SECRET']
  config.account_number = ENV['DHL_ACCOUNT_NUMBER']
end
```

Then, start calling `DHL::Fulfillment` methods.

```ruby
token = DHL::Fulfillment.access_token
DHL::Fulfillment.create_sales_order(properties_hash, token)
DHL::Fulfillment.sales_order_acknowledgement(options)
```

### Token stores

By default, the gem will request a new acess token, store it in memory
and reuse it until it expires, but there are scenarios where you would want
to store the token in a more permanent way.

For those cases, set the `token_store` property in a gem `config` block. Assign
it to an object that responds to `token` and `token=`.

For example, you could store the token in a file like this:

```ruby
class TokenFile
  def token
    File.read('dhl_token')
  end

  def token=(token)
    File.open('dhl_token', 'w') do |file|
      file.puts token
    end
  end
end

DHL::Fulfillment.configure do |config|
  config.token_store = TokenFile.new
end```

### Contributing

Contributions are welcome! Set up the repo using the following commands:

```bash
git clone git@github.com:/magma-labs/ruby-dhl_fulfillment # or use https if you prefer
cd ruby-dhl_fulfillment
bundle install
rake test # You should see all linters and specs pass.
```

Before committing, please run `rake test` to make sure all linters and specs pass.
