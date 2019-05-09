# rubychain
### A simple blockchain implementation written in Ruby with Sinatra using HTTP requests

This blockchain is based on the python/flask blockchain created by [Daniel van Flymen for Hackernoon](https://hackernoon.com/learn-blockchains-by-building-one-117428612f46 "Learn Blockchains")

## Setup
This blockchain requires Sinatra, run a bundle install in the root directory of the project
```
bundle install
```
Begin your chain by running rubychain.rb
```
ruby rubychain.rb
```
The chain will run on port 4567 by default

## Basic Usage

### Get Address
To get your address perform a get request
```
http://#{your_ip}:4567/identifier
```

### View Chain
To view the current chain on your node perform a get request
```
http://#{your_ip}:4567/chain
```

### Perform Transactions

To add transactions to the pending block perform a post to 
```
http://#{your_ip}:4567/transactions/new
```
with a request body containing a JSON object
```
{
 "sender": "#{your_address}",
 "recipient": "#{someone_elses_address}",
 "amount": #{Amount being transfered}
}
```

## Mining
To mine new block containing all pending transactions perform a get request

```
http://#{your_ip}:4567/mine
```

## Consensus
### Registering with Another Node(s)

To connect to a new node(s), register the node(s) by performing a post request
```
http://#{your_ip}:4567/nodes/register
```
with a request body containing a JSON object
```
{
"nodes": ["http://#{other_ip}:#{port}", "http://#{more_ips}:#{port}"]
}
```

### Ensuring Consensus
To ensure you have the correct chain (In this case the longest chain) perform a get request
```
http://#{your_ip}:4567/nodes/resolve
```
This will update your chain to the largest chain available on the connected nodes
