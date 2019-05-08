require 'sinatra'
require 'json'
require_relative 'blockchain.rb'

# Generate a globally unique address for this node
node_identifier = SecureRandom.uuid.gsub! '-', ''

# Instantiate the Blockchain
blockchain = Blockchain.new

get '/mine' do
  # We run the proof of work algorithm to get the next proof...
  last_block = blockchain.last_block
  last_proof = last_block[:proof]
  proof = blockchain.proof_of_work(last_proof)

  # We must receive a reward for finding the proof.
  # The sender is "0" to signify that this node has mined a new coin.
  blockchain.new_transaction(
      sender="0",
      recipient=node_identifier,
      amount=1,
      )

  # Forge the new Block by adding it to the chain
  previous_hash = Blockchain.hash(last_block)
  block = blockchain.new_block(previous_hash, proof)

  response = {
      :message => "New Block Forged",
      :index => block[:index],
      :transactions => block[:transactions],
      :proof => block[:proof],
      :previous_hash => block[:previous_hash],
  }
  response.to_json
end

post '/transactions/new' do
  values = JSON.parse(request.body.read)
  keys = values.keys
  # Check that the required fields are in the POST'ed data
  required = Array.new
  required << 'sender' << 'recipient' << 'amount'
  unless (required - keys).empty?
    return 'missing values'
  end

  index = blockchain.new_transaction(values['sender'], values['recipient'], values['amount'])
  response = {
      :message => "Transaction will be added to Block #{index}"
  }
  response.to_json
end

get '/chain' do
  response = {
      :chain => blockchain.chain,
      :length => blockchain.chain.length,
  }
  response.to_json
end
