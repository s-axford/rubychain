require 'digest'
require 'sinatra'
require 'json'

class Blockchain
  @chain
  @current_transactions

  def initialize
    @chain = Array.new
    @current_transaction = Array.new
    self.new_block(1,100)
  end

  """
        Create a new Block in the Blockchain
        :param proof: <int> The proof given by the Proof of Work algorithm
        :param previous_hash: (Optional) <str> Hash of previous Block
        :return: <dict> New Block
  """
  def new_block(previous_hash, proof)
    block = {
        :index => @chain.length + 1,
        :timestamp => Time.now.strftime("%d/%m/%Y %H:%M"),
        :transactions => @current_transactions,
        :proof => proof,
        :previous_hash => previous_hash || Blockchain.hash(self.chain[-1]),
    }

    @current_transactions = []
    @chain.push(block)
    block
  end


  """
        Creates a new transaction to go into the next mined Block
        :param sender: <str> Address of the Sender
        :param recipient: <str> Address of the Recipient
        :param amount: <int> Amount
        :return: <int> The index of the Block that will hold this transaction
  """
  def new_transaction(sender, recipient, amount)
    self.current_transactions << {
        :sender => sender,
        :recipient => recipient,
        :amount => amount,
    }
    self.last_block['index'] + 1
  end

  def last_block
    @chain[-1]
  end

  """
        Creates a SHA-256 hash of a Block
        :param block: <dict> Block
        :return: <str>
  """
  def self.hash(block)
    block_string = JSON.dump(block, sort_keys=true).encode
    sha256 = Digest::SHA2.new(256)
    sha256.digest block_string
  end


  """
        Simple Proof of Work Algorithm:
         - Find a number p' such that hash(pp') contains leading 4 zeroes, where p is the previous p'
         - p is the previous proof, and p' is the new proof
        :param last_proof: <int>
        :return: <int>
  """
  def proof_of_work(last_proof)
    proof = 0
    until self.valid_proof(last_proof, proof)
      proof += 1
    end
    proof
  end

  """
        Validates the Proof: Does hash(last_proof, proof) contain 4 leading zeroes?
        :param last_proof: <int> Previous Proof
        :param proof: <int> Current Proof
        :return: <bool> True if correct, False if not.
  """
  def self.valid_proof(last_proof, proof)
    guess = "#{last_proof}#{proof}".encode
    guess_hash = Digest::SHA2.new(256).hexdigest(guess)
    guess_hash
  end

  attr_reader :chain
end

# Instantiate the Blockchain
blockchain = Blockchain.new

get '/mine' do
  "We'll mine a new Block"
end

post '/transactions/new' do
  "We'll add a new transaction"
end

get '/chain' do
  response = {
      'chain': blockchain.chain,
      'length': blockchain.chain.length,
  }
  response.to_json
end
